with source as (
    select * from {{ source('olist_raw', 'product_category_translation') }}
),

renamed as (
    select
        lower(trim(product_category_name))            as product_category_name,
        lower(trim(product_category_name_english))    as product_category_name_english,
        _source_file                                  as _source,
        _loaded_at
    from source
    where product_category_name is not null
),

deduplicated as (
    select *
    from renamed
    qualify row_number() over (partition by product_category_name order by _loaded_at desc) = 1
)

select * from deduplicated