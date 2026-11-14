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
- **Sample size:** detecting 3% → 8% at 95% confidence and 80% power needs ~320 customers per group, about **2 months of late orders**. First read on reviews at **4 weeks**, decision on repeat purchase at **~12 weeks**.
- **Success:** a statistically clear lift in 60-day repeat rate with net revenue above voucher cost.

## B3. Assumptions, caveats and data quality

**Assumptions and limitations I'd flag to a client**
- **Correlation, not causation.** Late orders get worse reviews, but product type or seller may also play a part. The holdout test is what proves impact.
- **Review grain.** The source has 814 duplicate `review_id`s; I kept one review per order (latest). Review score is order-level, so all review analysis is done per order, not per item.
- **"Late"** is measured against Olist's promised date, at day level; undelivered orders are excluded rather than counted as late.
- **Incomplete edges.** 2016 and Sep–Oct 2018 are partial months, so trends exclude them from conclusions.
- **Location** is the customer's most recent address; revenue is item price in BRL, excluding freight; no inflation adjustment.
- **Impact estimate** is directional: the 5pp lift is an assumption to be tested, not a forecast.

**Top 3 production data quality checks**
1. **Source freshness:** `dbt source freshness` on `_loaded_at`, warning if raw tables haven't loaded within the expected window.
2. **Volume and reconciliation:** row counts per load compared with the previous load (alert on large swings), and `fct_order_items` rows = `stg_order_items` rows, so no items are lost or duplicated by joins.
3. **Key integrity:** the existing `unique` / `not_null` / `relationships` tests on every key, plus `accepted_values` on statuses and review scores, run in CI on every pull request and failing the build.

## B4. Client memo

**To:** CFO / COO, Olist
**Subject:** Late deliveries are costing reviews and repeat customers. A low-cost test to win them back

We've built a reliable data pipeline for your order data: raw files load automatically into Snowflake, and are cleaned, tested (43 automated checks) and modelled in dbt into simple tables for reporting. Every number below can be traced and re-run.

Two findings stand out. First, late deliveries drive bad reviews: on-time orders average 4.3★, but orders more than a week late average 1.7★. Rio de Janeiro and Bahia have nearly three times São Paulo's late rate. Second, only 3% of customers ever buy again, so growth depends almost entirely on acquiring new customers.

**Recommended next step:** a 12-week controlled test. Customers whose order arrives late get an apology and a 10% voucher; a matched group gets nothing. We estimate about BRL 22k net a year from repeat orders, and the test will show what fixing delivery in the worst regions is worth.

Decision needed: approval to run the test, plus access to email/CRM to send the vouchers.

## B5. LLM use case (bonus)

**Use case:** classify review comments (Portuguese free text) into complaint themes with Snowflake Cortex, so operations can see *why* customers are unhappy, not just the score.
- **Example prompt:** "Classify this Brazilian Portuguese review into one of: late delivery, wrong/missing item, damaged product, product quality, seller communication, positive, other. Return only the label."
- **Data retrieved:** `review_comment_message`, `review_score`, `is_late`, `customer_state` for 1–3★ orders.
- **Output:** one label per review, stored as a column, e.g. `complaint_theme`, so you can chart "% of bad reviews mentioning late delivery, by state".
- **Main risk:** misclassification (hallucinated or inconsistent labels), plus customer text possibly containing personal data.
- **Mitigation:** a fixed label list (no free text), human-check a random 200-review sample before trusting it, keep the prompt versioned in git, run it incrementally on new reviews only to control cost, and mask names and emails before sending text to the model.