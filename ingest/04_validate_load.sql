-- 04_validate_load.sql
-- Checks after loading: row counts, load errors, encoding, and duplicate keys.

USE ROLE TRANSFORMER;
USE WAREHOUSE TRANSFORM_WH;

-- 1. Row counts per raw table
SELECT 'customers'      AS table_name, COUNT(*) AS row_count FROM OLIST.RAW.CUSTOMERS
UNION ALL SELECT 'orders',          COUNT(*) FROM OLIST.RAW.ORDERS
UNION ALL SELECT 'order_items',     COUNT(*) FROM OLIST.RAW.ORDER_ITEMS
UNION ALL SELECT 'order_payments',  COUNT(*) FROM OLIST.RAW.ORDER_PAYMENTS
UNION ALL SELECT 'order_reviews',   COUNT(*) FROM OLIST.RAW.ORDER_REVIEWS
UNION ALL SELECT 'products',        COUNT(*) FROM OLIST.RAW.PRODUCTS
UNION ALL SELECT 'sellers',         COUNT(*) FROM OLIST.RAW.SELLERS
UNION ALL SELECT 'category_translation', COUNT(*) FROM OLIST.RAW.PRODUCT_CATEGORY_TRANSLATION;

-- 2. Load history: rows parsed vs loaded, and any errors, per file
SELECT table_name,
       file_name,
       status,
       row_parsed,
       row_count       AS rows_loaded,
       error_count,
       first_error_message
FROM OLIST.INFORMATION_SCHEMA.LOAD_HISTORY
WHERE schema_name = 'RAW'
ORDER BY table_name;

-- 3. Encoding check: Portuguese characters should display correctly (e.g. "são paulo")
SELECT DISTINCT customer_city
FROM OLIST.RAW.CUSTOMERS
WHERE customer_city LIKE '%ã%'
LIMIT 5;

-- 4. Duplicate check on what should be unique keys (handled later in staging)
SELECT 'orders.order_id' AS key_checked,
       COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_rows
FROM OLIST.RAW.ORDERS
UNION ALL
SELECT 'order_reviews.review_id',
       COUNT(*) - COUNT(DISTINCT review_id)
FROM OLIST.RAW.ORDER_REVIEWS
UNION ALL
SELECT 'products.product_id',
       COUNT(*) - COUNT(DISTINCT product_id)
FROM OLIST.RAW.PRODUCTS;