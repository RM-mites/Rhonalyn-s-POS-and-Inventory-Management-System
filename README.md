# Rhonalyn's POS & Inventory

A point-of-sale and inventory management desktop app for a small furniture
enterprise. Built with Flutter (Windows) and Supabase (hosted PostgreSQL).

## Features

- Point of sale with variant selection, custom line specifications, price
  overrides, discounts, and cash/GCash/bank/credit payments
- Made-to-order lines with deposit, balance, due date, and delivery details
- Product and variant management (size, color, material, price, stock)
- Inventory adjustments with a full stock-movement audit trail
- Customers with store credit (utang), credit limits, and payment recording
- Sales history with admin void/refund that restores stock and credit
- Sales reports and charts: totals, top products, categories, payment mix
- Role-based access: Admin, Cashier, and Inventory Manager
- On-screen receipts in Philippine pesos

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
3. Run:

```powershell
flutter pub get
flutter run -d windows
```

## Project layout

```
lib/
  core/        config, theme, formatting, shared widgets
  data/        Supabase client, models, repositories
  features/    auth, shell, dashboard, pos, products, inventory,
               customers, sales, reports, users, settings
supabase/
  migrations/  schema, functions/RPCs, RLS, seed data
  README.md    database setup and role/permission reference
test/          unit and widget tests
```

## Build phases

| Phase | Scope | Status |
| --- | --- | --- |
| 0 | Dependencies, schema, RPCs, RLS, app bootstrap | Done |
| 1 | Models, repositories, auth, role-based shell, theme | Planned |
| 2 | Categories and product/variant management | Planned |
| 3 | Inventory adjustments and movement history | Planned |
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
