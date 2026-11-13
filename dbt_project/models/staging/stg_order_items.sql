with source as (
    select * from {{ source('olist_raw', 'order_items') }}
),

renamed as (
    select
        {{ dbt_utils.generate_surrogate_key(['order_id', 'order_item_id']) }} as order_item_sk,
        order_id,
        try_to_number(order_item_id)                    as order_item_number,
        product_id,
        seller_id,
        try_to_timestamp_ntz(shipping_limit_date)       as shipping_limit_at,
        try_to_number(price, 10, 2)                     as price,
        try_to_number(freight_value, 10, 2)             as freight_value,
        _source_file                                    as _source,
        _loaded_at
    from source
    where order_id is not null
),

deduplicated as (
    select *
    from renamed
    qualify row_number() over (partition by order_item_sk order by _loaded_at desc) = 1
)

select * from deduplicated