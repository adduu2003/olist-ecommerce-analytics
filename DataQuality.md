# Olist E-Commerce Analytics


## Data Quality & Validation Report

**Project:** Olist E-Commerce Marketplace Analytics  
**Purpose:** Record the checks performed on the data, the issues found, and how those issues were handled before business analysis.

---

## 1. Overview

The Olist dataset was loaded into a relational PostgreSQL database containing nine source tables:

- `customers`
- `orders`
- `order_items`
- `products`
- `sellers`
- `order_payments`
- `order_reviews`
- `geolocation`
- `product_category_name_translation`

Before starting the business analysis, I ran a separate validation step to check:

- data types and schema structure
- duplicate and key behavior
- NULL values
- referential integrity
- domain and range validity
- date and business-rule consistency
- categorical/status values

The raw source data is **preserved**. When an issue was found, it was documented and flagged instead of being automatically deleted, corrected, or filled in.

---

# 2. Validation Summary

| Validation Area | Result | Summary |
|---|---|---|
| Data types | PASS | Declared data types and numeric precision/scale matched the project schema |
| Primary/key uniqueness | PASS | Main entity keys and composite transactional keys behaved as expected |
| Review ID uniqueness | FLAG | `review_id` is duplicated and therefore is not treated as a unique key |
| Geolocation exact duplicates | FLAG | 262,010 extra duplicate rows identified |
| NULL values | REVIEWED | NULLs occur in expected optional/status-dependent fields and are preserved |
| Referential integrity | PASS | All six tested relationships returned zero orphan records |
| Domain/range checks | PASS | Tested numeric ranges and coordinate/review-score domains were valid |
| Order/payment categorical values | PASS | Observed values matched the expected domain |
| Date/business rules | FLAG | A small number of temporal inconsistencies were identified |

---

# 3. Detailed Data Quality Flags

## Flag 1 — Duplicate `review_id`

### Finding
The `order_reviews` table contains duplicate values of `review_id`.

The duplicate investigation showed that a `review_id` cannot safely be treated as a unique identifier in the imported raw data.

### Why it matters
If `review_id` were incorrectly treated as a primary key or unique identifier, valid source rows could be rejected or lost during loading.

Duplicate review rows can also create **row multiplication** when reviews are joined directly to other one-to-many tables.

### How it is handled
- `review_id` is **not** treated as a primary key.
- The raw review records are preserved.
- Review-level analysis will use appropriate aggregation at the order level where necessary.
- Direct joins that could multiply business metrics will be avoided.

### Status
**FLAG — documented and accounted for; no deletion performed.**

---

## Flag 2 — Exact Duplicate Rows in `geolocation`

### Finding
The `geolocation` table contains repeated rows with exactly the same:

- `geolocation_zip_code_prefix`
- `geolocation_lat`
- `geolocation_lng`
- `geolocation_city`
- `geolocation_state`

The validation identified:

**262,010 extra duplicate rows.**

### Why it matters
The `geolocation` table is naturally capable of containing multiple records for the same ZIP-code prefix. However, exact duplicate records provide no additional information.

If this table is joined directly to other tables without controlling for duplicates, it can multiply rows and distort counts, revenue, or other aggregations.

### How it is handled
- Duplicate rows are **not deleted from the raw dataset**.
- The issue is documented.
- Geolocation will only be used in analysis when the join logic prevents duplicate-row multiplication.
- If a deduplicated geolocation lookup is required later, it will be created as an analytical step rather than altering the raw table.

### Status
**FLAG — documented; raw data preserved.**

---

# 4. NULL Value Findings

NULL values were reviewed table by table.

## `products`

NULLs were found in:

- `product_category_name` — 610
- `product_name_length` — 610
- `product_description_length` — 610
- `product_photos_qty` — 610
- `product_weight_g` — 2
- `product_length_cm` — 2
- `product_height_cm` — 2
- `product_width_cm` — 2

### How it is handled
These values are preserved. They will only be handled when a particular business analysis requires the corresponding field.

---

## `orders`

NULLs were found in:

- `order_approved_at` — 160
- `order_delivered_carrier_date` — 1,783
- `order_delivered_customer_date` — 2,965

### How it is handled
These are not automatically considered errors because timestamp availability can depend on the order's lifecycle/status.

For delivery-related analysis, the relevant non-NULL timestamps will be used according to the business question.

---

## `order_reviews`

NULLs were found in optional review-content/timestamp fields:

- `review_comment_title` — 87,656
- `review_comment_message` — 58,247
- `review_answer_timestamp` — 876

### How it is handled
These are treated as missing optional information rather than automatically invalid records. No text or timestamp values are imputed.

---

# 5. Referential Integrity

The following relationships were tested:

1. `orders.customer_id` → `customers.customer_id`
2. `order_items.order_id` → `orders.order_id`
3. `order_items.product_id` → `products.product_id`
4. `order_items.seller_id` → `sellers.seller_id`
5. `order_payments.order_id` → `orders.order_id`
6. `order_reviews.order_id` → `orders.order_id`

### Result

All six checks returned **0 orphan records**.

### Status
**PASS — relational integrity is intact for the tested relationships.**

---

# 6. Domain & Range Validation

The following checks passed:

- Product physical dimensions/weight: no negative values
- Product text/photo attributes: no negative values
- Review score: all values within 1–5
- Payment installments: no negative values
- Payment value: no negative values
- Item price: no negative values
- Freight value: no negative values
- Geolocation latitude: valid range
- Geolocation longitude: valid range
- Order status: values matched the expected domain
- Payment type: values matched the expected domain

### Important raw-data observations

`order_payments` contains some records with:

- `payment_value = 0.00`
- `payment_installments = 0`

These were **not treated as negative/invalid values**, and the raw data was preserved.

The analysis will account for such records where the specific business question makes them relevant.

---

# 7. Date & Business-Rule Flags

Several temporal consistency checks were performed.

## Flag 3 — Carrier Date vs Purchase/Approval Date

Some records contain delivery-carrier timestamps that are inconsistent with the expected chronological sequence relative to purchase and/or approval.

The exact flagged counts are retained in the validation results and are not being hard-coded here until the final documentation pass.

### How it is handled
These records are documented as source-data inconsistencies. They will not be manually corrected.

For delivery analysis, the relevant date logic will be explicitly defined and invalid/incomplete records will be handled according to the business question.

### Status
**FLAG**

---

## Flag 4 — Customer Delivery Before Carrier Handover

**23 orders** have a customer delivery timestamp earlier than the recorded carrier handover timestamp.

### Why it matters
This violates the expected operational sequence:

`Purchase → Carrier Handover → Customer Delivery`

### How it is handled
These records are not manually corrected. Delivery-latency analysis will use appropriate date-quality filters.

### Status
**FLAG**

---

## Flag 5 — Delivered Orders Missing Customer Delivery Date

**8 delivered orders** have a NULL `order_delivered_customer_date`.

### Why it matters
A delivered order would normally be expected to have a customer delivery timestamp.

### How it is handled
These orders will be excluded from calculations that specifically require actual delivery time.

### Status
**FLAG**

---

## Flag 6 — Non-Delivered Orders With Customer Delivery Date

**6 non-delivered orders** have a customer delivery timestamp.

### Why it matters
This creates a conflict between the recorded order status and delivery timestamp.

### How it is handled
The records are preserved. Analyses that depend on completed delivery will rely on both status and required timestamps.

### Status
**FLAG**

---

## Flag 7 — Customer Delivery Date Without Carrier Date

**1 order** has a customer delivery timestamp while the carrier handover timestamp is NULL.

### Why it matters
This makes carrier-to-customer delivery latency impossible to calculate reliably.

### How it is handled
The order will be excluded from analyses requiring the carrier handover date.

### Status
**FLAG**

---

## Flag 8 — Delivered Orders Missing Approval Date

**14 delivered orders** have a NULL `order_approved_at`.

### Why it matters
The approval timestamp is part of the normal order lifecycle and is useful for operational timing analysis.

### How it is handled
The raw records are preserved. Analyses requiring approval time will exclude records where the required timestamp is unavailable.

### Status
**FLAG**

---

## Flag 9 — Canceled Orders With Customer Delivery Date

**6 canceled orders** contain a customer delivery timestamp.

### Why it matters
The combination is inconsistent with the expected final order state and should be treated carefully in business analysis.

### How it is handled
These records are flagged but not deleted or manually corrected.

### Status
**FLAG**

---

# 8. What Passed Cleanly

The following areas did not produce material data-quality problems in validation:

- Main entity identifiers were unique where expected.
- `order_items` composite key `(order_id, order_item_id)` was unique.
- `order_payments` composite key `(order_id, payment_sequential)` was unique.
- Product-category translation key was unique.
- Tested foreign-key relationships had zero orphan records.
- Review scores stayed within 1–5.
- Tested monetary fields had no negative values.
- Product physical measurements had no negative values.
- Geolocation coordinates were within valid geographic ranges.
- Expected order-status values were valid.
- Expected payment-type values were valid.

---

# 9. Analytical Handling Principles

The purpose of validation is **not** to make the raw dataset look perfect. The raw source should remain traceable.

For the business-analysis stage:

1. **Do not delete flagged source records.**
2. **Do not silently impute missing values.**
3. Use business-question-specific filters when a metric requires complete data.
4. Aggregate one-to-many tables before joining when necessary to prevent metric multiplication.
5. Clearly distinguish between:
   - raw-data anomalies,
   - expected NULLs,
   - and genuine business-rule inconsistencies.
6. Document any analytical exclusions in the relevant SQL/Python analysis.

---

# 10. Final Data Quality Assessment

The dataset is **suitable for business analysis**, as long as the documented flags are handled appropriately.

The major issues are concentrated around:

- duplicate review identifiers,
- repeated geolocation records,
- missing optional/status-dependent timestamps,
- and a limited number of date/business-rule inconsistencies.

The core relational structure is sound: the tested relationships contain **no orphan records**, and the main numeric and domain checks passed.

Based on these checks, the project can move to the **Business Analysis** stage without changing the raw source data.

---

## Next Stage

**SQL Business Analysis → Q1: Monthly Sales Trend & MoM Growth**

These findings should stay with the SQL project and be considered whenever a business metric uses one of the affected fields.
