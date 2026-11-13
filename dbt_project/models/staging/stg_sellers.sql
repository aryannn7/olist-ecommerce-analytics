with source as (
    select * from {{ source('olist_raw', 'sellers') }}
),

renamed as (
    select
        seller_id,
        lpad(seller_zip_code_prefix, 5, '0')   as seller_zip_code_prefix,
        lower(trim(seller_city))               as seller_city,
        upper(trim(seller_state))              as seller_state,
        _source_file                           as _source,
        _loaded_at
    from source
    where seller_id is not null
),

deduplicated as (
    select *
    from renamed
    qualify row_number() over (partition by seller_id order by _loaded_at desc) = 1
)

select * from deduplicated