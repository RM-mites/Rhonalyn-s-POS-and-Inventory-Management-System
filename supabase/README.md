# Supabase Setup

This folder contains everything the app needs on the database side. The
Flutter client connects with the **anon public key** only; all privileged
operations run through `SECURITY DEFINER` functions guarded by role checks and
Row Level Security.

## 1. Create the project

1. Go to <https://supabase.com> and create a new project.
2. Choose a region close to you (Singapore is a good default for the
   Philippines) and save the database password somewhere safe.

## 2. Run the migrations

Open **SQL Editor** in the Supabase dashboard and run these files **in order**.
Copy the whole file, paste it, and click **Run**. Each one is safe to re-run.

| Order | File | What it does |
| --- | --- | --- |
| 1 | `migrations/0001_schema.sql` | Tables, indexes, `updated_at` triggers, new-user profile trigger |
| 2 | `migrations/0002_functions.sql` | Role helpers, atomic RPCs, reporting views, grants |
| 3 | `migrations/0003_rls.sql` | Enables RLS and adds per-role policies |
| 4 | `migrations/0004_seed.sql` | Optional demo categories, products, variants, customers |

> If step 4 fails because you already have data, it is safe to skip it.

## 3. Configure authentication

1. Go to **Authentication > Providers > Email** and make sure it is enabled.
2. For a school/demo setup, turn **Confirm email** off so accounts can sign in
   immediately. Turn it back on for production.
3. Leave **Allow new users to sign up** on while setting up; the profile trigger
   creates a `cashier` profile for each new account.

## 4. Create your first admin

Every new auth user gets a `profiles` row with role `cashier`. Promote yourself:

1. Create an account:
   - Supabase Dashboard **Authentication > Users > Add user**, or
   - sign up from the app once the login screen lands in Phase 1.
2. In **SQL Editor**, run (replace the email):

```sql
update public.profiles
set role = 'admin',
    full_name = 'Your Name'
where id = (select id from auth.users where email = 'you@example.com');
```

3. Sign in again so the app reloads your profile.

## 5. Connect the Flutter app

1. In Supabase, open **Project Settings > API**.
2. Copy the **Project URL** and the **anon public** key.
3. In the project root, copy `.env.example` to `.env`:

```powershell
Copy-Item .env.example .env
```

4. Fill in both values:

```
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-public-key
```

`.env` is already git-ignored. Never put the `service_role` key in the app.

5. Run:

```powershell
flutter pub get
flutter run -d windows
```

## 6. Verify the install

Run this in the SQL Editor; it should return one row and no errors:

```sql
select
  (select count(*) from public.categories) as categories,
  (select count(*) from public.products) as products,
  (select count(*) from public.product_variants) as variants,
  (select count(*) from public.customers) as customers;
```

## Schema at a glance

| Table | Purpose |
| --- | --- |
| `profiles` | One row per auth user: name, role, active flag |
| `categories` | Product grouping |
| `products` | Furniture products, base SKU, made-to-order flag |
| `product_variants` | Size/color/material combinations with price and stock |
| `customers` | Buyers, credit limit, outstanding balance |
| `sales` | Completed/voided sales with payment details |
| `sale_items` | Line items, custom specs, price overrides |
| `made_to_order_jobs` | Deposit, balance, due date, delivery details |
| `stock_movements` | Audit trail for every stock change |
| `credit_payments` | Payments against a customer's balance |
| `store_settings` | Store name, address, contact, receipt footer |

## Atomic operations (RPCs)

All stock and money mutations go through these functions so a sale can never
leave the database half-written.

### `create_sale(payload jsonb)`

```json
{
  "customer_id": "uuid-or-null",
  "payment_method": "cash",
  "discount": 0,
  "amount_paid": 3000,
  "notes": "Deliver on Saturday",
  "items": [
    {
      "product_id": "uuid",
      "variant_id": "uuid",
      "description": "Oak Dining Chair - Natural / Standard",
      "quantity": 2,
      "unit_price": 2500,
      "track_stock": true,
      "is_custom": false,
      "custom_specs": null,
      "notes": null
    }
  ]
}
```

For a made-to-order line, add:

```json
"made_to_order": {
  "target_price": 45000,
  "deposit_amount": 15000,
  "due_date": "2026-12-01",
  "delivery_address": "12 Mabini St, Quezon City",
  "delivery_notes": "Second floor, no elevator"
}
```

Set `"track_stock": false` and `is_custom: true` for made-to-order lines.

### Other RPCs

```sql
-- Restore stock and reverse store credit (admin only)
select public.void_sale('<sale-id>'::uuid, 'Customer cancelled');

-- Adjust stock; use a positive or negative change
select public.adjust_stock('<variant-id>'::uuid, 10, 'Delivery from supplier', 'restock');

-- Record a payment against a customer's outstanding balance
select public.record_credit_payment('<customer-id>'::uuid, 500, 'cash', null, 'Partial payment');
```

## Role permissions

| Action | Admin | Cashier | Inventory Manager |
| --- | --- | --- | --- |
| Record sale / credit payment | Yes | Yes | No |
| Void sale | Yes | No | No |
| Manage products & variants | Yes | No | Yes |
| Adjust stock | Yes | No | Yes |
| Manage customers | Yes | Yes | No |
| View own sales | Yes | Yes | No |
| View all sales | Yes | No | No |
| View stock movements | Yes | No | Yes |
| Store settings & team roles | Yes | No | No |

## Notes and limits

- The app needs an internet connection; there is no offline queue in v1.
- `credit_limit = 0` means **no limit** on that customer.
- Stock cannot go below zero; `create_sale` and `adjust_stock` enforce it.
- Receipts are on-screen only for now.
- Checkout and stock changes are transactional. If any line fails, nothing is
  saved.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `relation does not exist` | Run the migrations in order; check the SQL Editor is on the right project |
| `permission denied for table` | Run `0002_functions.sql` and `0003_rls.sql`, then reload the app |
| `function public.create_sale does not exist` | Run `0002_functions.sql`; also confirm PostgREST reloaded (it runs `notify pgrst` at the end) |
| App stuck on the setup screen | `.env` values are still placeholders or the file lacks the `SUPABASE_` names |
| `new row violates row-level security policy` | The signed-in profile is missing, inactive, or lacks the required role |
| Credit sale rejected | Customer is required, or the balance would exceed the credit limit |
| `Insufficient stock` | Stock quantity is lower than requested; adjust stock first |
