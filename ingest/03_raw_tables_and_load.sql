-- 03_raw_tables_and_load.sql
-- Creates the raw tables and loads each CSV from the stage with COPY INTO.
-- Raw keeps every business column as VARCHAR (as-is); typing happens in dbt staging.
-- Each row gets three metadata columns: source file, row number in that file, and load time.

USE ROLE TRANSFORMER;
USE WAREHOUSE TRANSFORM_WH;
USE SCHEMA OLIST.RAW;

-- =========================================================
-- 1. Raw tables (column names exactly as in the CSV headers)
-- =========================================================

CREATE TABLE IF NOT EXISTS OLIST.RAW.CUSTOMERS (
  customer_id                VARCHAR,
  customer_unique_id         VARCHAR,
  customer_zip_code_prefix   VARCHAR,
  customer_city              VARCHAR,
  customer_state             VARCHAR,
  _source_file               VARCHAR,
  _source_row_number         NUMBER,
  _loaded_at                 TIMESTAMP_LTZ
);

CREATE TABLE IF NOT EXISTS OLIST.RAW.ORDERS (
  order_id                       VARCHAR,
  customer_id                    VARCHAR,
  order_status                   VARCHAR,
  order_purchase_timestamp       VARCHAR,
  order_approved_at              VARCHAR,
  order_delivered_carrier_date   VARCHAR,
  order_delivered_customer_date  VARCHAR,
  order_estimated_delivery_date  VARCHAR,
  _source_file                   VARCHAR,
  _source_row_number             NUMBER,
  _loaded_at                     TIMESTAMP_LTZ
);

CREATE TABLE IF NOT EXISTS OLIST.RAW.ORDER_ITEMS (
  order_id              VARCHAR,
  order_item_id         VARCHAR,
  product_id            VARCHAR,
  seller_id             VARCHAR,
  shipping_limit_date   VARCHAR,
  price                 VARCHAR,
  freight_value         VARCHAR,
  _source_file          VARCHAR,
  _source_row_number    NUMBER,
  _loaded_at            TIMESTAMP_LTZ
);

CREATE TABLE IF NOT EXISTS OLIST.RAW.ORDER_PAYMENTS (
  order_id               VARCHAR,
  payment_sequential     VARCHAR,
  payment_type           VARCHAR,
  payment_installments   VARCHAR,
  payment_value          VARCHAR,
  _source_file           VARCHAR,
  _source_row_number     NUMBER,
  _loaded_at             TIMESTAMP_LTZ
);

CREATE TABLE IF NOT EXISTS OLIST.RAW.ORDER_REVIEWS (
  review_id                VARCHAR,
  order_id                 VARCHAR,
  review_score             VARCHAR,
  review_comment_title     VARCHAR,
  review_comment_message   VARCHAR,
  review_creation_date     VARCHAR,
  review_answer_timestamp  VARCHAR,
  _source_file             VARCHAR,
  _source_row_number       NUMBER,
  _loaded_at               TIMESTAMP_LTZ
);

-- Note: "lenght" is misspelt in the source file. Kept as-is in raw, fixed in staging.
CREATE TABLE IF NOT EXISTS OLIST.RAW.PRODUCTS (
  product_id                   VARCHAR,
  product_category_name        VARCHAR,
  product_name_lenght          VARCHAR,
  product_description_lenght   VARCHAR,
  product_photos_qty           VARCHAR,
  product_weight_g             VARCHAR,
  product_length_cm            VARCHAR,
  product_height_cm            VARCHAR,
  product_width_cm             VARCHAR,
  _source_file                 VARCHAR,
  _source_row_number           NUMBER,
  _loaded_at                   TIMESTAMP_LTZ
);

CREATE TABLE IF NOT EXISTS OLIST.RAW.SELLERS (
  seller_id                VARCHAR,
  seller_zip_code_prefix   VARCHAR,
  seller_city              VARCHAR,
  seller_state             VARCHAR,
  _source_file             VARCHAR,
  _source_row_number       NUMBER,
  _loaded_at               TIMESTAMP_LTZ
);

CREATE TABLE IF NOT EXISTS OLIST.RAW.PRODUCT_CATEGORY_TRANSLATION (
  product_category_name           VARCHAR,
  product_category_name_english   VARCHAR,
  _source_file                    VARCHAR,
  _source_row_number              NUMBER,
  _loaded_at                      TIMESTAMP_LTZ
);

-- =========================================================
-- 2. Load: one COPY INTO per file
-- ON_ERROR = 'CONTINUE' -> skip bad rows instead of failing the whole file;
-- error counts are checked afterwards in 04_validate_load.sql
-- =========================================================

COPY INTO OLIST.RAW.CUSTOMERS
FROM (
  SELECT $1, $2, $3, $4, $5,
         METADATA$FILENAME, METADATA$FILE_ROW_NUMBER, METADATA$START_SCAN_TIME
  FROM @OLIST.RAW.OLIST_STAGE
)
FILES = ('olist_customers_dataset.csv')
ON_ERROR = 'CONTINUE';

COPY INTO OLIST.RAW.ORDERS
FROM (
  SELECT $1, $2, $3, $4, $5, $6, $7, $8,
         METADATA$FILENAME, METADATA$FILE_ROW_NUMBER, METADATA$START_SCAN_TIME
  FROM @OLIST.RAW.OLIST_STAGE
)
FILES = ('olist_orders_dataset.csv')
ON_ERROR = 'CONTINUE';

COPY INTO OLIST.RAW.ORDER_ITEMS
FROM (
  SELECT $1, $2, $3, $4, $5, $6, $7,
         METADATA$FILENAME, METADATA$FILE_ROW_NUMBER, METADATA$START_SCAN_TIME
  FROM @OLIST.RAW.OLIST_STAGE
)
FILES = ('olist_order_items_dataset.csv')
ON_ERROR = 'CONTINUE';

COPY INTO OLIST.RAW.ORDER_PAYMENTS
FROM (
  SELECT $1, $2, $3, $4, $5,
         METADATA$FILENAME, METADATA$FILE_ROW_NUMBER, METADATA$START_SCAN_TIME
  FROM @OLIST.RAW.OLIST_STAGE
)
FILES = ('olist_order_payments_dataset.csv')
ON_ERROR = 'CONTINUE';

COPY INTO OLIST.RAW.ORDER_REVIEWS
FROM (
  SELECT $1, $2, $3, $4, $5, $6, $7,
         METADATA$FILENAME, METADATA$FILE_ROW_NUMBER, METADATA$START_SCAN_TIME
  FROM @OLIST.RAW.OLIST_STAGE
)
FILES = ('olist_order_reviews_dataset.csv')
ON_ERROR = 'CONTINUE';

COPY INTO OLIST.RAW.PRODUCTS
FROM (
  SELECT $1, $2, $3, $4, $5, $6, $7, $8, $9,
         METADATA$FILENAME, METADATA$FILE_ROW_NUMBER, METADATA$START_SCAN_TIME
  FROM @OLIST.RAW.OLIST_STAGE
)
FILES = ('olist_products_dataset.csv')
ON_ERROR = 'CONTINUE';

COPY INTO OLIST.RAW.SELLERS
FROM (
  SELECT $1, $2, $3, $4,
         METADATA$FILENAME, METADATA$FILE_ROW_NUMBER, METADATA$START_SCAN_TIME
  FROM @OLIST.RAW.OLIST_STAGE
)
FILES = ('olist_sellers_dataset.csv')
ON_ERROR = 'CONTINUE';

COPY INTO OLIST.RAW.PRODUCT_CATEGORY_TRANSLATION
FROM (
  SELECT $1, $2,
         METADATA$FILENAME, METADATA$FILE_ROW_NUMBER, METADATA$START_SCAN_TIME
  FROM @OLIST.RAW.OLIST_STAGE
)
FILES = ('product_category_name_translation.csv')
ON_ERROR = 'CONTINUE';