# Data model

## 1. Normalised model (staging layer, 3NF)

```mermaid
erDiagram
    CUSTOMERS ||--o{ ORDERS : places
    ORDERS ||--|{ ORDER_ITEMS : contains
    PRODUCTS ||--o{ ORDER_ITEMS : "sold as"
    SELLERS ||--o{ ORDER_ITEMS : fulfils
    ORDERS ||--o{ ORDER_PAYMENTS : "paid by"
    ORDERS ||--o| ORDER_REVIEWS : "reviewed in"
    PRODUCT_CATEGORIES |o--o{ PRODUCTS : classifies

    CUSTOMERS {
        varchar customer_id PK
        varchar customer_unique_id "real person"
        varchar customer_zip_code_prefix
        varchar customer_city
        varchar customer_state
    }
    ORDERS {
        varchar order_id PK
        varchar customer_id FK
        varchar order_status
        timestamp purchased_at
        timestamp delivered_to_customer_at
        timestamp estimated_delivery_at
    }
    ORDER_ITEMS {
        varchar order_item_sk PK "hash(order_id, order_item_number)"
        varchar order_id FK
        number order_item_number
        varchar product_id FK
        varchar seller_id FK
        number price
        number freight_value
    }
    PRODUCTS {
        varchar product_id PK
        varchar product_category_name FK
        number product_weight_g
    }
    PRODUCT_CATEGORIES {
        varchar product_category_name PK
        varchar product_category_name_english
    }
    SELLERS {
        varchar seller_id PK
        varchar seller_city
        varchar seller_state
    }
    ORDER_PAYMENTS {
        varchar payment_sk PK "hash(order_id, payment_sequence)"
        varchar order_id FK
        varchar payment_type
        number payment_value
    }
    ORDER_REVIEWS {
        varchar order_id PK "one review per order"
        varchar review_id
        number review_score
    }
```

**Normalisation reasoning.** Each entity holds facts about one thing only, keyed by its own identifier, and every foreign key is tested with dbt `relationships` tests because Snowflake does not enforce constraints. The main many-to-many relationships, orders ↔ products and orders ↔ sellers, are resolved by `ORDER_ITEMS`, a bridge table with a composite key (order_id + item number) hashed into a single surrogate key. Payments are a separate one-to-many table because one order can be split across several payment methods. I deliberately break 3NF in two places: city and state stay on customers and sellers instead of a separate postcode table, because the geolocation file has several cities per postcode prefix and isn't needed for the analysis; and reviews are reduced to one per order (latest kept), because `review_id` is not unique in the source and the business question is "how did the customer rate this order?".

## 2. Star schema (marts layer)

```mermaid
erDiagram
    DIM_CUSTOMERS ||--o{ FCT_ORDER_ITEMS : customer_sk
    DIM_PRODUCTS ||--o{ FCT_ORDER_ITEMS : product_sk

    FCT_ORDER_ITEMS {
        varchar order_item_sk PK
        varchar customer_sk FK
        varchar product_sk FK
        date order_date
        number price
        number freight_value
        number delivery_days
        number days_late
        boolean is_late
        number review_score
    }
    DIM_CUSTOMERS {
        varchar customer_sk PK
        varchar customer_unique_id
        varchar customer_state
        number lifetime_orders
        boolean is_repeat_customer
    }
    DIM_PRODUCTS {
        varchar product_sk PK
        varchar product_id
        varchar product_category
    }
```

**Why normalise in staging and denormalise in marts.** Staging is normalised so each fact lives in one place and stays consistent and testable. Marts are a star schema so analysts answer business questions with one simple join, without needing to know the source model.

## 3. Key strategy, types and materialisation

| Topic | Approach |
|---|---|
| Keys | Natural keys where unique (order_id, product_id); `dbt_utils.generate_surrogate_key` (MD5 hash) for composite keys and all mart keys |
| Duplicates | Every staging model keeps one row per key with `QUALIFY ROW_NUMBER() OVER (PARTITION BY key ORDER BY _loaded_at DESC) = 1` |
| Proving keys | `unique` + `not_null` on every key, `relationships` on every foreign key (43 tests, all passing) |
| Types | Raw = VARCHAR (lossless landing); staging casts with `TRY_TO_TIMESTAMP_NTZ` / `TRY_TO_NUMBER(…, 10, 2)` so bad values become NULL instead of failing; postcodes stay text to keep leading zeros |
| Materialisation | Raw = tables (COPY INTO); staging = **views** (always fresh, no storage, only read by marts); marts = **tables** (fast for analysts). At larger scale `fct_order_items` would become **incremental** |
| Grain | dim_customers = real person (`customer_unique_id`); fct_order_items = one item sold; reviews = one per order |