-- ============================================================================
-- Rhonalyn's POS & Inventory - Functions, views, and grants
-- Run after 0001_schema.sql.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Role helpers
-- ---------------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and is_active
  );
$$;

create or replace function public.is_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('admin', 'cashier') and is_active
  );
$$;

create or replace function public.is_inventory_or_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('admin', 'inventory_manager') and is_active
  );
$$;

-- ---------------------------------------------------------------------------
-- Receipt number generator
-- ---------------------------------------------------------------------------
create or replace function public.next_receipt_no()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_seq bigint;
begin
  select nextval('public.sale_receipt_seq') into v_seq;
  return 'RCPT-' || to_char(now(), 'YYYYMMDD') || '-' || lpad(v_seq::text, 4, '0');
end;
$$;

-- ---------------------------------------------------------------------------
-- create_sale(payload)
-- Atomically creates a sale, its items, stock movements, made-to-order jobs,
-- and customer credit balance updates.
-- ---------------------------------------------------------------------------
create or replace function public.create_sale(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_role text;
  v_active boolean;
  v_sale public.sales%rowtype;
  v_sale_id uuid;
  v_item jsonb;
  v_item_id uuid;
  v_qty integer;
  v_unit_price numeric(12, 2);
  v_subtotal numeric(12, 2) := 0;
  v_discount numeric(12, 2) := coalesce(nullif(payload ->> 'discount', '')::numeric, 0);
  v_total numeric(12, 2);
  v_paid numeric(12, 2);
  v_change numeric(12, 2);
  v_method text := payload ->> 'payment_method';
  v_customer_id uuid := nullif(payload ->> 'customer_id', '')::uuid;
  v_customer public.customers%rowtype;
  v_variant public.product_variants%rowtype;
  v_track boolean;
  v_mto jsonb;
  v_job_price numeric(12, 2);
  v_deposit numeric(12, 2);
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  select role, is_active into v_role, v_active
  from public.profiles where id = v_uid;

  if v_role is null or not v_active then
    raise exception 'Your account is inactive or missing a profile';
  end if;

  if v_role not in ('admin', 'cashier') then
    raise exception 'Only cashiers or admins can record sales';
  end if;

  if jsonb_typeof(payload -> 'items') is distinct from 'array'
     or jsonb_array_length(payload -> 'items') = 0 then
    raise exception 'A sale must contain at least one item';
  end if;

  if v_method is null or v_method not in ('cash', 'gcash', 'bank_transfer', 'credit') then
    raise exception 'Invalid payment method';
  end if;

  if v_discount < 0 then
    raise exception 'Discount cannot be negative';
  end if;

  select coalesce(sum((it ->> 'quantity')::int * (it ->> 'unit_price')::numeric), 0)
  into v_subtotal
  from jsonb_array_elements(payload -> 'items') as it;

  if v_subtotal < 0 then
    raise exception 'Invalid line amounts';
  end if;

  v_total := greatest(v_subtotal - v_discount, 0);

  if v_customer_id is not null then
    select * into v_customer
    from public.customers where id = v_customer_id for update;
    if not found then
      raise exception 'Customer not found';
    end if;
  end if;

  if v_method = 'credit' then
    if v_customer_id is null then
      raise exception 'Credit sales require a customer';
    end if;
    if v_customer.credit_limit > 0
       and (v_customer.balance + v_total) > v_customer.credit_limit then
      raise exception 'Credit limit exceeded. Remaining credit: %',
        (v_customer.credit_limit - v_customer.balance);
    end if;
    v_paid := 0;
    v_change := 0;
  else
    v_paid := coalesce(nullif(payload ->> 'amount_paid', '')::numeric, v_total);
    if v_paid < v_total then
      raise exception 'Amount paid is less than the total';
    end if;
    v_change := v_paid - v_total;
  end if;

  insert into public.sales (
    receipt_no, customer_id, cashier_id, subtotal, discount, total,
    amount_paid, change_due, payment_method, notes
  ) values (
    public.next_receipt_no(), v_customer_id, v_uid, v_subtotal, v_discount, v_total,
    v_paid, v_change, v_method, nullif(payload ->> 'notes', '')
  )
  returning * into v_sale;

  v_sale_id := v_sale.id;

  for v_item in select * from jsonb_array_elements(payload -> 'items')
  loop
    v_qty := (v_item ->> 'quantity')::int;
    v_unit_price := (v_item ->> 'unit_price')::numeric;
    v_track := coalesce((v_item ->> 'track_stock')::boolean, true);

    if v_qty is null or v_qty <= 0 then
      raise exception 'Item quantity must be greater than zero';
    end if;
    if v_unit_price is null or v_unit_price < 0 then
      raise exception 'Item price cannot be negative';
    end if;

    insert into public.sale_items (
      sale_id, product_id, variant_id, description, quantity, unit_price,
      line_total, is_custom, custom_specs, notes, tracked_stock
    ) values (
      v_sale_id,
      nullif(v_item ->> 'product_id', '')::uuid,
      nullif(v_item ->> 'variant_id', '')::uuid,
      coalesce(nullif(v_item ->> 'description', ''), 'Item'),
      v_qty,
      v_unit_price,
      v_qty * v_unit_price,
      coalesce((v_item ->> 'is_custom')::boolean, false),
      v_item -> 'custom_specs',
      nullif(v_item ->> 'notes', ''),
      v_track
    )
    returning id into v_item_id;

    if v_track and nullif(v_item ->> 'variant_id', '') is not null then
      select * into v_variant
      from public.product_variants
      where id = (v_item ->> 'variant_id')::uuid
      for update;

      if not found then
        raise exception 'Variant not found';
      end if;

      if v_variant.stock_qty < v_qty then
        raise exception 'Insufficient stock for %. Available: %, requested: %',
          v_variant.label, v_variant.stock_qty, v_qty;
      end if;

      update public.product_variants
      set stock_qty = stock_qty - v_qty
      where id = v_variant.id;

      insert into public.stock_movements (
        variant_id, movement_type, quantity_change, reference_id, notes, created_by
      ) values (
        v_variant.id, 'sale', -v_qty, v_sale_id,
        'Sale ' || v_sale.receipt_no, v_uid
      );
    end if;

    v_mto := v_item -> 'made_to_order';
    if v_mto is not null and jsonb_typeof(v_mto) = 'object' then
      v_job_price := coalesce(
        nullif(v_mto ->> 'target_price', '')::numeric,
        v_qty * v_unit_price
      );
      v_deposit := coalesce(nullif(v_mto ->> 'deposit_amount', '')::numeric, 0);

      insert into public.made_to_order_jobs (
        sale_id, sale_item_id, customer_id, specs, target_price,
        deposit_amount, balance_due, due_date, delivery_address, delivery_notes
      ) values (
        v_sale_id,
        v_item_id,
        coalesce(nullif(v_mto ->> 'customer_id', '')::uuid, v_customer_id),
        coalesce(v_mto -> 'specs', v_item -> 'custom_specs'),
        v_job_price,
        v_deposit,
        greatest(v_job_price - v_deposit, 0),
        nullif(v_mto ->> 'due_date', '')::date,
        nullif(v_mto ->> 'delivery_address', ''),
        nullif(v_mto ->> 'delivery_notes', '')
      );
    end if;
  end loop;

  if v_method = 'credit' then
    update public.customers
    set balance = balance + v_total
    where id = v_customer_id;
  end if;

  return to_jsonb(v_sale);
end;
$$;

-- ---------------------------------------------------------------------------
-- void_sale(sale_id, reason)
-- Restores stock, reverses store credit, and marks the sale voided.
-- ---------------------------------------------------------------------------
create or replace function public.void_sale(p_sale_id uuid, p_reason text default null)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_sale public.sales%rowtype;
  v_item public.sale_items%rowtype;
begin
  if not public.is_admin() then
    raise exception 'Only admins can void sales';
  end if;

  select * into v_sale from public.sales where id = p_sale_id for update;
  if not found then
    raise exception 'Sale not found';
  end if;
  if v_sale.status = 'voided' then
    raise exception 'Sale is already voided';
  end if;

  for v_item in select * from public.sale_items where sale_id = p_sale_id
  loop
    if v_item.tracked_stock and v_item.variant_id is not null then
      update public.product_variants
      set stock_qty = stock_qty + v_item.quantity
      where id = v_item.variant_id;

      insert into public.stock_movements (
        variant_id, movement_type, quantity_change, reference_id, notes, created_by
      ) values (
        v_item.variant_id, 'void', v_item.quantity, p_sale_id,
        coalesce(p_reason, 'Voided ' || v_sale.receipt_no), v_uid
      );
    end if;
  end loop;

  if v_sale.payment_method = 'credit' and v_sale.customer_id is not null then
    update public.customers
    set balance = greatest(balance - v_sale.total, 0)
    where id = v_sale.customer_id;
  end if;

  delete from public.made_to_order_jobs where sale_id = p_sale_id;

  update public.sales
  set status = 'voided',
      voided_at = now(),
      voided_by = v_uid,
      notes = nullif(
        concat_ws(E'\n', notes, nullif(p_reason, '')),
        ''
      )
  where id = p_sale_id;

  return jsonb_build_object('id', p_sale_id, 'status', 'voided');
end;
$$;

-- ---------------------------------------------------------------------------
-- adjust_stock(variant, change, notes, type)
-- ---------------------------------------------------------------------------
create or replace function public.adjust_stock(
  p_variant_id uuid,
  p_quantity_change integer,
  p_notes text default null,
  p_movement_type text default 'adjustment'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_variant public.product_variants%rowtype;
  v_new integer;
begin
  if not public.is_inventory_or_admin() then
    raise exception 'Only inventory managers or admins can adjust stock';
  end if;

  if p_quantity_change is null or p_quantity_change = 0 then
    raise exception 'Quantity change must be non-zero';
  end if;

  if p_movement_type is null
     or p_movement_type not in ('adjustment', 'restock') then
    raise exception 'Invalid movement type';
  end if;

  select * into v_variant
  from public.product_variants where id = p_variant_id for update;
  if not found then
    raise exception 'Variant not found';
  end if;

  v_new := v_variant.stock_qty + p_quantity_change;
  if v_new < 0 then
    raise exception 'Stock cannot go below zero. Current stock: %', v_variant.stock_qty;
  end if;

  update public.product_variants
  set stock_qty = v_new
  where id = p_variant_id;

  insert into public.stock_movements (
    variant_id, movement_type, quantity_change, notes, created_by
  ) values (
    p_variant_id, p_movement_type, p_quantity_change, p_notes, v_uid
  );

  return jsonb_build_object('variant_id', p_variant_id, 'stock_qty', v_new);
end;
$$;

-- ---------------------------------------------------------------------------
-- record_credit_payment(customer, amount, method, sale, notes)
-- ---------------------------------------------------------------------------
create or replace function public.record_credit_payment(
  p_customer_id uuid,
  p_amount numeric,
  p_method text default 'cash',
  p_sale_id uuid default null,
  p_notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_customer public.customers%rowtype;
  v_new numeric(12, 2);
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  if not public.is_staff() then
    raise exception 'Only cashiers or admins can record payments';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Payment amount must be greater than zero';
  end if;

  if p_method is null or p_method not in ('cash', 'gcash', 'bank_transfer') then
    raise exception 'Invalid payment method';
  end if;

  select * into v_customer
  from public.customers where id = p_customer_id for update;
  if not found then
    raise exception 'Customer not found';
  end if;

  if p_amount > v_customer.balance then
    raise exception 'Payment exceeds outstanding balance of %', v_customer.balance;
  end if;

  insert into public.credit_payments (
    customer_id, sale_id, amount, method, received_by, notes
  ) values (
    p_customer_id, p_sale_id, p_amount, p_method, v_uid, p_notes
  );

  v_new := v_customer.balance - p_amount;
  update public.customers set balance = v_new where id = p_customer_id;

  return jsonb_build_object('customer_id', p_customer_id, 'balance', v_new);
end;
$$;

-- ---------------------------------------------------------------------------
-- Reporting views
-- ---------------------------------------------------------------------------
create or replace view public.v_sale_item_details
with (security_invoker = true)
as
select
  si.id,
  s.id as sale_id,
  s.receipt_no,
  s.created_at,
  s.status,
  s.payment_method,
  s.customer_id,
  c.name as customer_name,
  si.product_id,
  p.name as product_name,
  p.category_id,
  cat.name as category_name,
  si.variant_id,
  v.label as variant_label,
  si.description,
  si.quantity,
  si.unit_price,
  si.line_total,
  si.is_custom,
  si.custom_specs
from public.sale_items si
join public.sales s on s.id = si.sale_id
left join public.customers c on c.id = s.customer_id
left join public.products p on p.id = si.product_id
left join public.categories cat on cat.id = p.category_id
left join public.product_variants v on v.id = si.variant_id;

create or replace view public.v_low_stock
with (security_invoker = true)
as
select
  v.id as variant_id,
  v.sku,
  v.label,
  v.stock_qty,
  coalesce(v.low_stock_threshold, p.low_stock_threshold) as threshold,
  p.id as product_id,
  p.name as product_name
from public.product_variants v
join public.products p on p.id = v.product_id
where v.track_stock
  and v.is_active
  and p.is_active
  and v.stock_qty <= coalesce(v.low_stock_threshold, p.low_stock_threshold);

-- ---------------------------------------------------------------------------
-- Grants (RLS still governs row access)
-- ---------------------------------------------------------------------------
grant usage on schema public to anon, authenticated;

grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;

revoke execute on function public.create_sale(jsonb) from public;
revoke execute on function public.void_sale(uuid, text) from public;
revoke execute on function public.adjust_stock(uuid, integer, text, text) from public;
revoke execute on function public.record_credit_payment(uuid, numeric, text, uuid, text) from public;

grant execute on function public.create_sale(jsonb) to authenticated;
grant execute on function public.void_sale(uuid, text) to authenticated;
grant execute on function public.adjust_stock(uuid, integer, text, text) to authenticated;
grant execute on function public.record_credit_payment(uuid, numeric, text, uuid, text) to authenticated;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.is_staff() to authenticated;
grant execute on function public.is_inventory_or_admin() to authenticated;
grant execute on function public.next_receipt_no() to authenticated;
