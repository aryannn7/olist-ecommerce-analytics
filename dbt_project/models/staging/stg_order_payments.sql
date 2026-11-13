with source as (
    select * from {{ source('olist_raw', 'order_payments') }}
),

renamed as (
    select
        {{ dbt_utils.generate_surrogate_key(['order_id', 'payment_sequential']) }} as payment_sk,
        order_id,
        try_to_number(payment_sequential)       as payment_sequence,
        lower(trim(payment_type))               as payment_type,
        try_to_number(payment_installments)     as payment_installments,
        try_to_number(payment_value, 10, 2)     as payment_value,
        _source_file                            as _source,
        _loaded_at
    from source
    where order_id is not null
),

deduplicated as (
    select *
    from renamed
    qualify row_number() over (partition by payment_sk order by _loaded_at desc) = 1
)

select * from deduplicated