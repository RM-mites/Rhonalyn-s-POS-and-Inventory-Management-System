# Rhonalyn's POS & Inventory

A point-of-sale and inventory management desktop app for a small furniture
enterprise. Built with Flutter (Windows) and Supabase (hosted PostgreSQL).

## Current status

Phases 0–3 are implemented (bootstrap, auth/shell, products & variants, inventory). Phases 4–9 are planned. `flutter analyze` is clean and 10 tests pass.

### Implemented
- Supabase bootstrap with `.env` config, schema/migrations, RLS, and atomic RPCs (`create_sale`, `void_sale`, `adjust_stock`, `record_credit_payment`)
- Email/password auth with profile/role loading (Admin, Cashier, Inventory Manager), inactive-account handling, and a role-based `NavigationRail` shell/dashboard
- Products & categories: CRUD for categories and products, inline variant management (SKU/label/size/color/material/price/stock, track/active, low-stock override, made-to-order flag), search
- Inventory: stock-level view with search and low-stock badges, Restock/Deduct adjustments with notes, and a stock-movement audit history

### Planned
- Customers & store credit (utang) — Phase 4
- POS cart, custom/made-to-order lines, checkout/receipt (`create_sale`) — Phase 5
- Sales history & void — Phase 6
- Reports & analytics — Phase 7
- Settings & admin team/roles — Phase 8
- Seed/demo polish, more tests, final verification — Phase 9

## Tech stack

| Layer | Choice |
| --- | --- |
| UI | Flutter 3.47 (Material 3), Windows desktop |
| State | `provider` |
| Backend | Supabase Auth + Postgres + RLS + RPCs |
| Charts | `fl_chart` |
| Config | `flutter_dotenv` |
| Formatting | `intl` (₱ currency) |

## Quick start

1. Follow [supabase/README.md](supabase/README.md) to create the project and
   run the migrations.
2. Copy `.env.example` to `.env` and add your Supabase URL and anon key.
3. Create your first user in **Supabase → Authentication → Users**, then
   promote it to admin (the signup trigger defaults new profiles to `cashier`):
   ```sql
   update public.profiles
   set role = 'admin', full_name = 'Store Admin', is_active = true
   where id = (select id from auth.users where email = 'you@example.com');
   ```
4. Run:

```powershell
flutter pub get
flutter run -d windows
```

Sign in with that admin account to access the role-based shell (Products/Inventory are available to Admin and Inventory Manager).

## Project layout

```
lib/
  app.dart, main.dart      App bootstrap and provider/auth wiring
  core/
    config/                .env access (Supabase URL/anon key)
    theme/                 Material 3 theme
    utils/                 Formatting helpers (₱, dates)
  data/
    models/                profile, role, category, product/variant,
                           inventory item, stock movement
    repositories/          auth, catalog, inventory (Supabase)
    supabase/              Supabase client
  features/
    startup/               Setup/connection screen
    auth/                  Login, auth gate, session/profile provider
    shell/                 Role-based NavigationRail and placeholders
    dashboard/             Role-aware dashboard
    products/              Category and product/variant management
    inventory/             Stock levels, adjustments, movement history
supabase/
  migrations/              0001 schema, 0002 functions/RPCs, 0003 RLS, 0004 seed
  README.md                Database setup and role/permission reference
test/                      Unit and widget tests
```

Scaffolded (upcoming): `features/{pos,customers,sales,reports,users,settings}` and additional `data` models/repositories.

## Build phases

| Phase | Scope | Status |
| --- | --- | --- |
| 0 | Dependencies, schema, RPCs, RLS, app bootstrap | Done |
| 1 | Auth, profiles/roles, role-based shell, dashboard | Done |
| 2 | Categories and product/variant management | Done |
| 3 | Inventory adjustments and movement history | Done |
| 4 | Customers and store credit | Planned |
| 5 | POS cart, checkout, receipt, made-to-order | Planned |
| 6 | Sales history and void | Planned |
| 7 | Reports and analytics | Planned |
| 8 | Settings and team management | Planned |
| 9 | Seed data, tests, polish | Planned |

## Verification

```powershell
flutter analyze
flutter test
```

## Notes

- The app requires internet access; there is no offline queue in v1.
- Only the Supabase anon key ships with the app. The `service_role` key must
  never be added to `.env` or committed.
- Receipts are displayed on screen only; printing is a future enhancement.
- No barcode scanning. Role access is enforced by both the UI and Supabase RLS/RPCs.
