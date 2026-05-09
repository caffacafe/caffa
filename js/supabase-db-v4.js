// =============================================
// Supabase Database Layer - النسخة المُصلَّحة
// الإصلاح: upsertSetting يستخدم ?on_conflict=key
// =============================================

const SUPABASE_CONFIG = {
  url: window.SUPABASE_URL || 'https://YOUR_PROJECT.supabase.co',
  key: window.SUPABASE_KEY || 'YOUR_ANON_KEY'
};

function isSupabaseConfigured() {
  return !SUPABASE_CONFIG.url.includes('YOUR_PROJECT') &&
         !SUPABASE_CONFIG.key.includes('YOUR_ANON_KEY');
}

// =============================================
// HTTP Helper
// =============================================
async function sbFetch(table, options = {}) {
  const { method = 'GET', filters = '', body = null,
          select = '*', order = '', limit = '' } = options;
  let url = `${SUPABASE_CONFIG.url}/rest/v1/${table}`;
  const params = [];
  if (select !== '*' || filters || order || limit) {
    if (select) params.push(`select=${select}`);
    if (filters) params.push(filters);
    if (order)   params.push(`order=${order}`);
    if (limit)   params.push(`limit=${limit}`);
    if (params.length) url += '?' + params.join('&');
  }
  const headers = {
    'apikey':        SUPABASE_CONFIG.key,
    'Authorization': 'Bearer ' + SUPABASE_CONFIG.key,
    'Content-Type':  'application/json',
    'Prefer':        'return=representation'
  };
  const res = await fetch(url, {
    method,
    headers,
    body: body ? JSON.stringify(body) : null
  });
  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`Supabase ${res.status}: ${txt}`);
  }
  const text = await res.text();
  return text ? JSON.parse(text) : [];
}

// PATCH helper (used heavily in settings)
async function sbPatch(table, filter, body) {
  const res = await fetch(
    `${SUPABASE_CONFIG.url}/rest/v1/${table}?${filter}`,
    {
      method: 'PATCH',
      headers: {
        'apikey':        SUPABASE_CONFIG.key,
        'Authorization': 'Bearer ' + SUPABASE_CONFIG.key,
        'Content-Type':  'application/json',
        'Prefer':        'return=representation'
      },
      body: JSON.stringify(body)
    }
  );
  const text = await res.text();
  return text ? JSON.parse(text) : [];
}

// =============================================
// Realtime (WebSocket)
// =============================================
function subscribeToOrders(callback) {
  if (!isSupabaseConfigured()) return;
  const wsUrl = SUPABASE_CONFIG.url.replace('https://', 'wss://')
    + '/realtime/v1/websocket?apikey=' + SUPABASE_CONFIG.key + '&vsn=1.0.0';
  try {
    const ws = new WebSocket(wsUrl);
    ws.onopen = () => {
      ws.send(JSON.stringify({
        topic: 'realtime:public:orders',
        event: 'phx_join', payload: {}, ref: 1
      }));
    };
    ws.onmessage = (e) => {
      const msg = JSON.parse(e.data);
      if (['INSERT','UPDATE','DELETE'].includes(msg.event)) {
        callback(msg.event, msg.payload?.record);
      }
    };
    ws.onerror = () => {};
  } catch(e) {}
}

// =============================================
// DB API
// =============================================
const DB = {

  // ══════════════════════════════════════════
  // SETTINGS — الإصلاح الرئيسي هنا
  // ══════════════════════════════════════════
  getSetting: async (key) => {
    try {
      const rows = await sbFetch('admin_settings', {
        filters: `key=eq.${encodeURIComponent(key)}`,
        order:   'updated_at.desc',
        limit:   '1'
      });
      return rows[0]?.value ?? '';
    } catch(e) { return ''; }
  },

  // الدالة الأساسية: POST مع ?on_conflict=key (الطريقة الرسمية لـ Supabase)
  // ─── upsertSetting: إصلاح شامل ───
  // الاستراتيجية:
  //  1) PATCH أولاً (UPDATE) — يعمل دائماً مع USING(true) حتى بدون WITH CHECK
  //  2) إذا لم يُعدَّل أي صف → الصف غير موجود → أنشئه
  //  3) كل خطوة تُسجّل الخطأ بوضوح في console
  upsertSetting: async (key, value) => {
    const now = new Date().toISOString();
    const headers = {
      'apikey':        SUPABASE_CONFIG.key,
      'Authorization': 'Bearer ' + SUPABASE_CONFIG.key,
      'Content-Type':  'application/json',
      'Prefer':        'return=representation'
    };

    try {
      // ── خطوة 1: PATCH (UPDATE) ──
      const patchRes = await fetch(
        `${SUPABASE_CONFIG.url}/rest/v1/admin_settings?key=eq.${encodeURIComponent(key)}`,
        { method: 'PATCH', headers, body: JSON.stringify({ value, updated_at: now }) }
      );

      if (!patchRes.ok) {
        const err = await patchRes.text();
        console.warn(`PATCH failed for "${key}": ${patchRes.status} ${err}`);
        // جرّب INSERT كـ fallback
        throw new Error('patch_failed');
      }

      const patchData = await patchRes.json().catch(() => []);

      if (Array.isArray(patchData) && patchData.length > 0) {
        return true; // ✅ تم التحديث بنجاح
      }

      // ── خطوة 2: الصف غير موجود → INSERT ──
      const insertRes = await fetch(
        `${SUPABASE_CONFIG.url}/rest/v1/admin_settings`,
        { method: 'POST', headers, body: JSON.stringify({ key, value, updated_at: now }) }
      );

      if (!insertRes.ok) {
        const err = await insertRes.text();
        console.error(`INSERT failed for "${key}": ${insertRes.status} ${err}`);
        // آخر محاولة: upsert مع on_conflict
        const upsertRes = await fetch(
          `${SUPABASE_CONFIG.url}/rest/v1/admin_settings?on_conflict=key`,
          {
            method: 'POST',
            headers: { ...headers, 'Prefer': 'resolution=merge-duplicates,return=representation' },
            body: JSON.stringify({ key, value, updated_at: now })
          }
        );
        if (!upsertRes.ok) {
          const e2 = await upsertRes.text();
          console.error(`UPSERT also failed for "${key}": ${upsertRes.status} ${e2}`);
          return false;
        }
      }
      return true;

    } catch(e) {
      if (e.message === 'patch_failed') {
        // حاول INSERT مباشرة
        try {
          await fetch(
            `${SUPABASE_CONFIG.url}/rest/v1/admin_settings`,
            { method: 'POST', headers, body: JSON.stringify({ key, value, updated_at: now }) }
          );
          return true;
        } catch(e3) {
          console.error(`All methods failed for "${key}":`, e3);
          return false;
        }
      }
      console.error(`upsertSetting exception for "${key}":`, e);
      return false;
    }
  },

  // alias للتوافق مع الكود القديم
  updateSetting: async (key, value) => DB.upsertSetting(key, value),

  // حذف التكرارات إن وُجدت (أداة صيانة)
  deduplicateSettings: async () => {
    try {
      const all = await sbFetch('admin_settings', { order: 'updated_at.asc' });
      const seen = {};
      for (const row of all) {
        if (seen[row.key]) {
          // احذف الصف القديم (الأصغر id)
          await fetch(
            `${SUPABASE_CONFIG.url}/rest/v1/admin_settings?id=eq.${seen[row.key]}`,
            { method: 'DELETE',
              headers: { 'apikey': SUPABASE_CONFIG.key,
                         'Authorization': 'Bearer ' + SUPABASE_CONFIG.key } }
          );
        }
        seen[row.key] = row.id;
      }
    } catch(e) {}
  },

  // ══════════════════════════════════════════
  // CATEGORIES
  // ══════════════════════════════════════════
  getCategories: async () =>
    sbFetch('categories', { filters: 'is_active=eq.true', order: 'sort_order.asc' }),

  getAllCategories: async () =>
    sbFetch('categories', { order: 'sort_order.asc' }),

  addCategory: async (data) => {
    const r = await sbFetch('categories', { method: 'POST', body: data });
    return r[0];
  },

  updateCategory: async (id, data) =>
    sbPatch('categories', `id=eq.${id}`, data),

  deleteCategory: async (id) => {
    await fetch(`${SUPABASE_CONFIG.url}/rest/v1/categories?id=eq.${id}`, {
      method: 'DELETE',
      headers: { 'apikey': SUPABASE_CONFIG.key,
                 'Authorization': 'Bearer ' + SUPABASE_CONFIG.key }
    });
  },

  // ══════════════════════════════════════════
  // PRODUCTS
  // ══════════════════════════════════════════
  getProducts: async (categoryId = null) => {
    const filter = categoryId ? `category_id=eq.${categoryId}` : '';
    return sbFetch('products_with_category', {
      filters: filter, order: 'sort_order.asc,id.asc'
    });
  },

  getFeaturedProducts: async () =>
    sbFetch('products', {
      filters: 'is_featured=eq.true&is_available=eq.true',
      order:   'sort_order.asc',
      limit:   '10'
    }),

  getProduct: async (id) => {
    const r = await sbFetch('products_with_category', { filters: `id=eq.${id}` });
    return r[0];
  },

  addProduct: async (data) => {
    const r = await sbFetch('products', { method: 'POST', body: data });
    return r[0];
  },

  updateProduct: async (id, data) => {
    data.updated_at = new Date().toISOString();
    return sbPatch('products', `id=eq.${id}`, data);
  },

  updateStock: async (id, stock) =>
    sbPatch('products', `id=eq.${id}`, {
      stock,
      is_available: stock > 0,
      updated_at:   new Date().toISOString()
    }),

  deleteProduct: async (id) => {
    await fetch(`${SUPABASE_CONFIG.url}/rest/v1/products?id=eq.${id}`, {
      method: 'DELETE',
      headers: { 'apikey': SUPABASE_CONFIG.key,
                 'Authorization': 'Bearer ' + SUPABASE_CONFIG.key }
    });
  },

  // ══════════════════════════════════════════
  // PRODUCT EXTRAS
  // ══════════════════════════════════════════
  getExtras: async (productId) =>
    sbFetch('product_extras', {
      filters: `product_id=eq.${productId}&is_active=eq.true`
    }),

  addExtra: async (data) =>
    sbFetch('product_extras', { method: 'POST', body: data }),

  deleteExtra: async (id) => {
    await fetch(`${SUPABASE_CONFIG.url}/rest/v1/product_extras?id=eq.${id}`, {
      method: 'DELETE',
      headers: { 'apikey': SUPABASE_CONFIG.key,
                 'Authorization': 'Bearer ' + SUPABASE_CONFIG.key }
    });
  },

  deleteExtrasByProduct: async (productId) => {
    await fetch(
      `${SUPABASE_CONFIG.url}/rest/v1/product_extras?product_id=eq.${productId}`,
      { method: 'DELETE',
        headers: { 'apikey': SUPABASE_CONFIG.key,
                   'Authorization': 'Bearer ' + SUPABASE_CONFIG.key } }
    );
  },

  // ══════════════════════════════════════════
  // SLIDER IMAGES
  // ══════════════════════════════════════════
  getSliders: async () =>
    sbFetch('slider_images', { filters: 'is_active=eq.true', order: 'sort_order.asc' }),

  getAllSliders: async () =>
    sbFetch('slider_images', { order: 'sort_order.asc' }),

  addSlider: async (data) =>
    sbFetch('slider_images', { method: 'POST', body: data }),

  deleteSlider: async (id) => {
    await fetch(`${SUPABASE_CONFIG.url}/rest/v1/slider_images?id=eq.${id}`, {
      method: 'DELETE',
      headers: { 'apikey': SUPABASE_CONFIG.key,
                 'Authorization': 'Bearer ' + SUPABASE_CONFIG.key }
    });
  },

  // ══════════════════════════════════════════
  // ORDERS
  // ══════════════════════════════════════════
  getOrders: async (status = null) => {
    const filter = status ? `status=eq.${status}` : '';
    return sbFetch('orders', { filters: filter, order: 'created_at.desc' });
  },

  getOrder: async (id) => {
    const r = await sbFetch('orders', { filters: `id=eq.${id}` });
    return r[0];
  },

  getOrderItems: async (orderId) =>
    sbFetch('order_items', { filters: `order_id=eq.${orderId}` }),

  createOrder: async (data) => {
    const orderNum = 'ORD-' + Date.now();
    const orderRes = await sbFetch('orders', {
      method: 'POST',
      body: {
        order_number:  orderNum,
        table_number:  data.table_number || null,
        order_type:    data.order_type || 'dine_in',
        status:        'pending',
        total_amount:  data.total_amount,
        notes:         data.notes || ''
      }
    });
    const orderId = orderRes[0]?.id;
    if (!orderId) throw new Error('Failed to create order');

    // Insert items
    const items = data.items.map(it => ({
      order_id:      orderId,
      product_id:    it.product_id,
      product_name:  it.product_name,
      product_price: it.product_price,
      quantity:      it.quantity,
      extras:        JSON.stringify(it.extras || []),
      extras_price:  it.extras_price || 0,
      item_total:    it.item_total,
      notes:         it.notes || ''
    }));
    await sbFetch('order_items', { method: 'POST', body: items });

    // Decrement stock
    for (const it of data.items) {
      try {
        const prod = await DB.getProduct(it.product_id);
        if (prod) {
          const newStock = Math.max(0, (prod.stock || 0) - it.quantity);
          await DB.updateStock(it.product_id, newStock);
        }
      } catch(e) {}
    }
    return { orderId, orderNum };
  },

  updateOrderStatus: async (id, status) =>
    sbPatch('orders', `id=eq.${id}`, {
      status,
      updated_at: new Date().toISOString()
    }),

  deleteOrder: async (id) => {
    await fetch(
      `${SUPABASE_CONFIG.url}/rest/v1/order_items?order_id=eq.${id}`,
      { method: 'DELETE',
        headers: { 'apikey': SUPABASE_CONFIG.key,
                   'Authorization': 'Bearer ' + SUPABASE_CONFIG.key } }
    );
    await fetch(
      `${SUPABASE_CONFIG.url}/rest/v1/orders?id=eq.${id}`,
      { method: 'DELETE',
        headers: { 'apikey': SUPABASE_CONFIG.key,
                   'Authorization': 'Bearer ' + SUPABASE_CONFIG.key } }
    );
  },

  getTodayStats: async () => {
    try {
      const today = new Date().toISOString().split('T')[0];
      const orders = await sbFetch('orders', {
        filters: `created_at=gte.${today}T00:00:00&status=neq.cancelled`,
        select:  'total_amount'
      });
      const pending = await sbFetch('orders', {
        filters: 'status=eq.pending',
        select:  'id'
      });
      const revenue = orders.reduce((s, o) => s + (+o.total_amount || 0), 0);
      return { total: orders.length, revenue, pending: pending.length };
    } catch(e) {
      return { total: 0, revenue: 0, pending: 0 };
    }
  },

  subscribeToOrders,
  isConfigured: isSupabaseConfigured
};

window.DB = DB;
window.SUPABASE_CONFIG = SUPABASE_CONFIG;

// ══════════════════════════════════════════════
// RESTAURANT TABLES  (إضافة جديدة)
// ══════════════════════════════════════════════
DB.getTables = async () => {
  return sbFetch('restaurant_tables', {
    filters: 'is_active=eq.true',
    order:   'table_number.asc'
  });
};

DB.getTable = async (tableNumber) => {
  const r = await sbFetch('restaurant_tables', {
    filters: `table_number=eq.${tableNumber}`
  });
  return r[0];
};

// الحصول على الطلب الحالي المفتوح لطاولة معينة
DB.getActiveOrderForTable = async (tableNumber) => {
  const rows = await sbFetch('orders', {
    filters: `table_number=eq.${tableNumber}&status=in.(pending,confirmed,preparing,ready)`,
    order:   'created_at.desc',
    limit:   '1'
  });
  return rows[0] || null;
};

// تحديث حالة الطاولة
DB.setTableStatus = async (tableNumber, status, orderId = null) => {
  const body = {
    status,
    current_order_id: orderId,
    opened_at: status === 'occupied' ? new Date().toISOString() : null
  };
  return sbPatch('restaurant_tables', `table_number=eq.${tableNumber}`, body);
};

// غلق الطاولة وتحرير مقعدها
DB.closeTable = async (tableNumber) => {
  // أنهِ كل الطلبات المفتوحة لهذه الطاولة
  await sbPatch('orders',
    `table_number=eq.${tableNumber}&status=in.(pending,confirmed,preparing,ready)`,
    { status: 'delivered', updated_at: new Date().toISOString() }
  );
  // حرّر الطاولة
  return DB.setTableStatus(tableNumber, 'available', null);
};

// إضافة أصناف لطلب موجود (دمج في نفس الفاتورة)
DB.addItemsToOrder = async (orderId, items, extraTotal) => {
  const newItems = items.map(it => ({
    order_id:      orderId,
    product_id:    it.product_id,
    product_name:  it.product_name,
    product_price: it.product_price,
    quantity:      it.quantity,
    extras:        JSON.stringify(it.extras || []),
    extras_price:  it.extras_price || 0,
    item_total:    it.item_total,
    notes:         it.notes || ''
  }));
  await sbFetch('order_items', { method: 'POST', body: newItems });

  // تحديث إجمالي الفاتورة
  const order = await DB.getOrder(orderId);
  const newTotal = (order?.total_amount || 0) + extraTotal;
  await sbPatch('orders', `id=eq.${orderId}`, {
    total_amount: newTotal,
    updated_at:   new Date().toISOString()
  });

  // تحديث المخزون
  for (const it of items) {
    try {
      const prod = await DB.getProduct(it.product_id);
      if (prod) await DB.updateStock(it.product_id, Math.max(0, (prod.stock||0) - it.quantity));
    } catch(e) {}
  }
  return newTotal;
};

// تعديل createOrder ليُشغّل الطاولة تلقائياً
const _origCreateOrder = DB.createOrder.bind(DB);
DB.createOrder = async (data) => {
  const result = await _origCreateOrder(data);
  // شغّل الطاولة إذا كان الطلب داخلياً
  if (data.table_number && data.order_type === 'dine_in') {
    await DB.setTableStatus(data.table_number, 'occupied', result.orderId);
  }
  return result;
};
