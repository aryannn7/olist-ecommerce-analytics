with source as (
    select * from {{ source('olist_raw', 'customers') }}
),

renamed as (
    select
        customer_id,
        customer_unique_id,
        lpad(customer_zip_code_prefix, 5, '0')   as customer_zip_code_prefix,
        lower(trim(customer_city))               as customer_city,
        upper(trim(customer_state))              as customer_state,
        _source_file                             as _source,
        _loaded_at
    from source
    where customer_id is not null
),

deduplicated as (
    select *
    from renamed
    qualify row_number() over (partition by customer_id order by _loaded_at desc) = 1
)

select * from deduplicated