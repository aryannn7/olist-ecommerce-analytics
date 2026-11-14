-- analytics_queries.sql
-- Analytics queries against the marts layer (OLIST.MARTS).
-- Run in a Snowsight worksheet with role TRANSFORMER and warehouse TRANSFORM_WH.

USE ROLE TRANSFORMER;
USE WAREHOUSE TRANSFORM_WH;

-- =====================================================================
-- Q1. Top 10 product categories by revenue (delivered orders only)
-- =====================================================================
select
    p.product_category,
    count(distinct f.order_id)     as orders,
    round(sum(f.price), 0)         as revenue_brl,
    round(avg(f.price), 2)         as avg_item_price_brl
from OLIST.MARTS.FCT_ORDER_ITEMS as f
inner join OLIST.MARTS.DIM_PRODUCTS as p
    on f.product_sk = p.product_sk
where f.order_status = 'delivered'
group by p.product_category
order by revenue_brl desc
limit 10;

-- =====================================================================
-- Q2. Monthly trend: orders, revenue and average order value
-- Note: the first months (2016) and the last months (Sep-Oct 2018) are incomplete in the source data.
-- =====================================================================
select
    date_trunc('month', f.order_date)                          as order_month,
    count(distinct f.order_id)                                 as orders,
    round(sum(f.price), 0)                                     as revenue_brl,
    round(sum(f.price) / count(distinct f.order_id), 2)        as avg_order_value_brl
from OLIST.MARTS.FCT_ORDER_ITEMS as f
where f.order_status not in ('canceled', 'unavailable')
group by order_month
order by order_month;

-- =====================================================================
-- Q3. Delivery performance vs review score (one row per delivered, reviewed order)
-- =====================================================================
with delivered_orders as (
    select
        order_id,
        max(days_late)      as days_late,
        max(review_score)   as review_score
    from OLIST.MARTS.FCT_ORDER_ITEMS
    where order_status = 'delivered'
      and delivered_to_customer_at is not null
      and review_score is not null
    group by order_id
)

select
    case
        when days_late <= 0 then '1. On time or early'
        when days_late <= 3 then '2. 1-3 days late'
        when days_late <= 7 then '3. 4-7 days late'
        else '4. 8+ days late'
    end                                                        as delivery_bucket,
    count(*)                                                   as orders,
    round(count(*) * 100 / sum(count(*)) over (), 1)           as pct_of_orders,
    round(avg(review_score), 2)                                as avg_review_score,
    round(avg(iff(review_score <= 2, 1, 0)) * 100, 1)          as pct_1_or_2_star
from delivered_orders
group by delivery_bucket
order by delivery_bucket;

-- =====================================================================
-- Q4. Top 10 customer states: volume, revenue and delivery performance
-- =====================================================================
with state_orders as (
    select
        f.order_id,
        c.customer_state,
        sum(f.price)                    as order_revenue,
        max(iff(f.is_late, 1, 0))       as is_late,
        max(f.delivery_days)            as delivery_days
    from OLIST.MARTS.FCT_ORDER_ITEMS as f
    inner join OLIST.MARTS.DIM_CUSTOMERS as c
        on f.customer_sk = c.customer_sk
    where f.order_status = 'delivered'
      and f.delivered_to_customer_at is not null
    group by f.order_id, c.customer_state
)

select
    customer_state,
    count(*)                           as orders,
    round(sum(order_revenue), 0)       as revenue_brl,
    round(avg(is_late) * 100, 1)       as pct_late,
    round(avg(delivery_days), 1)       as avg_delivery_days
from state_orders
group by customer_state
order by orders desc
limit 10;

-- =====================================================================
-- Q5. Stakeholder ask: "How many customers come back?"
-- =====================================================================
select
    count(*)                                               as customers,
    sum(iff(is_repeat_customer, 1, 0))                     as repeat_customers,
    round(avg(iff(is_repeat_customer, 1, 0)) * 100, 2)     as repeat_rate_pct,
    round(avg(lifetime_orders), 3)                         as avg_orders_per_customer
from OLIST.MARTS.DIM_CUSTOMERS;