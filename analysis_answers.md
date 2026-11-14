# Part B: Analysis and commercial recommendation

All figures come from `sql/analytics_queries.sql`, run against the `OLIST.MARTS` star schema.
Revenue = item price in BRL (freight excluded). Delivery and review metrics are measured per order, not per item.

## B1. Commercial insights

### Insight 1: Late deliveries are the biggest driver of bad reviews, and they cluster in specific regions
**Finding.** 93.3% of delivered orders arrive on time and average 4.29★. Orders 1–3 days late fall to 3.29★, 4–7 days late to 2.10★, and 8+ days late to 1.70★. In total, 6,381 reviewed orders (6.7%) arrived late. Lateness is uneven: 12.1% of orders in Rio de Janeiro (RJ) and 12.2% in Bahia (BA) are late, against 4.5% in São Paulo (SP).
**Method.** Each delivered, reviewed order was bucketed by days late versus the delivery date promised at checkout (Q3), then compared with its review score. Lateness rates were split by customer state (Q4).
**Why it matters.** Reviews are what new customers see. Late orders are a small share of volume but a large share of 1–2★ ratings, and they're concentrated enough to act on (two states, one promise date).

### Insight 2: Customers almost never buy twice
**Finding.** Of 96,096 real customers, only 2,997 (3.12%) placed more than one order; the average is 1.035 orders per customer.
**Method.** Customers were identified by `customer_unique_id` (Olist issues a new `customer_id` per order) and their lifetime orders counted in `dim_customers` (Q5).
**Why it matters.** Almost all revenue depends on finding new customers. Even a small lift in repeat purchase is cheap growth, and customers who had a bad experience are the most at risk of never returning.

## B2. Recommendation: late-delivery recovery campaign

**Target segment.** Customers whose order arrived after the promised date (`fct_order_items.is_late = TRUE`), identified automatically on delivery. On historical volume that's about 6,381 orders over ~20 months, roughly **320 customers a month**, weighted towards RJ and BA.

**Mechanic.** On the day a late order is delivered, send an automated apology email with a **10% voucher on the next order, valid for 60 days**. It goes out before the review request, so the customer hears from Olist before they rate.

**Expected impact (rough, assumptions stated).**
| Assumption | Value |
|---|---|
| Late orders per year | ~3,830 (6,381 × 12/20) |
| Baseline repeat rate | ~3% (Q5) |
| Repeat rate with voucher | ~8% (+5 percentage points) |
| Average order value | ~BRL 140 (Q2, 2017 monthly AOV range BRL 125–155) |

- Extra orders: 3,830 × 5% ≈ **190 per year → ≈ BRL 27k extra revenue**
- Voucher cost: 10% on ≈ 305 redeemed orders (190 new + ≈ 115 who would have returned anyway) ≈ **BRL 4k**
- **Net ≈ BRL 22k per year**. Sensitivity: +2pp lift ≈ BRL 11k, +10pp ≈ BRL 54k gross.

This is a modest, low-risk direct return. The larger value is protecting review scores, and the test tells us how much late customers are worth winning back, which sizes the bigger fix (more realistic delivery promises and carrier changes in RJ and BA).

**Measurement.**
- **Design:** randomised holdout. Half of late customers get the voucher, half get nothing (control).
- **Primary metric:** repeat-purchase rate within 60 days, treatment vs control.
- **Leading indicators (2–4 weeks):** voucher redemption rate, and average review score of treated vs control orders.
- **Sample size:** detecting 3% → 8% at 95% confidence and 80% power needs ~320 customers per group, about **2 months of