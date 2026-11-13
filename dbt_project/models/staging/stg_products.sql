with source as (
    select * from {{ source('olist_raw', 'products') }}
),

renamed as (
    select
        product_id,
        lower(trim(product_category_name))               as product_category_name,
        try_to_number(product_name_lenght)               as product_name_length,
        try_to_number(product_description_lenght)        as product_description_length,
        try_to_number(product_photos_qty)                as product_photos_qty,
        try_to_number(product_weight_g)                  as product_weight_g,
        try_to_number(product_length_cm)                 as product_length_cm,
        try_to_number(product_height_cm)                 as product_height_cm,
        try_to_number(product_width_cm)                  as product_width_cm,
        _source_file                                     as _source,
        _loaded_at
    from source
    where product_id is not null
),

deduplicated as (
    select *
    from renamed
    qualify row_number() over (partition by product_id order by _loaded_at desc) = 1
)

select * from deduplicated