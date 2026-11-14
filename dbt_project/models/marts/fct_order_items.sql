with items as (
    select * from {{ ref('stg_order_items') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

reviews as (
    select * from {{ ref('stg_order_reviews') }}
),

final as (
    select
        -- keys
        i.order_item_sk,
        i.order_id,
        i.order_item_number,
        {{ dbt_utils.generate_surrogate_key(['c.customer_unique_id']) }}  as customer_sk,
        {{ dbt_utils.generate_surrogate_key(['i.product_id']) }}          as product_sk,
        i.seller_id,

        -- order context
        o.order_status,
        o.purchased_at,
        to_date(o.purchased_at)                                            as order_date,
        o.delivered_to_customer_at,
        o.estimated_delivery_at,

        -- money
        i.price,
        i.freight_value,
        i.price + i.freight_value                                          as item_total,

        -- delivery performance
        datediff('day', o.purchased_at, o.delivered_to_customer_at)        as delivery_days,
        datediff('day', o.estimated_delivery_at, o.delivered_to_customer_at) as days_late,
        case
            when o.delivered_to_customer_at is null then null
            when to_date(o.delivered_to_customer_at) > to_date(o.estimated_delivery_at) then true
            else false
        end                                                                as is_late,

        -- customer experience (order-level, repeated on each item of the order)
        r.review_score
    from items as i
    inner join orders as o
        on i.order_id = o.order_id
    inner join customers as c
        on o.customer_id = c.customer_id
    left join reviews as r
        on i.order_id = r.order_id
)

select * from final