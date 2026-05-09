-- =============================================
-- مطعم النخبة - Supabase PostgreSQL Schema
-- انسخ هذا الكود والصقه في Supabase SQL Editor
-- =============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ---- CATEGORIES ----
CREATE TABLE IF NOT EXISTS categories (
  id SERIAL PRIMARY KEY,
  name_ar TEXT NOT NULL,
  name_en TEXT DEFAULT '',
  icon TEXT DEFAULT '🍽️',
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ---- PRODUCTS ----
CREATE TABLE IF NOT EXISTS products (
  id SERIAL PRIMARY KEY,
  category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
  name_ar TEXT NOT NULL,
  name_en TEXT DEFAULT '',
  description_ar TEXT DEFAULT '',
  price NUMERIC(10,2) NOT NULL DEFAULT 0,
  image_url TEXT DEFAULT '',
  video_url TEXT DEFAULT '',
  stock INTEGER DEFAULT 100,
  is_available BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ---- PRODUCT EXTRAS ----
CREATE TABLE IF NOT EXISTS product_extras (
  id SERIAL PRIMARY KEY,
  product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
  name_ar TEXT NOT NULL,
  name_en TEXT DEFAULT '',
  price NUMERIC(10,2) DEFAULT 0,
  is_active BOOLEAN DEFAULT true
);

-- ---- ORDERS ----
CREATE TABLE IF NOT EXISTS orders (
  id SERIAL PRIMARY KEY,
  order_number TEXT UNIQUE NOT NULL,
  table_number INTEGER,
  order_type TEXT DEFAULT 'dine_in' CHECK (order_type IN ('dine_in','takeaway')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','confirmed','preparing','ready','delivered','cancelled')),
  total_amount NUMERIC(10,2) DEFAULT 0,
  notes TEXT DEFAULT '',
  customer_name TEXT DEFAULT '',
  customer_phone TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ---- ORDER ITEMS ----
CREATE TABLE IF NOT EXISTS order_items (
  id SERIAL PRIMARY KEY,
  order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
  product_id INTEGER REFERENCES products(id) ON DELETE SET NULL,
  product_name TEXT NOT NULL,
  product_price NUMERIC(10,2) NOT NULL,
  quantity INTEGER DEFAULT 1,
  extras JSONB DEFAULT '[]',
  extras_price NUMERIC(10,2) DEFAULT 0,
  item_total NUMERIC(10,2) DEFAULT 0,
  notes TEXT DEFAULT ''
);

-- ---- ADMIN SETTINGS ----
CREATE TABLE IF NOT EXISTS admin_settings (
  id SERIAL PRIMARY KEY,
  key TEXT UNIQUE NOT NULL,
  value TEXT DEFAULT '',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ---- SLIDER IMAGES ----
CREATE TABLE IF NOT EXISTS slider_images (
  id SERIAL PRIMARY KEY,
  image_url TEXT NOT NULL,
  title_ar TEXT DEFAULT '',
  subtitle_ar TEXT DEFAULT '',
  link TEXT DEFAULT '',
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true
);

-- =============================================
-- VIEW: products with category name
-- =============================================
CREATE OR REPLACE VIEW products_with_category AS
SELECT
  p.*,
  c.name_ar AS cat_name,
  c.icon AS cat_icon
FROM products p
LEFT JOIN categories c ON p.category_id = c.id;

-- =============================================
-- Row Level Security (RLS) - Public Read
-- =============================================
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_extras ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE slider_images ENABLE ROW LEVEL SECURITY;

-- Allow public read for menu tables
CREATE POLICY "Public read categories" ON categories FOR SELECT USING (true);
CREATE POLICY "Public read products" ON products FOR SELECT USING (true);
CREATE POLICY "Public read extras" ON product_extras FOR SELECT USING (true);
CREATE POLICY "Public read sliders" ON slider_images FOR SELECT USING (true);

-- Allow public insert/read for orders (customers place orders)
CREATE POLICY "Public insert orders" ON orders FOR INSERT WITH CHECK (true);
CREATE POLICY "Public read orders" ON orders FOR SELECT USING (true);
CREATE POLICY "Public update orders" ON orders FOR UPDATE USING (true);
CREATE POLICY "Public delete orders" ON orders FOR DELETE USING (true);
CREATE POLICY "Public insert order_items" ON order_items FOR INSERT WITH CHECK (true);
CREATE POLICY "Public read order_items" ON order_items FOR SELECT USING (true);
CREATE POLICY "Public delete order_items" ON order_items FOR DELETE USING (true);

-- Allow full access (USING + WITH CHECK for INSERT/UPDATE)
CREATE POLICY "Full access categories" ON categories FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Full access products"   ON products   FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Full access extras"     ON product_extras FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Full access settings"   ON admin_settings FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Full access sliders"    ON slider_images  FOR ALL USING (true) WITH CHECK (true);

-- =============================================
-- DEFAULT DATA
-- =============================================

INSERT INTO admin_settings (key, value) VALUES
  ('admin_password', '1234'),
  ('restaurant_name', 'مطعم النخبة'),
  ('restaurant_logo', ''),
  ('currency', 'ج.م'),
  ('welcome_message', 'أهلاً بكم في مطعمنا')
ON CONFLICT (key) DO NOTHING;

INSERT INTO categories (name_ar, name_en, icon, sort_order) VALUES
  ('المقبلات', 'Appetizers', '🥗', 1),
  ('الوجبات الرئيسية', 'Main Courses', '🍽️', 2),
  ('المشويات', 'Grills', '🔥', 3),
  ('البيتزا', 'Pizza', '🍕', 4),
  ('البرجر', 'Burgers', '🍔', 5),
  ('المعكرونة', 'Pasta', '🍝', 6),
  ('السلطات', 'Salads', '🥙', 7),
  ('الحلويات', 'Desserts', '🍰', 8),
  ('المشروبات', 'Beverages', '🥤', 9)
ON CONFLICT DO NOTHING;

-- Insert sample products (category_ids 1-9 from above)
INSERT INTO products (category_id, name_ar, name_en, description_ar, price, stock, is_featured, image_url) VALUES
  (2, 'شيش طاووق', 'Chicken Shish', 'دجاج مشوي بالتوابل الشرقية مع خبز وصلصة', 85, 50, true, 'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=400'),
  (2, 'كباب مشوي', 'Grilled Kebab', 'كباب لحم بالفحم مع أرز وسلطة', 95, 30, true, 'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?w=400'),
  (5, 'برجر كلاسيك', 'Classic Burger', 'برجر لحم بقري مع خس وطماطم وجبن', 75, 40, true, 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400'),
  (4, 'بيتزا مارجريتا', 'Margherita Pizza', 'بيتزا بصلصة الطماطم والجبن والريحان', 90, 25, false, 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400'),
  (6, 'مكرونة بولونيز', 'Bolognese Pasta', 'مكرونة بصلصة اللحم الإيطالية', 70, 35, false, 'https://images.unsplash.com/photo-1555949258-eb67b1ef0ceb?w=400'),
  (8, 'كنافة بالجبن', 'Knafeh', 'كنافة نابلسية أصلية بالجبن والعسل', 45, 20, true, 'https://images.unsplash.com/photo-1579954115545-a95591f28bfc?w=400'),
  (9, 'عصير مانجو', 'Mango Juice', 'عصير مانجو طازج 100%', 30, 100, false, 'https://images.unsplash.com/photo-1546173159-315724a31696?w=400'),
  (1, 'سمبوسك', 'Sambousek', 'سمبوسك بالجبن واللحم مقلي', 35, 0, false, 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400'),
  (3, 'دجاج مشوي كامل', 'Whole Grilled Chicken', 'دجاجة كاملة مشوية بالأعشاب والتوابل', 120, 15, true, 'https://images.unsplash.com/photo-1598103442097-8b74394b95c8?w=400'),
  (5, 'كريسبي برجر', 'Crispy Burger', 'برجر دجاج مقرمش مع صلصة خاصة', 80, 45, false, 'https://images.unsplash.com/photo-1606755962773-d324e0a13086?w=400');

INSERT INTO slider_images (image_url, title_ar, subtitle_ar, sort_order) VALUES
  ('https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=1200', 'أهلاً بكم في مطعم النخبة', 'تجربة طعام لا تُنسى', 1),
  ('https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=1200', 'أشهى المأكولات الشرقية', 'مع أفضل الطهاة المحترفين', 2),
  ('https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=1200', 'عروض خاصة يومية', 'وجبات طازجة بأسعار مميزة', 3);

-- =============================================
-- Function to auto-update updated_at
-- =============================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER products_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER orders_updated_at BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =============================================
-- Enable Realtime for orders table
-- =============================================
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime FOR TABLE orders;
COMMIT;

-- =============================================
-- TABLES MANAGEMENT (إضافة جديدة)
-- =============================================
CREATE TABLE IF NOT EXISTS restaurant_tables (
  id            SERIAL PRIMARY KEY,
  table_number  INTEGER UNIQUE NOT NULL,
  name          TEXT DEFAULT '',
  capacity      INTEGER DEFAULT 4,
  status        TEXT DEFAULT 'available'   -- available | occupied | reserved
    CHECK (status IN ('available','occupied','reserved')),
  current_order_id INTEGER REFERENCES orders(id) ON DELETE SET NULL,
  opened_at     TIMESTAMPTZ,
  is_active     BOOLEAN DEFAULT true
);

-- Insert default tables 1-20
INSERT INTO restaurant_tables (table_number, name, capacity)
SELECT
  n,
  'طاولة ' || n,
  CASE WHEN n <= 4 THEN 2 WHEN n <= 12 THEN 4 ELSE 6 END
FROM generate_series(1,20) AS n
ON CONFLICT (table_number) DO NOTHING;

-- RLS for tables
ALTER TABLE restaurant_tables ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Full access tables" ON restaurant_tables FOR ALL USING (true) WITH CHECK (true);

-- Add missing columns to orders (customer info for takeaway)
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_name  TEXT DEFAULT '';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_phone TEXT DEFAULT '';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_address TEXT DEFAULT '';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_landmark TEXT DEFAULT '';

-- Index for fast lookup
CREATE INDEX IF NOT EXISTS idx_orders_table ON orders(table_number) WHERE status NOT IN ('delivered','cancelled');
