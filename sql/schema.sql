-- Tabel raw event dari Kafka
CREATE TABLE IF NOT EXISTS raw_order_events (
    event_id TEXT PRIMARY KEY,
    event_type TEXT NOT NULL,
    event_timestamp TIMESTAMP NOT NULL,
    order_id TEXT NOT NULL,
    customer_id TEXT NOT NULL,
    received_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Tabel staging orders
CREATE TABLE IF NOT EXISTS stg_orders (
    order_id TEXT,
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

-- Tabel staging order items
CREATE TABLE IF NOT EXISTS stg_order_items (
    order_id TEXT,
    order_item_id INTEGER,
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_date TIMESTAMP,
    price NUMERIC(10,2),
    freight_value NUMERIC(10,2)
);

-- Tabel staging customers
CREATE TABLE IF NOT EXISTS stg_customers (
    customer_id TEXT,
    customer_unique_id TEXT,
    customer_zip_code_prefix INTEGER,
    customer_city TEXT,
    customer_state TEXT
);

-- Tabel staging products
CREATE TABLE IF NOT EXISTS stg_products (
    product_id TEXT,
    product_category_name TEXT,
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER
);

-- Tabel staging sellers
CREATE TABLE IF NOT EXISTS stg_sellers (
    seller_id TEXT,
    seller_zip_code_prefix INTEGER,
    seller_city TEXT,
    seller_state TEXT
);

-- Dimensi tanggal
CREATE TABLE IF NOT EXISTS dim_date (
    date_key DATE PRIMARY KEY,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    month_name TEXT NOT NULL,
    quarter INTEGER NOT NULL,
    day INTEGER NOT NULL
);

-- Dimensi customer
CREATE TABLE IF NOT EXISTS dim_customer (
    customer_id TEXT PRIMARY KEY,
    customer_unique_id TEXT NOT NULL,
    customer_zip_code_prefix INTEGER,
    customer_city TEXT,
    customer_state TEXT
);

-- Dimensi product
CREATE TABLE IF NOT EXISTS dim_product (
    product_id TEXT PRIMARY KEY,
    product_category_name TEXT,
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER
);

-- Dimensi seller
CREATE TABLE IF NOT EXISTS dim_seller (
    seller_id TEXT PRIMARY KEY,
    seller_zip_code_prefix INTEGER,
    seller_city TEXT,
    seller_state TEXT
);

-- Tabel fakta order
CREATE TABLE IF NOT EXISTS fact_orders (
    order_id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    order_status TEXT NOT NULL,
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    delivery_days NUMERIC(10,2),
    is_late BOOLEAN,
    total_price NUMERIC(12,2),
    total_freight NUMERIC(12,2),
    order_purchase_date DATE
);

-- Tabel fakta order items
CREATE TABLE IF NOT EXISTS fact_order_items (
    order_id TEXT NOT NULL,
    order_item_id INTEGER NOT NULL,
    product_id TEXT NOT NULL,
    seller_id TEXT NOT NULL,
    shipping_limit_date TIMESTAMP,
    price NUMERIC(10,2) NOT NULL,
    freight_value NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id)
);

-- Relasi fact orders ke dimensi tanggal
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_fact_orders_date'
    ) THEN
        ALTER TABLE fact_orders
        ADD CONSTRAINT fk_fact_orders_date
        FOREIGN KEY (order_purchase_date)
        REFERENCES dim_date(date_key);
    END IF;
END $$;

-- Relasi fact orders ke dimensi customer
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_fact_orders_customer'
    ) THEN
        ALTER TABLE fact_orders
        ADD CONSTRAINT fk_fact_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES dim_customer(customer_id);
    END IF;
END $$;

-- Relasi fact order items ke fact orders
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_order_items_order'
    ) THEN
        ALTER TABLE fact_order_items
        ADD CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES fact_orders(order_id);
    END IF;
END $$;

-- Relasi fact order items ke dimensi product
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_order_items_product'
    ) THEN
        ALTER TABLE fact_order_items
        ADD CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES dim_product(product_id);
    END IF;
END $$;

-- Relasi fact order items ke dimensi seller
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_order_items_seller'
    ) THEN
        ALTER TABLE fact_order_items
        ADD CONSTRAINT fk_order_items_seller
        FOREIGN KEY (seller_id)
        REFERENCES dim_seller(seller_id);
    END IF;
END $$;
