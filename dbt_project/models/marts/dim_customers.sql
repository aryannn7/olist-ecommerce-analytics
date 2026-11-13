with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

-- link every order to the real person behind it
customer_orders as (
    select
        c.customer_unique_id,
        c.customer_zip_code_prefix,
        c.customer_city,
        c.customer_state,
        o.order_id,
        o.purchased_at
    from customers as c
    inner join orders as o
        on c.customer_id = o.customer_id
),

-- a person can order from different addresses: keep the most recent one
latest_location as (
    select
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state
    from customer_orders
    qualify row_number() over (partition by customer_unique_id order by purchased_at desc) = 1
),

order_summary as (
    select
        customer_unique_id,
        min(purchased_at)         as first_order_at,
        max(purchased_at)         as last_order_at,
        count(distinct order_id)  as lifetime_orders
    from customer_orders
    group by customer_unique_id
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['l.customer_unique_id']) }} as customer_sk,
        l.customer_unique_id,
        l.customer_city,
        l.customer_state,
        l.customer_zip_code_prefix,
        s.first_order_at,
        s.last_order_at,
        s.lifetime_orders,
        s.lifetime_orders > 1 as is_repeat_customer
    from latest_location as l
    inner join order_summary as s
        on l.customer_unique_id = s.customer_unique_id
)

select * from final