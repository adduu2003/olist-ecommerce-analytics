# Olist E-Commerce Database & Analytics Project

**Author:** ADEEB MUZAFFAR  
**Date:** 08-Sep-2026  
**Version:** 1.1  
**Status:** SQL & Python Complete | Power BI In Progress

---

## 📊 Project Overview

This project uses the **Olist Brazilian E-Commerce Public Dataset** to build a PostgreSQL database and analyze e-commerce performance from both a data and business perspective.

The project is being completed in three main phases:

1. **SQL** — database setup, data validation, and business analysis.
2. **Python** — data preparation, validation, exploratory analysis, business analysis, and visualizations.
3. **Power BI** — dashboard development and final presentation of the analysis.

The workflow follows a simple structure:

**Prepare the data → Validate it → Analyze it → Visualize it → Build the final dashboard**

The final business insights and recommendations will be added after the Power BI phase is complete.

---

## 📁 Project Structure

```text
olist-ecommerce-analytics/
│
├── 01_setup.sql
├── 02_validation.sql
├── 03_business_analysis.sql
├── 04_data_quality_report.md
│
├── 01_data_preparation_EDA.ipynb
├── 02_business_analysis.ipynb
│
├── power_bi/
│   └── olist_ecommerce_dashboard.pbix
│
└── README.md
```

### File Purpose

| File | Purpose |
|---|---|
| `01_setup.sql` | Creates the nine-table PostgreSQL schema, relationships, constraints, indexes, and initial checks |
| `02_validation.sql` | Runs data-quality, integrity, and business-rule checks |
| `03_business_analysis.sql` | Contains the SQL business-analysis questions and queries |
| `04_data_quality_report.md` | Documents the SQL validation findings and treatment decisions |
| `01_data_preparation_EDA.ipynb` | Loads, prepares, validates, and explores the Olist datasets in Python |
| `02_business_analysis.ipynb` | Performs business analysis and visualizations in Python |
| `power_bi/olist_ecommerce_dashboard.pbix` | Final Power BI dashboard — pending |
| `README.md` | Project overview, workflow, analysis scope, and project status |

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

## ❓ SQL Business Questions

The SQL phase covers 15 practical business questions across sales, customers, products, payments, operations, and seller performance.

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

## 🐍 Python Analysis

The Python phase is now complete and is organized into two notebooks.

### 01 — Data Preparation & EDA

The first notebook prepares the datasets and checks whether the data is suitable for analysis.

It covers:

- Loading all Olist datasets
- Dataset size and structure
- Column and data-type checks
- Descriptive statistics
- Missing-value checks
- Duplicate and key checks
- Date conversion and range checks
- Order timeline validation
- Negative and zero-value checks
- Review score validation
- Product dimension checks
- Payment range checks
- Blank-string checks
- Foreign-key validation

The goal is to understand the data clearly before starting the business analysis.

### 02 — Business Analysis

The second notebook contains four business-analysis modules.

#### Module 1 — RFM Analysis

- RFM calculation
- RFM scoring
- Customer segmentation
- Revenue contribution by customer segment
- Customer distribution by segment

#### Module 2 — Cohort Analysis

- Customer acquisition cohorts
- Customer retention analysis
- Retention heatmap
- Cohort average order value progression
- Selected-cohort visualization for clearer comparison

#### Module 3 — Logistics & SLA Deep-Dive

- Delivery gap calculation
- IQR-based outlier analysis
- Delivery gap distribution
- State-wise average delivery gap
- Delivery gap vs review score
- Correlation between delivery gap and review score

#### Module 4 — Pricing & Freight Analysis

- Product price vs freight correlation
- Freight burden vs cancellation rate
- Price tiers vs average freight value
- Visual comparison of pricing and freight patterns

The Python analysis focuses on understanding customer behavior, retention, delivery performance, pricing, freight costs, and their relationships using pandas, NumPy, Matplotlib, and Seaborn.

---

## 🔍 Data Quality Summary

Before the business analysis, the data was checked to understand its quality and consistency.

The validation covered:

- Data types and schema structure
- Duplicate and key behavior
- NULL values
- Referential integrity
- Domain and range checks
- Order and payment categories
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

The raw source data was kept unchanged. Flagged records were documented rather than silently removed or corrected.

For the complete findings and treatment decisions, see:

`04_data_quality_report.md`

---

## 🛠️ Technical Stack

| Component | Technology |
|---|---|
| Database | PostgreSQL |
| SQL | SQL |
| Python | Python |
| Data Analysis | pandas, NumPy |
| Visualization | Matplotlib, Seaborn |
| Dashboard | Power BI — In Progress |
| Documentation | Markdown |
| Version Control | Git / GitHub |

---

## 🧱 Database Design

The SQL setup creates nine related tables covering the main entities and transaction-level data.

Key relationships include:

- Customers → Orders
- Orders → Order Items
- Products → Order Items
- Sellers → Order Items
- Orders → Payments
- Orders → Reviews

The database also uses composite keys where required by the source structure, including:

- `order_items (order_id, order_item_id)`
- `order_payments (order_id, payment_sequential)`

---

## 📋 How I Handled the Data

The project keeps the data-handling process clear and traceable.

The approach was:

- Preserve the raw source data
- Check data quality before analysis
- Investigate duplicate and NULL patterns
- Validate relationships between datasets
- Flag business-rule inconsistencies
- Use appropriate filters and aggregations during analysis
- Document important limitations instead of hiding them

The purpose of validation was not to make the dataset look perfect. It was to understand the data and its limitations before using it for analysis.

---

## 🚀 Project Workflow

### Phase 1 — SQL

**Status: ✅ Complete**

- Database setup
- Data validation
- 15 business questions
- Data quality report
- SQL documentation

### Phase 2 — Python

**Status: ✅ Complete**

- Data preparation
- Exploratory data analysis
- Validation checks
- RFM analysis
- Cohort analysis
- Logistics and SLA analysis
- Pricing and freight analysis
- Visualizations

### Phase 3 — Power BI

**Status: ⏳ In Progress**

The next step is to build the Power BI dashboard using the prepared analysis.

The final dashboard will bring the project together and present the most useful metrics and findings in a business-friendly format.

---

## 📊 Final Insights & Recommendations

**Pending completion of the Power BI phase.**

Business insights and recommendations will be added here after the SQL, Python, and Power BI work has been reviewed together.

This keeps the final conclusions consistent across all three phases of the project.

---

## 📄 Detailed Documentation

For the complete SQL data-quality findings, flagged records, treatment decisions, and analytical-use notes:

**`04_data_quality_report.md`**

---

## 📌 Project Status

| Phase | File / Area | Status |
|---|---|---|
| Database Setup | `01_setup.sql` | ✅ Complete |
| Data Validation | `02_validation.sql` | ✅ Complete |
| SQL Business Analysis | `03_business_analysis.sql` | ✅ Complete |
| Data Quality Report | `04_data_quality_report.md` | ✅ Complete |
| Python Data Preparation & EDA | `01_data_preparation_EDA.ipynb` | ✅ Complete |
| Python Business Analysis | `02_business_analysis.ipynb` | ✅ Complete |
| Power BI Dashboard | `power_bi/` | ⏳ Pending |
| Final Insights & Recommendations | README | ⏳ Pending |
| Final Project Review | All phases | ⏳ Pending |

**Current Status: SQL & Python Complete | Power BI Pending**

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

Project date: **08-Sep-2026**

---

## License

This project analyzes the Olist Brazilian E-Commerce Public Dataset. Refer to the original dataset source for its licensing and usage terms.
