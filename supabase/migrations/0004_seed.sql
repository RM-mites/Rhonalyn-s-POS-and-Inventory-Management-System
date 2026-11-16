-- ============================================================================
-- Rhonalyn's POS & Inventory - Sample seed data (optional)
-- Run after 0003_rls.sql. Safe to re-run.
-- ============================================================================

insert into public.categories (name, description) values
  ('Seating', 'Chairs, sofas, and benches'),
  ('Tables', 'Dining, coffee, and work tables'),
  ('Storage', 'Shelves, cabinets, and wardrobes'),
  ('Bedroom', 'Beds, nightstands, and dressers'),
  ('Living Room', 'Accent and occasional furniture')
on conflict (name) do nothing;

-- ---------------------------------------------------------------------------
-- Products
-- ---------------------------------------------------------------------------
insert into public.products
  (name, sku, category_id, description, base_price, is_made_to_order, low_stock_threshold)
values
  ('Oak Dining Chair', 'CHAIR-OAK', (select id from public.categories where name = 'Seating'),
   'Solid oak dining chair with a natural finish.', 2500.00, false, 5),
  ('Fabric Sofa 3-Seater', 'SOFA-3S', (select id from public.categories where name = 'Seating'),
   'Three-seater sofa with removable linen covers.', 18500.00, false, 2),
  ('Dining Table 6-Seater', 'TBL-D6', (select id from public.categories where name = 'Tables'),
   'Six-seater dining table available in narra or mahogany.', 22000.00, false, 2),
  ('Coffee Table', 'TBL-COFFEE', (select id from public.categories where name = 'Tables'),
   'Low coffee table with a slatted lower shelf.', 6500.00, false, 3),
  ('Bookshelf 5-Tier', 'SHELF-5T', (select id from public.categories where name = 'Storage'),
   'Five-tier open bookshelf.', 4500.00, false, 5),
  ('Queen Bed Frame', 'BED-Q', (select id from public.categories where name = 'Bedroom'),
   'Queen-size wooden bed frame with headboard.', 15000.00, false, 2),
  ('Custom Wardrobe', 'WARD-CUSTOM', (select id from public.categories where name = 'Storage'),
   'Built-to-order wardrobe. Specifications are agreed per customer.', 0.00, true, 0),
  ('Custom Dining Set', 'DINING-CUSTOM', (select id from public.categories where name = 'Tables'),
   'Made-to-order dining set sized and finished per customer.', 0.00, true, 0)
on conflict (sku) do nothing;

-- ---------------------------------------------------------------------------
-- Variants
-- ---------------------------------------------------------------------------
insert into public.product_variants
  (product_id, sku, label, size, color, material, price, stock_qty, low_stock_threshold, track_stock)
select p.id, v.sku, v.label, v.size, v.color, v.material, v.price, v.stock_qty, v.threshold, v.track_stock
from (values
  ('CHAIR-OAK', 'CHAIR-OAK-NAT', 'Natural / Standard', 'Standard', 'Natural', 'Oak', 2500.00, 12, null::integer, true),
  ('CHAIR-OAK', 'CHAIR-OAK-WAL', 'Walnut / Standard', 'Standard', 'Walnut', 'Oak', 2700.00, 8, null::integer, true),
  ('SOFA-3S', 'SOFA-3S-GRY', 'Gray Linen', '3-Seater', 'Gray', 'Linen', 18500.00, 3, null::integer, true),
  ('SOFA-3S', 'SOFA-3S-BGE', 'Beige Linen', '3-Seater', 'Beige', 'Linen', 18500.00, 2, null::integer, true),
  ('TBL-D6', 'TBL-D6-NAR', 'Narra / 180x90', '180x90 cm', 'Narra', 'Narra', 22000.00, 2, null::integer, true),
  ('TBL-D6', 'TBL-D6-MAH', 'Mahogany / 180x90', '180x90 cm', 'Mahogany', 'Mahogany', 23500.00, 1, null::integer, true),
  ('TBL-COFFEE', 'TBL-COFFEE-OAK', 'Oak / 100x50', '100x50 cm', 'Natural', 'Oak', 6500.00, 4, null::integer, true),
  ('TBL-COFFEE', 'TBL-COFFEE-WAL', 'Walnut / 120x60', '120x60 cm', 'Walnut', 'Walnut', 7800.00, 3, null::integer, true),
  ('SHELF-5T', 'SHELF-5T-WHT', 'White', '5-Tier', 'White', 'Engineered Wood', 4500.00, 6, null::integer, true),
  ('SHELF-5T', 'SHELF-5T-OAK', 'Oak', '5-Tier', 'Natural', 'Oak', 4800.00, 5, null::integer, true),
  ('BED-Q', 'BED-Q-OAK', 'Oak / Queen', 'Queen', 'Natural', 'Oak', 15000.00, 2, null::integer, true),
  ('BED-Q', 'BED-Q-WAL', 'Walnut / Queen', 'Queen', 'Walnut', 'Walnut', 16500.00, 1, null::integer, true),
  ('WARD-CUSTOM', 'WARD-CUSTOM-STD', 'Made to order', null, null, null, 0.00, 0, null::integer, false),
  ('DINING-CUSTOM', 'DINING-CUSTOM-STD', 'Made to order', null, null, null, 0.00, 0, null::integer, false)
) as v(product_sku, sku, label, size, color, material, price, stock_qty, threshold, track_stock)
join public.products p on p.sku = v.product_sku
on conflict (sku) do nothing;

-- ---------------------------------------------------------------------------
-- Initial stock movement audit entries
-- ---------------------------------------------------------------------------
insert into public.stock_movements (variant_id, movement_type, quantity_change, notes)
select v.id, 'initial', v.stock_qty, 'Opening stock (seed data)'
from public.product_variants v
where v.stock_qty > 0
  and not exists (
    select 1 from public.stock_movements m
    where m.variant_id = v.id and m.movement_type = 'initial'
  );

-- ---------------------------------------------------------------------------
-- Customers
-- ---------------------------------------------------------------------------
insert into public.customers (name, phone, email, address, credit_limit, balance, notes)
select c.name, c.phone, c.email, c.address, c.credit_limit, c.balance, c.notes
from (values
  ('Maria Santos', '09171234567', 'maria.santos@example.com', 'Quezon City', 10000.00, 0.00, 'Repeat customer'),
  ('Juan Dela Cruz', '09182345678', 'juan.delacruz@example.com', 'Manila', 5000.00, 2500.00, 'Store credit customer'),
  ('Ana Reyes', '09293456789', 'ana.reyes@example.com', 'Pasig City', 0.00, 0.00, null),
  ('Pedro Bautista', '09094567890', 'pedro.bautista@example.com', 'Mandaluyong', 8000.00, 0.00, 'Office furniture buyer')
) as c(name, phone, email, address, credit_limit, balance, notes)
where not exists (
  select 1 from public.customers existing where existing.name = c.name
);
