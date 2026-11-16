-- ============================================================================
-- Rhonalyn's POS & Inventory - Row Level Security
-- Run after 0002_functions.sql.
--
-- Writes to sales, sale_items, stock_movements, made_to_order_jobs, and
-- credit_payments happen ONLY through SECURITY DEFINER functions, so those
-- tables intentionally have no direct insert/update policies.
-- ============================================================================

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.product_variants enable row level security;
alter table public.customers enable row level security;
alter table public.sales enable row level security;
alter table public.sale_items enable row level security;
alter table public.made_to_order_jobs enable row level security;
alter table public.stock_movements enable row level security;
alter table public.credit_payments enable row level security;
alter table public.store_settings enable row level security;

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
  for select to authenticated
  using (id = auth.uid() or public.is_admin());

drop policy if exists profiles_update_admin on public.profiles;
create policy profiles_update_admin on public.profiles
  for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- categories
-- ---------------------------------------------------------------------------
drop policy if exists categories_select on public.categories;
create policy categories_select on public.categories
  for select to authenticated using (true);

drop policy if exists categories_write on public.categories;
create policy categories_write on public.categories
  for all to authenticated
  using (public.is_inventory_or_admin())
  with check (public.is_inventory_or_admin());

-- ---------------------------------------------------------------------------
-- products
-- ---------------------------------------------------------------------------
drop policy if exists products_select on public.products;
create policy products_select on public.products
  for select to authenticated using (true);

drop policy if exists products_write on public.products;
create policy products_write on public.products
  for all to authenticated
  using (public.is_inventory_or_admin())
  with check (public.is_inventory_or_admin());

-- ---------------------------------------------------------------------------
-- product_variants
-- ---------------------------------------------------------------------------
drop policy if exists variants_select on public.product_variants;
create policy variants_select on public.product_variants
  for select to authenticated using (true);

drop policy if exists variants_write on public.product_variants;
create policy variants_write on public.product_variants
  for all to authenticated
  using (public.is_inventory_or_admin())
  with check (public.is_inventory_or_admin());

-- ---------------------------------------------------------------------------
-- customers
-- ---------------------------------------------------------------------------
drop policy if exists customers_select on public.customers;
create policy customers_select on public.customers
  for select to authenticated using (public.is_staff());

drop policy if exists customers_insert on public.customers;
create policy customers_insert on public.customers
  for insert to authenticated with check (public.is_staff());

drop policy if exists customers_update on public.customers;
create policy customers_update on public.customers
  for update to authenticated
  using (public.is_staff())
  with check (public.is_staff());

drop policy if exists customers_delete on public.customers;
create policy customers_delete on public.customers
  for delete to authenticated using (public.is_admin());

-- ---------------------------------------------------------------------------
-- sales (read only; writes via create_sale / void_sale)
-- ---------------------------------------------------------------------------
drop policy if exists sales_select on public.sales;
create policy sales_select on public.sales
  for select to authenticated
  using (public.is_admin() or cashier_id = auth.uid());

-- ---------------------------------------------------------------------------
-- sale_items
-- ---------------------------------------------------------------------------
drop policy if exists sale_items_select on public.sale_items;
create policy sale_items_select on public.sale_items
  for select to authenticated
  using (
    exists (
      select 1 from public.sales s
      where s.id = sale_id
        and (public.is_admin() or s.cashier_id = auth.uid())
    )
  );

-- ---------------------------------------------------------------------------
-- made_to_order_jobs
-- ---------------------------------------------------------------------------
drop policy if exists mto_select on public.made_to_order_jobs;
create policy mto_select on public.made_to_order_jobs
  for select to authenticated
  using (
    exists (
      select 1 from public.sales s
      where s.id = sale_id
        and (public.is_admin() or s.cashier_id = auth.uid())
    )
  );

-- ---------------------------------------------------------------------------
-- stock_movements
-- ---------------------------------------------------------------------------
drop policy if exists stock_movements_select on public.stock_movements;
create policy stock_movements_select on public.stock_movements
  for select to authenticated using (public.is_inventory_or_admin());

-- ---------------------------------------------------------------------------
-- credit_payments
-- ---------------------------------------------------------------------------
drop policy if exists credit_payments_select on public.credit_payments;
create policy credit_payments_select on public.credit_payments
  for select to authenticated using (public.is_staff());

-- ---------------------------------------------------------------------------
-- store_settings
-- ---------------------------------------------------------------------------
drop policy if exists store_settings_select on public.store_settings;
create policy store_settings_select on public.store_settings
  for select to authenticated using (true);

drop policy if exists store_settings_update on public.store_settings;
create policy store_settings_update on public.store_settings
  for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

notify pgrst, 'reload schema';
