-- ============================================================================
-- Rhonalyn's POS & Inventory - Schema
-- Run this first in the Supabase SQL Editor.
-- ============================================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Profiles (linked to Supabase Auth users)
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  role text not null default 'cashier'
    check (role in ('admin', 'cashier', 'inventory_manager')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Categories
-- ---------------------------------------------------------------------------
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Products
-- ---------------------------------------------------------------------------
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sku text not null unique,
  category_id uuid references public.categories (id) on delete set null,
  description text,
  base_price numeric(12, 2) not null default 0 check (base_price >= 0),
  is_made_to_order boolean not null default false,
  low_stock_threshold integer not null default 5 check (low_stock_threshold >= 0),
  image_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Product variants (size / color / material combinations)
-- ---------------------------------------------------------------------------
create table if not exists public.product_variants (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products (id) on delete cascade,
  sku text not null unique,
  label text not null,
  size text,
  color text,
  material text,
  price numeric(12, 2) not null default 0 check (price >= 0),
  stock_qty integer not null default 0 check (stock_qty >= 0),
  low_stock_threshold integer check (low_stock_threshold is null or low_stock_threshold >= 0),
  track_stock boolean not null default true,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (product_id, label)
);

-- ---------------------------------------------------------------------------
-- Customers & store credit (utang)
-- ---------------------------------------------------------------------------
create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text,
  email text,
  address text,
  credit_limit numeric(12, 2) not null default 0 check (credit_limit >= 0),
  balance numeric(12, 2) not null default 0 check (balance >= 0),
  notes text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Sales
-- ---------------------------------------------------------------------------
create sequence if not exists public.sale_receipt_seq;

create table if not exists public.sales (
  id uuid primary key default gen_random_uuid(),
  receipt_no text not null unique,
  customer_id uuid references public.customers (id) on delete set null,
  cashier_id uuid references public.profiles (id) on delete set null,
  subtotal numeric(12, 2) not null default 0 check (subtotal >= 0),
  discount numeric(12, 2) not null default 0 check (discount >= 0),
  total numeric(12, 2) not null default 0 check (total >= 0),
  amount_paid numeric(12, 2) not null default 0 check (amount_paid >= 0),
  change_due numeric(12, 2) not null default 0 check (change_due >= 0),
  payment_method text not null
    check (payment_method in ('cash', 'gcash', 'bank_transfer', 'credit')),
  status text not null default 'completed'
    check (status in ('completed', 'voided')),
  notes text,
  voided_at timestamptz,
  voided_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.sale_items (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.sales (id) on delete cascade,
  product_id uuid references public.products (id) on delete set null,
  variant_id uuid references public.product_variants (id) on delete set null,
  description text not null,
  quantity integer not null check (quantity > 0),
  unit_price numeric(12, 2) not null check (unit_price >= 0),
  line_total numeric(12, 2) not null check (line_total >= 0),
  is_custom boolean not null default false,
  custom_specs jsonb,
  notes text,
  tracked_stock boolean not null default true,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Made-to-order jobs (deposit / balance / delivery; no status workflow)
-- ---------------------------------------------------------------------------
create table if not exists public.made_to_order_jobs (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.sales (id) on delete cascade,
  sale_item_id uuid not null references public.sale_items (id) on delete cascade,
  customer_id uuid references public.customers (id) on delete set null,
  specs jsonb,
  target_price numeric(12, 2) not null default 0 check (target_price >= 0),
  deposit_amount numeric(12, 2) not null default 0 check (deposit_amount >= 0),
  balance_due numeric(12, 2) not null default 0 check (balance_due >= 0),
  due_date date,
  delivery_address text,
  delivery_notes text,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Inventory audit trail
-- ---------------------------------------------------------------------------
create table if not exists public.stock_movements (
  id uuid primary key default gen_random_uuid(),
  variant_id uuid not null references public.product_variants (id) on delete cascade,
  movement_type text not null
    check (movement_type in ('sale', 'restock', 'adjustment', 'void', 'initial')),
  quantity_change integer not null,
  reference_id uuid,
  notes text,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Credit payments
-- ---------------------------------------------------------------------------
create table if not exists public.credit_payments (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers (id) on delete cascade,
  sale_id uuid references public.sales (id) on delete set null,
  amount numeric(12, 2) not null check (amount > 0),
  method text not null default 'cash'
    check (method in ('cash', 'gcash', 'bank_transfer')),
  received_by uuid references public.profiles (id) on delete set null,
  notes text,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Store settings (single row)
-- ---------------------------------------------------------------------------
create table if not exists public.store_settings (
  id integer primary key default 1 check (id = 1),
  store_name text not null default 'Rhonalyn''s Furniture',
  address text,
  contact text,
  receipt_footer text default 'Thank you for your purchase!',
  default_low_stock_threshold integer not null default 5
    check (default_low_stock_threshold >= 0),
  updated_at timestamptz not null default now()
);

insert into public.store_settings (id) values (1)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
create index if not exists idx_products_category on public.products (category_id);
create index if not exists idx_products_active on public.products (is_active);
create index if not exists idx_variants_product on public.product_variants (product_id);
create index if not exists idx_variants_active on public.product_variants (is_active);
create index if not exists idx_sales_created_at on public.sales (created_at desc);
create index if not exists idx_sales_customer on public.sales (customer_id);
create index if not exists idx_sales_cashier on public.sales (cashier_id);
create index if not exists idx_sales_status on public.sales (status);
create index if not exists idx_sale_items_sale on public.sale_items (sale_id);
create index if not exists idx_sale_items_variant on public.sale_items (variant_id);
create index if not exists idx_stock_movements_variant on public.stock_movements (variant_id);
create index if not exists idx_stock_movements_created on public.stock_movements (created_at desc);
create index if not exists idx_credit_payments_customer on public.credit_payments (customer_id);
create index if not exists idx_mto_sale on public.made_to_order_jobs (sale_id);
create index if not exists idx_mto_customer on public.made_to_order_jobs (customer_id);

-- ---------------------------------------------------------------------------
-- updated_at maintenance
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated on public.profiles;
create trigger trg_profiles_updated before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists trg_categories_updated on public.categories;
create trigger trg_categories_updated before update on public.categories
  for each row execute function public.set_updated_at();

drop trigger if exists trg_products_updated on public.products;
create trigger trg_products_updated before update on public.products
  for each row execute function public.set_updated_at();

drop trigger if exists trg_variants_updated on public.product_variants;
create trigger trg_variants_updated before update on public.product_variants
  for each row execute function public.set_updated_at();

drop trigger if exists trg_customers_updated on public.customers;
create trigger trg_customers_updated before update on public.customers
  for each row execute function public.set_updated_at();

drop trigger if exists trg_store_settings_updated on public.store_settings;
create trigger trg_store_settings_updated before update on public.store_settings
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Create a profile automatically for every new auth user
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)),
    'cashier'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
