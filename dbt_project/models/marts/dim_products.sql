with products as (
    select * from {{ ref('stg_products') }}
),

translation as (
    select * from {{ ref('stg_product_category_translation') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['p.product_id']) }}               as product_sk,
        p.product_id,
        coalesce(t.product_category_name_english, p.product_category_name, 'unknown') as product_category,
        p.product_category_name                                                as product_category_name_pt,
        p.product_photos_qty,
        p.product_weight_g,
        p.product_length_cm,
        p.product_height_cm,
        p.product_width_cm
    from products as p
    left join translation as t
        on p.product_category_name = t.product_category_name
)

select * from final