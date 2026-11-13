with source as (
    select * from {{ source('olist_raw', 'order_reviews') }}
),

renamed as (
    select
        review_id,
        order_id,
        try_to_number(review_score)                      as review_score,
        review_comment_title,
        review_comment_message,
        try_to_timestamp_ntz(review_creation_date)       as review_created_at,
        try_to_timestamp_ntz(review_answer_timestamp)    as review_answered_at,
        _source_file                                     as _source,
        _loaded_at
    from source
    where order_id is not null
),

-- Grain: one review per order. Where an order has several reviews, keep the latest.
deduplicated as (
    select *
    from renamed
    qualify row_number() over (
        partition by order_id
        order by review_answered_at desc nulls last, review_created_at desc
    ) = 1
)

select * from deduplicated