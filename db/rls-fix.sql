-- =============================================
-- 🔧 إصلاح RLS (Row Level Security)
-- شغّل هذا في Supabase → SQL Editor
-- =============================================
-- المشكلة: سياسة FOR ALL USING(true) بدون WITH CHECK
--          تمنع عمليات INSERT (إضافة صفوف جديدة)
-- الحل: إضافة WITH CHECK (true) لكل الجداول
-- =============================================

-- ── admin_settings ──
DROP POLICY IF EXISTS "Full access settings" ON admin_settings;
CREATE POLICY "Full access settings" ON admin_settings
  FOR ALL USING (true) WITH CHECK (true);

-- ── categories ──
DROP POLICY IF EXISTS "Full access categories" ON categories;
CREATE POLICY "Full access categories" ON categories
  FOR ALL USING (true) WITH CHECK (true);

-- ── products ──
DROP POLICY IF EXISTS "Full access products" ON products;
CREATE POLICY "Full access products" ON products
  FOR ALL USING (true) WITH CHECK (true);

-- ── product_extras ──
DROP POLICY IF EXISTS "Full access extras" ON product_extras;
CREATE POLICY "Full access extras" ON product_extras
  FOR ALL USING (true) WITH CHECK (true);

-- ── slider_images ──
DROP POLICY IF EXISTS "Full access sliders" ON slider_images;
CREATE POLICY "Full access sliders" ON slider_images
  FOR ALL USING (true) WITH CHECK (true);

-- ── restaurant_tables (جديد) ──
DROP POLICY IF EXISTS "Full access tables" ON restaurant_tables;
CREATE POLICY "Full access tables" ON restaurant_tables
  FOR ALL USING (true) WITH CHECK (true);

-- ── orders ──
DROP POLICY IF EXISTS "Public insert orders"  ON orders;
DROP POLICY IF EXISTS "Public read orders"    ON orders;
DROP POLICY IF EXISTS "Public update orders"  ON orders;
DROP POLICY IF EXISTS "Public delete orders"  ON orders;
CREATE POLICY "Full access orders" ON orders
  FOR ALL USING (true) WITH CHECK (true);

-- ── order_items ──
DROP POLICY IF EXISTS "Public insert order_items" ON order_items;
DROP POLICY IF EXISTS "Public read order_items"   ON order_items;
DROP POLICY IF EXISTS "Public delete order_items" ON order_items;
CREATE POLICY "Full access order_items" ON order_items
  FOR ALL USING (true) WITH CHECK (true);

-- =============================================
-- تأكيد أن restaurant_logo موجود في الإعدادات
-- =============================================
INSERT INTO admin_settings (key, value)
  VALUES ('restaurant_logo', '')
  ON CONFLICT (key) DO NOTHING;

-- =============================================
-- إنشاء جدول الطاولات (إذا لم يكن موجوداً)
-- =============================================
CREATE TABLE IF NOT EXISTS restaurant_tables (
  id            SERIAL PRIMARY KEY,
  table_number  INTEGER UNIQUE NOT NULL,
  name          TEXT DEFAULT '',
  capacity      INTEGER DEFAULT 4,
  status        TEXT DEFAULT 'available'
    CHECK (status IN ('available','occupied','reserved')),
  current_order_id INTEGER REFERENCES orders(id) ON DELETE SET NULL,
  opened_at     TIMESTAMPTZ,
  is_active     BOOLEAN DEFAULT true
);

INSERT INTO restaurant_tables (table_number, name, capacity)
SELECT
  n,
  'طاولة ' || n,
  CASE WHEN n <= 4 THEN 2 WHEN n <= 12 THEN 4 ELSE 6 END
FROM generate_series(1,20) AS n
ON CONFLICT (table_number) DO NOTHING;

ALTER TABLE restaurant_tables ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Full access tables" ON restaurant_tables;
CREATE POLICY "Full access tables" ON restaurant_tables
  FOR ALL USING (true) WITH CHECK (true);

-- =============================================
-- إضافة أعمدة التوصيل لجدول الطلبات
-- =============================================
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_address  TEXT DEFAULT '';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_landmark TEXT DEFAULT '';
-- (customer_name و customer_phone ربما موجودان بالفعل)
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_name     TEXT DEFAULT '';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_phone    TEXT DEFAULT '';

-- =============================================
-- ✅ اكتمل الإصلاح
-- =============================================
SELECT 'RLS Fix Applied Successfully ✅' AS result;
