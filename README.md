# 🍽️ مطعم النخبة — منيو إلكتروني + Supabase

منيو إلكتروني احترافي متكامل مع قاعدة بيانات PostgreSQL سحابية حقيقية عبر Supabase.

---

## 🚀 خطوات الإعداد الكاملة

### الخطوة 1: إنشاء مشروع Supabase

1. اذهب إلى **https://supabase.com**
2. اضغط **"Start your project"** وسجّل بـ GitHub أو البريد الإلكتروني
3. اضغط **"New Project"**
4. اختر اسماً للمشروع (مثلاً: `restaurant-menu`)
5. أدخل كلمة مرور لقاعدة البيانات (احتفظ بها)
6. اختر المنطقة الأقرب: **Europe (Frankfurt)** للشرق الأوسط
7. اضغط **"Create new project"** وانتظر دقيقة

---

### الخطوة 2: إنشاء جداول قاعدة البيانات

1. من القائمة الجانبية اضغط على **"SQL Editor"**
2. اضغط **"New query"**
3. افتح ملف `db/supabase-schema.sql` من هذا المشروع
4. **انسخ كل المحتوى** والصقه في SQL Editor
5. اضغط **"Run"** (أو Ctrl+Enter)
6. يجب أن ترى رسالة: `Success. No rows returned`

---

### الخطوة 3: الحصول على مفاتيح API

1. من القائمة الجانبية اضغط **"Project Settings"** ثم **"API"**
2. انسخ القيمتين التاليتين:
   - **Project URL** — يشبه: `https://abcdefgh.supabase.co`
   - **anon / public** (تحت API Keys) — مفتاح طويل يبدأ بـ `eyJ...`

---

### الخطوة 4: إضافة المفاتيح للمشروع

افتح ملف `js/config.js` وعدّله:

```javascript
window.SUPABASE_URL = 'https://YOUR_PROJECT_ID.supabase.co';
window.SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

**مثال حقيقي:**
```javascript
window.SUPABASE_URL = 'https://xyzabcdefgh.supabase.co';
window.SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSJ9.xxxxx';
```

---

### الخطوة 5: رفع المشروع على GitHub

```bash
# 1. أنشئ repository جديد على github.com (اسم مثلاً: restaurant-menu)

# 2. في الـ terminal / command prompt:
git init
git add .
git commit -m "🍽️ Restaurant Menu - Initial Setup"
git branch -M main
git remote add origin https://github.com/USERNAME/restaurant-menu.git
git push -u origin main
```

---

### الخطوة 6: تفعيل GitHub Pages

1. اذهب إلى repository على GitHub
2. اضغط **"Settings"** (الإعدادات)
3. من القائمة الجانبية اضغط **"Pages"**
4. تحت **"Source"** اختر **"GitHub Actions"**
5. سيبدأ النشر تلقائياً خلال دقيقة

**روابطك النهائية:**
```
المنيو:    https://USERNAME.github.io/restaurant-menu/
الإدارة:  https://USERNAME.github.io/restaurant-menu/admin/
```

---

## 📁 هيكل الملفات

```
restaurant-menu/
│
├── index.html              ← 🍽️ واجهة العميل (المنيو)
│
├── admin/
│   └── index.html          ← 🔐 لوحة الإدارة
│
├── js/
│   ├── config.js           ← ⚙️ ضع هنا مفاتيح Supabase
│   └── supabase-db.js      ← 🗄️ طبقة قاعدة البيانات
│
├── db/
│   └── supabase-schema.sql ← 📋 مخطط قاعدة البيانات PostgreSQL
│
└── .github/
    └── workflows/
        └── deploy.yml      ← 🚀 نشر تلقائي على GitHub Pages
```

---

## 🎨 المميزات

### واجهة العميل
| الميزة | التفاصيل |
|--------|----------|
| 🎬 شاشة Splash | لوجو مطعم النخبة عند فتح الموقع |
| 🖼️ سلايدر متحرك | مع أوتوبلاي وأزرار تنقل |
| 🔍 بحث فوري | يبحث في الاسم والوصف |
| 📁 تصفية بالأقسام | شريط أقسام ثابت أثناء التمرير |
| 🎥 دعم الفيديو | يعرض فيديو لكل وجبة |
| ✅ المنتجات المنفذة | تظهر شفافة مع "نفذت الكمية" |
| 🛒 سلة مشتريات | مع إضافات وملاحظات لكل وجبة |
| 🪑 رقم الطاولة | اختيار الطاولة من شبكة تفاعلية |
| 🥡 تيك أواي | خيار منفصل للطلب خارج المطعم |
| 📱 متجاوب | يعمل على الموبايل والتابلت والكمبيوتر |

### لوحة الإدارة
| الميزة | التفاصيل |
|--------|----------|
| 🔐 رمز سري | محفوظ في Supabase |
| 📊 داشبورد | إيرادات اليوم وعدد الطلبات |
| 📋 إدارة الطلبات | مع تغيير الحالة وعرض التفاصيل |
| 🍔 إدارة المنتجات | إضافة/تعديل/حذف مع صورة وفيديو |
| 🧩 الإضافات | إضافات لكل وجبة مع أسعار مستقلة |
| 📦 إدارة المخزون | تنبيه للمنخفض وتعطيل عند النفاد |
| 🖼️ السلايدر | إضافة/حذف صور السلايدر |
| 💰 التقارير | إجمالي الإيرادات وكل الطلبات |
| ⚙️ الإعدادات | اسم المطعم والعملة والرمز السري |
| 🔴 مباشر | Realtime - يتحدث تلقائياً عند وصول طلب |

---

## 🔐 البيانات الافتراضية

| الإعداد | القيمة |
|---------|--------|
| رمز سري الإدارة | `1234` |
| يمكن تغييره من | لوحة الإدارة → الإعدادات |

---

## 🗄️ جداول قاعدة البيانات

```
categories      ← الأقسام
products        ← المنتجات
product_extras  ← إضافات كل منتج
orders          ← الطلبات
order_items     ← تفاصيل كل طلب
admin_settings  ← إعدادات المطعم
slider_images   ← صور السلايدر
```

---

## 🔄 مزامنة البيانات

- ✅ **كل الأجهزة** تقرأ من Supabase مباشرة
- ✅ **الطلبات** تُحفظ فوراً في PostgreSQL
- ✅ **المخزون** يُحدَّث تلقائياً عند كل طلب
- ✅ **لوحة الإدارة** تتحدث كل 20 ثانية + Realtime WebSocket

---

## ❓ أسئلة شائعة

**س: هل Supabase مجاني فعلاً؟**
ج: نعم، الخطة المجانية تشمل 500MB قاعدة بيانات و50,000 طلب/شهر، كافي لأي مطعم.

**س: هل البيانات تُحفظ إذا أُغلق الموقع؟**
ج: نعم، كل البيانات في PostgreSQL على سيرفرات Supabase.

**س: كيف أرى الطلبات من أي جهاز؟**
ج: افتح `https://USERNAME.github.io/restaurant-menu/admin/` من أي جهاز.

**س: كيف أغير رمز الإدارة؟**
ج: من لوحة الإدارة → الإعدادات → تغيير الرمز السري.
