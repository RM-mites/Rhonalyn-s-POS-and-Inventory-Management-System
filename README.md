# Rhonalyn's POS & Inventory

A point-of-sale and inventory management desktop app for a small furniture
enterprise. Built with Flutter (Windows) and Supabase (hosted PostgreSQL).

## Current status

All planned phases (0–9) are implemented. Automated verification (static analysis, 21 tests, Windows debug build) passes. A manual smoke test against your Supabase project with real credentials is still recommended before deployment.

### Implemented
- Supabase bootstrap with `.env` config, schema/migrations, RLS, and atomic RPCs (`create_sale`, `void_sale`, `adjust_stock`, `record_credit_payment`)
- Email/password auth with profile/role loading (Admin, Cashier, Inventory Manager), inactive-account handling, and a role-based `NavigationRail` shell/dashboard
- Products & categories: CRUD for categories and products, inline variant management (SKU/label/size/color/material/price/stock, track/active, low-stock override, made-to-order flag), search
- Inventory: stock-level view with search and low-stock badges, Restock/Deduct adjustments with notes, and a stock-movement audit history
- Customers & credit: customer CRUD (contact/address, credit limit, active flag), balance/available-credit view, and payment recording via `record_credit_payment` with payment history
- POS: product/variant cart, custom and made-to-order lines (specs, price override, deposit/due date/delivery), checkout (cash/GCash/bank/credit) via `create_sale`, and on-screen receipt
- Sales history: list/search/filter by status and payment method, sale detail with line items and made-to-order job info, and admin void via `void_sale`
- Reports & analytics: date-range KPIs, daily sales trend (`fl_chart`), payment mix, top products by revenue, and low-stock alerts
- Settings & team: store details/receipt footer/low-stock defaults (used by receipts and new products), and admin management of staff roles/active status with self/last-admin lockout guards

### Verification
- Static analysis: `dart analyze lib test`
- Tests: `flutter test` (21 tests)
- Windows build: `flutter build windows --debug`

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

Sign in with that admin account to access the role-based shell (Products/Inventory are available to Admin and Inventory Manager). Create additional staff in **Supabase → Authentication → Users**; their profiles appear in the app's **Team** screen, where admins can set roles and activation.

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
                           inventory item, stock movement, customer/credit,
                           cart/sale, reports summary
    repositories/          auth, catalog, inventory, customers, sales,
                           reports (Supabase)
    supabase/              Supabase client
  features/
    startup/               Setup/connection screen
    auth/                  Login, auth gate, session/profile provider
    shell/                 Role-based NavigationRail and placeholders
    dashboard/             Role-aware dashboard
    products/              Category and product/variant management
    inventory/             Stock levels, adjustments, movement history
    customers/             Customer list/detail, credit (utang), payments
    pos/                   Cart, custom/made-to-order lines, checkout
    sales/                 Sales history, detail, admin void
    reports/               KPIs, sales trend, payment mix, stock alerts
    team/                  Staff list, role/active editing
    settings/              Store details, receipt footer, low-stock default
supabase/
  migrations/              0001 schema, 0002 functions/RPCs, 0003 RLS, 0004 seed
  README.md                Database setup and role/permission reference
test/                      Unit and widget tests
```

Scaffolded (upcoming): additional `data` models/repositories as needed for Phase 9 polish.

## Build phases

| Phase | Scope | Status |
| --- | --- | --- |
| 0 | Dependencies, schema, RPCs, RLS, app bootstrap | Done |
| 1 | Auth, profiles/roles, role-based shell, dashboard | Done |
| 2 | Categories and product/variant management | Done |
| 3 | Inventory adjustments and movement history | Done |
| 4 | Customers and store credit | Done |
| 5 | POS cart, checkout, receipt, made-to-order | Done |
| 6 | Sales history and void | Done |
| 7 | Reports and analytics | Done |
| 8 | Settings and team management | Done |
| 9 | Seed data, tests, polish | Done |

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
