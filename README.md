# Olist E-Commerce Database & Analytics Project

**Author:** ADEEB MUZAFFAR  
**Date:** 05-Sep-2026  
**Version:** 1.0  
**Status:** Ready for Analytical Use

---

## 📊 Project Overview

This project uses the **Olist Brazilian E-Commerce Public Dataset** to build a PostgreSQL database and answer 15 practical business questions.

The work is split into three main phases:

1. **Database Setup** — create a relational schema for the nine source tables, define keys and relationships, and add indexes.
2. **Data Validation** — check data types, duplicates, NULL values, referential integrity, domain/range rules, categorical values, and date/business rules.
3. **Business Analysis** — use SQL to analyze sales, customers, products, payments, delivery performance, reviews, and seller performance.

The aim is to keep the analysis simple and traceable: **set up the data → validate it → answer the business questions**.

---

## 📁 Project Structure

```text
olist-ecommerce-analytics/
│
├── 01_setup.sql
├── 02_validation.sql
├── 03_business_analysis.sql
├── 04_data_quality_report.md
└── README.md
```

### File Purpose

| File | Purpose |
|---|---|
| `01_setup.sql` | Creates the nine-table PostgreSQL schema, relationships, constraints, indexes, and initial row-count verification |
| `02_validation.sql` | Runs data-quality and integrity checks across the database |
| `03_business_analysis.sql` | Contains the 15 business-analysis questions and their SQL queries |
| `04_data_quality_report.md` | Documents validation findings, flagged issues, treatment decisions, and analytical-use approval |
| `README.md` | Project overview and instructions |

---

## 📈 Dataset Overview

### Source

**Olist Brazilian E-Commerce Public Dataset**

The dataset brings together customer, order, product, seller, payment, review, geolocation, and product-category information.

### Source Tables

The PostgreSQL database contains these 9 tables:

1. `customers`
2. `orders`
3. `order_items`
4. `products`
5. `sellers`
6. `order_payments`
7. `order_reviews`
8. `geolocation`
9. `product_category_name_translation`

The source data contains roughly **100K orders** and about **1M geolocation records**.

---

## ❓ 15 Business Questions

### Sales Performance

**Q1. Monthly Sales Trend & MoM Growth**  
Track monthly delivered product revenue, order volume, and month-over-month revenue growth.

**Q2. Average Order Value (AOV) & Freight Cost**  
Measure order-level average order value, average freight cost, and overall freight burden.

**Q3. Order Fulfillment Pipeline & Revenue Leakage (GMV at Risk)**  
Compare order statuses and estimate potential product revenue at risk from canceled and unavailable orders.

### Customer & Geographic Analysis

**Q4. State-wise Revenue & Order Ranking**  
Compare delivered revenue, order volume, unique customers, AOV, and state-level revenue ranking.

**Q5. Top Customer Cities**  
Compare customer cities using delivered orders, unique customers, revenue, and AOV.

**Q6. Repeat Customer Rate**  
Measure the share of unique customers who made more than one delivered purchase.

### Product & Category Analysis

**Q7. Top & Bottom Product Categories Performance**  
Identify the highest- and lowest-performing product categories by delivered product revenue.

**Q8. Freight-to-Price Impact by Category**  
Evaluate freight cost relative to product revenue across categories and rank categories by freight burden.

**Q9. Basket Size & Revenue Contribution**  
Analyze how different basket sizes contribute to delivered order volume, items sold, and product revenue.

### Payment & Finance

**Q10. Payment Method Distribution**  
Compare payment methods by order count, payment records, payment value, and payment-value share.

**Q11. Credit Card Installment Behavior**  
Analyze credit-card installment patterns, order share, payment-value share, and average transaction size.

**Q12. Voucher Payment Impact**  
Compare voucher-used and non-voucher orders using order value, basket size, and voucher value.

### Operations & Seller Performance

**Q13. Delivery Latency & SLA Gap**  
Compare actual delivery time with estimated delivery time and classify delivered orders as early, on-time, or late.

**Q14. Delivery Performance vs Review Score**  
Compare delivery performance with customer review scores for delivered orders.

**Q15. Seller Pareto Analysis (80/20 Rule)**  
Segment sellers into the top 20% and bottom 80% using revenue-based quintiles and compare their revenue contribution.

---

## 🔍 Data Quality Summary

Before starting the business analysis, I ran a separate validation step to understand the quality and consistency of the data.

The validation covered:

- Data types and schema structure
- Duplicate and key behavior
- NULL values
- Referential integrity
- Domain and range checks
- Order/payment categorical values
- Date and business-rule consistency

### Main Findings

| Area | Result |
|---|---|
| Data types | **PASS** |
| Main key/composite-key checks | **PASS** |
| `review_id` uniqueness | **FLAG** |
| Geolocation exact duplicates | **FLAG** |
| NULL values | **REVIEWED** |
| Referential integrity | **PASS** |
| Domain/range checks | **PASS** |
| Order/payment categorical values | **PASS** |
| Date/business rules | **FLAG** |

The main findings included **262,010 extra exact duplicate geolocation rows**, repeated `review_id` values, expected NULLs in optional or status-dependent fields, and a small number of timestamp/business-rule inconsistencies.

I kept the raw source data unchanged. Flagged records were documented rather than silently removed or corrected. Where needed, the analysis uses appropriate filters, aggregation, or review-level handling so these issues do not distort the results.

For the complete findings and treatment decisions, see:

`04_data_quality_report.md`

---

## 🚀 How to Run

### Prerequisites

- PostgreSQL
- A SQL client such as **DBeaver** or **pgAdmin**
- The Olist CSV dataset
- Permission to create tables and indexes in the target database

The SQL uses PostgreSQL-specific features such as `generate_series()`, `DATE_TRUNC()`, PostgreSQL casting, and window functions, so it should be run in PostgreSQL.

### Execution Order

Run the files in this order:

```text
01_setup.sql
      ↓
02_validation.sql
      ↓
03_business_analysis.sql
```

The data-quality report is documentation rather than an SQL execution step:

```text
04_data_quality_report.md
```

### Step 1 — Database Setup

Run `01_setup.sql`.

It:

- Drops existing project tables so the schema can be recreated cleanly
- Creates 9 tables
- Defines primary/composite keys
- Defines foreign-key relationships
- Adds appropriate CHECK constraints
- Creates 15 indexes
- Runs row-count verification queries

### Step 2 — Data Validation

Run `02_validation.sql`.

It checks:

- Data types
- Duplicates
- NULL values
- Referential integrity
- Domain/range validity
- Date/business rules
- Status and payment categories

Review the results together with `04_data_quality_report.md`.

### Step 3 — Business Analysis

Run `03_business_analysis.sql`.

It contains all 15 business questions, from monthly sales performance through seller Pareto analysis.

---

## 📊 Expected Results

The business-analysis results come directly from the data loaded into PostgreSQL, so I have not added fixed KPI values here that could become out of sync with the database.

After setup, you should have the 9 project tables available.

After validation, you should see PASS results for the core structural and relational checks, along with the documented data-quality flags.

After business analysis, you should receive **15 result sets**, one for each business question.

---

## 🛠️ Technical Stack

| Component | Technology |
|---|---|
| Database | PostgreSQL |
| Language | SQL |
| SQL Techniques | CTEs, JOINs, aggregations, CASE, subqueries, window functions |
| Database Design | Primary keys, composite keys, foreign keys, CHECK constraints |
| Performance | 15 indexes |
| Documentation | Markdown |
| Version Control | Git / GitHub |

---

## 🧱 Database Design

The setup script creates nine related tables covering the main entities and transaction-level data.

Key relationships include:

- Customers → Orders
- Orders → Order Items
- Products → Order Items
- Sellers → Order Items
- Orders → Payments
- Orders → Reviews

The design also uses composite keys where the source data requires them, such as:

- `order_items (order_id, order_item_id)`
- `order_payments (order_id, payment_sequential)`

This keeps the transactional structure explicit while allowing the business analysis to join the tables by their actual relationships.

---

## 📋 How I Handled the Data

A major part of the project was deciding how to handle imperfect real-world data.

The approach was:

- **Preserve the raw source data**
- Do not silently delete duplicate records
- Do not automatically fill NULL values
- Flag business-rule inconsistencies
- Use question-specific filters where complete timestamps are required
- Aggregate one-to-many tables where necessary to avoid metric multiplication
- Document important limitations in the data-quality report

The point of validation was not to make the dataset look perfect. It was to understand its limitations before using it for analysis.

---

## 🎯 What I Worked On

### Database Design

- Relational schema design
- Primary and composite keys
- Foreign-key relationships
- Constraints
- Strategic indexing

### Data Quality

- Systematic validation
- Duplicate investigation
- NULL analysis
- Referential-integrity testing
- Domain and range validation
- Date/business-rule validation
- Non-destructive data handling

### SQL Analysis

- CTEs
- Multi-table JOINs
- Aggregations
- CASE statements
- Subqueries
- Window functions such as `LAG()`, `DENSE_RANK()`, and `NTILE()`
- Business-oriented KPI calculations

### Business Thinking

The analysis focuses on practical marketplace questions rather than standalone SQL exercises, covering revenue trends, customer behavior, freight burden, payments, delivery performance, customer satisfaction, and seller concentration.

---

## 📄 Detailed Documentation

For the full validation findings, flagged records, risk considerations, remediation decisions, and analytical-use approval:

**`04_data_quality_report.md`**

The report contains the detailed validation work, while this README keeps the summary brief.

---

## 📌 Project Status

| Phase | File | Status |
|---|---|---|
| Database Setup | `01_setup.sql` | ✅ Complete |
| Data Validation | `02_validation.sql` | ✅ Complete |
| Business Analysis | `03_business_analysis.sql` | ✅ Complete |
| Data Quality Report | `04_data_quality_report.md` | ✅ Complete |
| Project Documentation | `README.md` | ✅ Complete |

**Overall Status: Ready for Analytical Use / Portfolio**

---

## 📚 Dataset

This project uses the Olist Brazilian E-Commerce Public Dataset.

Dataset source:  
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

---

## 👤 Author

**ADEEB MUZAFFAR**

- **GitHub:** https://github.com/adduu2003
- **LeetCode:** https://leetcode.com/u/adduu_2003/

Project date: **05-Sep-2026**

---

## License

This project analyzes the Olist Brazilian E-Commerce Public Dataset. Refer to the original dataset source for its licensing and usage terms.
