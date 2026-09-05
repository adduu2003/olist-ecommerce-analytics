/* 
 * Question 1: Monthly Sales Trend & MoM Growth
 * ----------------------------------------------------------------------------
 * What we're trying to analyze here:
 * - Tracking how monthly revenue and order volume move over time.
 * - Generating a full calendar series first so if any month has zero sales, 
 *   it won't drop out of the report and keeps the MoM calculation consistent across the full timeline.
 * - Filtering strictly for 'delivered' orders to reflect delivered sales revenue.
 * - Using LAG() to fetch the previous month's revenue for the % change calculation.
 */

WITH monthly_sales AS (
    -- Aggregate monthly revenue and order count for delivered orders
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)::DATE AS sales_month,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.price) AS total_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
),

calendar_months AS (
    -- Create a continuous month timeline to catch potential missing periods
    SELECT
        generate_series(
            (
                SELECT MIN(DATE_TRUNC('month', order_purchase_timestamp))
                FROM orders
                WHERE order_status = 'delivered'
            ),
            (
                SELECT MAX(DATE_TRUNC('month', order_purchase_timestamp))
                FROM orders
                WHERE order_status = 'delivered'
            ),
            INTERVAL '1 month'
        )::DATE AS sales_month
),

complete_monthly_sales AS (
    -- Join actuals with the continuous timeline and default nulls to 0
    SELECT
        c.sales_month,
        COALESCE(ms.order_count, 0) AS order_count,
        COALESCE(ms.total_revenue, 0) AS total_revenue
    FROM calendar_months c
    LEFT JOIN monthly_sales ms
        ON c.sales_month = ms.sales_month
),

monthly_with_lag AS (
    -- Fetch previous month's revenue using LAG window function
    SELECT
        sales_month,
        order_count,
        total_revenue,
        LAG(total_revenue) OVER (
            ORDER BY sales_month
        ) AS previous_month_revenue
    FROM complete_monthly_sales
)

-- Final SELECT: calculate month-over-month growth percentage
SELECT
    sales_month,
    order_count,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,
    ROUND(
        (total_revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0) * 100,
        2
    ) AS mom_revenue_growth_pct
FROM monthly_with_lag
ORDER BY sales_month;


/* 
 * Question 2: Average Order Value (AOV) & Freight Cost
 * ----------------------------------------------------------------------------
 * What we're trying to analyze here:
 * - Looking at typical customer spending per order (AOV) alongside shipping costs.
 * - Pre-aggregating price and freight values at the order level first so multi-item 
 *   orders don't skew our averages due to row expansion (fan-out).
 * - Calculating the overall freight burden percentage to see how heavily shipping 
 *   costs weigh against actual product sales value.
 */

WITH order_financials AS (
    -- Aggregate total price and freight at the individual order level
    SELECT
        o.order_id,
        SUM(oi.price) AS total_order_value,
        SUM(oi.freight_value) AS total_freight_cost
    FROM orders o
    JOIN order_items oi 
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id
)

-- Final SELECT: calculate overall averages and freight burden percentage
SELECT
    COUNT(order_id) AS total_delivered_orders,
    ROUND(AVG(total_order_value), 2) AS average_order_value,
    ROUND(AVG(total_freight_cost), 2) AS average_freight_per_order,
    ROUND(
        (AVG(total_freight_cost) / NULLIF(AVG(total_order_value), 0)) * 100, 
        2
    ) AS freight_burden_pct
FROM order_financials;


/* 
 * Question 3: Order Fulfillment Pipeline & Revenue Leakage (GMV at Risk)
 * ----------------------------------------------------------------------------
 * What we're trying to analyze here:
 * - Breakdown of orders across each fulfillment stage to check overall operational health.
 * - Using a LEFT JOIN so canceled or unavailable orders that don't have line items attached 
 *   still get counted properly instead of dropping off.
 * - Calculating Gross Merchandise Value (GMV) per status to pinpoint potential revenue 
 *   at risk due to canceled and unavailable orders.
 * - Computing order percentage share across statuses using a window function.
 */

WITH order_level_revenue AS (
    -- Pre-aggregate price at order level, accounting for items with no line entries
    SELECT
        o.order_id,
        o.order_status,
        COALESCE(SUM(oi.price), 0) AS total_order_value
    FROM orders o
    LEFT JOIN order_items oi 
        ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.order_status
)

-- Final SELECT: summarize order distribution, GMV, and revenue at risk
SELECT
    order_status,
    COUNT(order_id) AS order_count,
    ROUND(SUM(total_order_value), 2) AS total_gmv,
    ROUND(
        SUM(CASE WHEN order_status IN ('canceled', 'unavailable') THEN total_order_value ELSE 0 END), 
        2
    ) AS revenue_at_risk,
    ROUND(
        (COUNT(order_id) * 100.0) / SUM(COUNT(order_id)) OVER (), 
        2
    ) AS order_share_pct
FROM order_level_revenue
GROUP BY order_status
ORDER BY order_count DESC;


/* 
 * Question 4: State-wise Revenue & Order Ranking
 * ----------------------------------------------------------------------------
 * What we're trying to analyze here:
 * - Aggregating delivered product revenue, order volume, and unique customer counts by state.
 * - Using DENSE_RANK() to establish a clean state-level financial performance leaderboard.
 * - Calculating average product order value per state to measure regional purchasing power.
 * - Filtering strictly for 'delivered' orders to maintain financial accounting accuracy.
 */

WITH state_financials AS (
    -- Aggregate revenue, orders, and unique customer counts per customer state
    SELECT
        c.customer_state,
        COUNT(DISTINCT o.order_id) AS total_orders,
        COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
        SUM(oi.price) AS total_product_revenue,
        AVG(oi.price) AS avg_item_price
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_state
)

-- Final SELECT: rank states by total product revenue and format metrics
SELECT
    DENSE_RANK() OVER (ORDER BY total_product_revenue DESC) AS revenue_rank,
    customer_state,
    total_orders,
    unique_customers,
    ROUND(total_product_revenue::numeric, 2) AS total_product_revenue,
    ROUND(
        (total_product_revenue / NULLIF(total_orders, 0))::numeric, 
        2
    ) AS avg_order_value,
    ROUND(avg_item_price::numeric, 2) AS avg_item_price
FROM state_financials
ORDER BY revenue_rank ASC;

/* 
 * Question 5: Top Customer Cities
 * ----------------------------------------------------------------------------
 * What we're trying to analyze here:
 * - Identifying top-performing municipal markets across Brazil by customer city and state.
 * - Aggregating delivered product revenue, order volume, and unique customer counts per city.
 * - Using DENSE_RANK() to establish a city-level financial ranking based on product revenue.
 * - Calculating average order value (AOV) per city to evaluate local purchasing density.
 * - Filtering strictly for 'delivered' orders to maintain financial accounting integrity.
 */

WITH city_financials AS (
    -- Aggregate revenue, order volume, and unique customers per city/state
    SELECT
        c.customer_city,
        c.customer_state,
        COUNT(DISTINCT o.order_id) AS total_orders,
        COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
        SUM(oi.price) AS total_product_revenue
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_city, c.customer_state
)

-- Final SELECT: rank cities by total product revenue and format financial metrics
SELECT
    DENSE_RANK() OVER (ORDER BY total_product_revenue DESC) AS city_rank,
    customer_city,
    customer_state,
    total_orders,
    unique_customers,
    ROUND(total_product_revenue::numeric, 2) AS total_product_revenue,
    ROUND(
        (total_product_revenue / NULLIF(total_orders, 0))::numeric, 
        2
    ) AS avg_order_value
FROM city_financials
ORDER BY city_rank ASC;

/* 
 * Question 6: Repeat Customer Rate
 * ----------------------------------------------------------------------------
 * What we're trying to analyze here:
 * - Evaluating overall platform retention by tracking unique buyers via customer_unique_id.
 * - Segmenting the customer base into single-purchase buyers vs repeat purchasers (2+ orders).
 * - Calculating the repeat customer rate % alongside the percentage share of total delivered orders 
 *   contributed by repeat customers.
 * - Filtering strictly for 'delivered' orders to reflect confirmed customer retention.
 */

WITH customer_order_counts AS (
    -- Count distinct delivered orders per unique customer
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
retention_metrics AS (
    -- Aggregate total customer counts and order volumes by buyer tier
    SELECT
        COUNT(customer_unique_id) AS total_unique_customers,
        COUNT(CASE WHEN order_count = 1 THEN 1 END) AS single_order_customers,
        COUNT(CASE WHEN order_count > 1 THEN 1 END) AS repeat_customers,
        SUM(order_count) AS total_delivered_orders,
        SUM(CASE WHEN order_count > 1 THEN order_count ELSE 0 END) AS repeat_customer_orders
    FROM customer_order_counts
)

-- Final SELECT: compute repeat customer rate % and repeat order contribution share %
SELECT
    total_unique_customers,
    single_order_customers,
    repeat_customers,
    ROUND(
        (repeat_customers * 100.0 / NULLIF(total_unique_customers, 0))::numeric, 
        2
    ) AS repeat_customer_rate_pct,
    total_delivered_orders,
    repeat_customer_orders,
    ROUND(
        (repeat_customer_orders * 100.0 / NULLIF(total_delivered_orders, 0))::numeric, 
        2
    ) AS repeat_order_share_pct
FROM retention_metrics;


/* 
 * Question 7: Top & Bottom Product Categories Performance
 * ----------------------------------------------------------------------------
 * What we're trying to analyze here:
 * - Identifying the highest and lowest performing product categories based on delivered product revenue.
 * - Joining products with product_category_name_translation to present clean English category names.
 * - Using DENSE_RANK() in both descending and ascending order to capture Top 10 and Bottom 10 categories.
 * - Computing total items sold, total orders, total product revenue, and average item price per category.
 * - Filtering strictly for 'delivered' orders to maintain financial reporting integrity.
 */

WITH category_performance AS (
    -- Aggregate revenue, item counts, and order volume per English category name
    SELECT
        COALESCE(pct.product_category_name_english, p.product_category_name, 'Unknown / Uncategorized') AS category_name,
        COUNT(DISTINCT o.order_id) AS total_orders,
        COUNT(oi.order_item_id) AS total_items_sold,
        SUM(oi.price) AS total_product_revenue,
        AVG(oi.price) AS avg_item_price
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    LEFT JOIN product_category_name_translation pct
        ON p.product_category_name = pct.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY COALESCE(pct.product_category_name_english, p.product_category_name, 'Unknown / Uncategorized')
),
ranked_categories AS (
    -- Assign top and bottom ranks based on total product revenue
    SELECT
        category_name,
        total_orders,
        total_items_sold,
        total_product_revenue,
        avg_item_price,
        DENSE_RANK() OVER (ORDER BY total_product_revenue DESC) AS top_rank,
        DENSE_RANK() OVER (ORDER BY total_product_revenue ASC) AS bottom_rank
    FROM category_performance
)

-- Final SELECT: filter for Top 10 and Bottom 10 categories and label performance tier
SELECT
    CASE 
        WHEN top_rank <= 10 THEN 'Top 10'
        WHEN bottom_rank <= 10 THEN 'Bottom 10'
    END AS performance_tier,
    CASE 
        WHEN top_rank <= 10 THEN top_rank
        ELSE bottom_rank
    END AS tier_rank,
    category_name,
    total_orders,
    total_items_sold,
    ROUND(total_product_revenue::numeric, 2) AS total_product_revenue,
    ROUND(avg_item_price::numeric, 2) AS avg_item_price
FROM ranked_categories
WHERE top_rank <= 10 OR bottom_rank <= 10
ORDER BY 
    CASE WHEN top_rank <= 10 THEN 1 ELSE 2 END,
    top_rank ASC,
    bottom_rank ASC;

-- Q8: Freight-to-Price Impact by Category (With Translation Table Join)
WITH category_freight AS (
    SELECT 
        COALESCE(t.product_category_name_english, p.product_category_name, 'untranslated') AS category_name,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        SUM(oi.price) AS total_product_revenue,
        SUM(oi.freight_value) AS total_freight_cost,
        AVG(oi.price) AS avg_product_price,
        AVG(oi.freight_value) AS avg_freight_cost
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT 
    category_name,
    total_orders,
    ROUND(total_product_revenue::numeric, 2) AS total_product_revenue,
    ROUND(total_freight_cost::numeric, 2) AS total_freight_cost,
    ROUND(avg_product_price::numeric, 2) AS avg_product_price,
    ROUND(avg_freight_cost::numeric, 2) AS avg_freight_cost,
    ROUND((total_freight_cost / NULLIF(total_product_revenue, 0) * 100)::numeric, 2) AS freight_to_price_percentage,
    DENSE_RANK() OVER (ORDER BY (total_freight_cost / NULLIF(total_product_revenue, 0)) DESC) AS freight_burden_rank
FROM category_freight
WHERE total_orders >= 10
ORDER BY freight_to_price_percentage DESC;

/* 
 * Question 9: Basket Size & Revenue Contribution
 * ----------------------------------------------------------------------------
 * What we're trying to analyze here:
 * - Grouping delivered orders by basket size (1 item, 2 items, 3 items, 4+ items).
 * - Counting total orders, total items sold, and total product revenue per basket size tier.
 * - Calculating order share percentage and revenue share percentage for each basket tier.
 * - Filtering strictly for 'delivered' orders to reflect true purchase completion.
 */

WITH order_basket_sizes AS (
    SELECT
        o.order_id,
        COUNT(oi.order_item_id) AS item_count,
        SUM(oi.price) AS order_product_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id
),
basket_tiered AS (
    SELECT
        order_id,
        item_count,
        order_product_revenue,
        CASE
            WHEN item_count = 1 THEN '1 Item'
            WHEN item_count = 2 THEN '2 Items'
            WHEN item_count = 3 THEN '3 Items'
            ELSE '4+ Items'
        END AS basket_tier,
        CASE
            WHEN item_count = 1 THEN 1
            WHEN item_count = 2 THEN 2
            WHEN item_count = 3 THEN 3
            ELSE 4
        END AS tier_order
    FROM order_basket_sizes
)

SELECT
    basket_tier,
    COUNT(order_id) AS total_orders,
    ROUND(
        (COUNT(order_id) * 100.0 / NULLIF(SUM(COUNT(order_id)) OVER (), 0))::numeric, 
        2
    ) AS order_share_pct,
    SUM(item_count) AS total_items_sold,
    ROUND(SUM(order_product_revenue)::numeric, 2) AS total_product_revenue,
    ROUND(
        (SUM(order_product_revenue) * 100.0 / NULLIF(SUM(SUM(order_product_revenue)) OVER (), 0))::numeric, 
        2
    ) AS revenue_share_pct
FROM basket_tiered
GROUP BY basket_tier, tier_order
ORDER BY tier_order ASC;


/* 
 * Question 10: Payment Method Distribution
 * ----------------------------------------------------------------------------
 * What we're trying to analyze here:
 * - Evaluating volume, revenue, and share of payment transactions by payment_type.
 * - Excluding 'not_defined' records and filtering for 'delivered' orders.
 * - Calculating each payment method's share of overall platform payment value using window functions.
 * - Computing total payment records, total payment value, and average transaction size per method.
 */

WITH payment_distribution AS (
    SELECT
        op.payment_type,
        COUNT(DISTINCT op.order_id) AS total_orders,
        COUNT(op.payment_sequential) AS total_payment_records,
        SUM(op.payment_value) AS total_payment_value,
        AVG(op.payment_value) AS avg_transaction_size
    FROM order_payments op
    JOIN orders o
        ON op.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND op.payment_type != 'not_defined'
    GROUP BY op.payment_type
)

SELECT
    payment_type,
    total_orders,
    total_payment_records,
    ROUND(total_payment_value::numeric, 2) AS total_payment_value,
    ROUND(
        (total_payment_value * 100.0 / NULLIF(SUM(total_payment_value) OVER (), 0))::numeric, 
        2
    ) AS payment_value_share_pct,
    ROUND(avg_transaction_size::numeric, 2) AS avg_transaction_size
FROM payment_distribution
ORDER BY total_payment_value DESC;

/* 
 * Question 11: Credit Card Installment Behavior
 * ----------------------------------------------------------------------------
 * What we're trying to analyze here:
 * - Focusing strictly on credit card transactions to evaluate installment usage patterns.
 * - Categorizing credit card payments into installment buckets (1x, 2x-3x, 4x-6x, 7x-10x, 11x+).
 * - Measuring order volume, total payment value, average order value, and percentage contribution per bucket.
 * - Filtering for 'delivered' orders and 'credit_card' payment type.
 */

WITH credit_card_payments AS (
    SELECT
        op.order_id,
        op.payment_value,
        op.payment_installments,
        CASE
            WHEN op.payment_installments = 1 THEN '1x (Single Payment)'
            WHEN op.payment_installments BETWEEN 2 AND 3 THEN '2x - 3x Installments'
            WHEN op.payment_installments BETWEEN 4 AND 6 THEN '4x - 6x Installments'
            WHEN op.payment_installments BETWEEN 7 AND 10 THEN '7x - 10x Installments'
            ELSE '11x+ Installments'
        END AS installment_tier,
        CASE
            WHEN op.payment_installments = 1 THEN 1
            WHEN op.payment_installments BETWEEN 2 AND 3 THEN 2
            WHEN op.payment_installments BETWEEN 4 AND 6 THEN 3
            WHEN op.payment_installments BETWEEN 7 AND 10 THEN 4
            ELSE 5
        END AS tier_order
    FROM order_payments op
    JOIN orders o
        ON op.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND op.payment_type = 'credit_card'
)

SELECT
    installment_tier,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(
        (COUNT(DISTINCT order_id) * 100.0 / NULLIF(SUM(COUNT(DISTINCT order_id)) OVER (), 0))::numeric, 
        2
    ) AS order_share_pct,
    ROUND(SUM(payment_value)::numeric, 2) AS total_payment_value,
    ROUND(
        (SUM(payment_value) * 100.0 / NULLIF(SUM(SUM(payment_value)) OVER (), 0))::numeric, 
        2
    ) AS payment_value_share_pct,
    ROUND(AVG(payment_value)::numeric, 2) AS avg_transaction_size
FROM credit_card_payments
GROUP BY installment_tier, tier_order
ORDER BY tier_order ASC;


/* 
 * Question 12: Voucher Payment Impact
 * ----------------------------------------------------------------------------
 * What we're trying to analyze here:
 * - Analyzing the usage frequency and monetary volume of voucher payments across delivered orders.
 * - Comparing order value and item basket sizes between voucher-backed orders vs non-voucher orders.
 * - Measuring total voucher value redeemed and calculating average voucher discount per order.
 * - Filtering strictly for 'delivered' orders and excluding 'not_defined' payment statuses.
 */

WITH order_voucher_breakdown AS (
    SELECT
        o.order_id,
        SUM(oi.price) AS total_order_price,
        COUNT(oi.order_item_id) AS total_items,
        MAX(CASE WHEN op.payment_type = 'voucher' THEN 1 ELSE 0 END) AS used_voucher,
        SUM(CASE WHEN op.payment_type = 'voucher' THEN op.payment_value ELSE 0 END) AS total_voucher_value
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN order_payments op
        ON o.order_id = op.order_id
    WHERE o.order_status = 'delivered'
      AND op.payment_type != 'not_defined'
    GROUP BY o.order_id
)

SELECT
    CASE WHEN used_voucher = 1 THEN 'Voucher Used' ELSE 'No Voucher' END AS voucher_usage,
    COUNT(order_id) AS total_orders,
    ROUND(
        (COUNT(order_id) * 100.0 / NULLIF(SUM(COUNT(order_id)) OVER (), 0))::numeric, 
        2
    ) AS order_share_pct,
    ROUND(SUM(total_order_price)::numeric, 2) AS total_product_revenue,
    ROUND(AVG(total_order_price)::numeric, 2) AS avg_order_value,
    ROUND(AVG(total_items)::numeric, 2) AS avg_items_per_order,
    ROUND(SUM(total_voucher_value)::numeric, 2) AS total_voucher_redeemed,
    ROUND(
        AVG(CASE WHEN used_voucher = 1 THEN total_voucher_value END)::numeric, 
        2
    ) AS avg_voucher_amount
FROM order_voucher_breakdown
GROUP BY used_voucher
ORDER BY used_voucher DESC;

/* 
 * Question 13: Delivery Latency & SLA Gap
 * ----------------------------------------------------------------------------
 * What we're trying to analyze here:
 * - Evaluating overall platform logistics lead times and actual delivery vs estimated SLA gap.
 * - Measuring average actual delivery duration (purchase timestamp to customer delivery timestamp).
 * - Calculating variance in days (actual delivery date minus estimated delivery date).
 * - Categorizing orders into 'Early Delivery', 'On-Time Delivery', and 'Late Delivery'.
 * - Filtering strictly for delivered orders with complete timestamp records.
 */

WITH delivery_sla_metrics AS (
    SELECT
        order_id,
        EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp)) / 86400.0 AS actual_delivery_days,
        EXTRACT(EPOCH FROM (order_estimated_delivery_date - order_purchase_timestamp)) / 86400.0 AS estimated_delivery_days,
        EXTRACT(EPOCH FROM (order_delivered_customer_date - order_estimated_delivery_date)) / 86400.0 AS sla_gap_days,
        CASE
            WHEN order_delivered_customer_date::date < order_estimated_delivery_date::date THEN 'Early Delivery'
            WHEN order_delivered_customer_date::date = order_estimated_delivery_date::date THEN 'On-Time Delivery'
            ELSE 'Late Delivery'
        END AS sla_status,
        CASE
            WHEN order_delivered_customer_date::date < order_estimated_delivery_date::date THEN 1
            WHEN order_delivered_customer_date::date = order_estimated_delivery_date::date THEN 2
            ELSE 3
        END AS status_order
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
      AND order_purchase_timestamp IS NOT NULL
)

SELECT
    sla_status,
    COUNT(order_id) AS total_orders,
    ROUND(
        (COUNT(order_id) * 100.0 / NULLIF(SUM(COUNT(order_id)) OVER (), 0))::numeric, 
        2
    ) AS order_share_pct,
    ROUND(AVG(actual_delivery_days)::numeric, 1) AS avg_actual_delivery_days,
    ROUND(AVG(estimated_delivery_days)::numeric, 1) AS avg_estimated_delivery_days,
    ROUND(AVG(sla_gap_days)::numeric, 1) AS avg_sla_gap_days
FROM delivery_sla_metrics
GROUP BY sla_status, status_order
ORDER BY status_order ASC;


/* 
 * Question 14: Delivery Performance vs Review Score
 * ----------------------------------------------------------------------------
 * What we're trying to analyze here:
 * - Evaluating the relationship between fulfillment timeliness (On-Time / Early vs Late) and customer review scores.
 * - Deduplicating review records using ROW_NUMBER() with NULLS LAST to select one primary review per order.
 * - Measuring average review score, 5-star rating share, and 1-star rating share across delivery performance buckets.
 * - Filtering strictly for delivered orders with complete timestamps and valid reviews.
 */

WITH dedup_reviews AS (
    SELECT
        order_id,
        review_score,
        ROW_NUMBER() OVER (
            PARTITION BY order_id 
            ORDER BY review_answer_timestamp DESC NULLS LAST
        ) AS rn
    FROM order_reviews
),
order_delivery_reviews AS (
    SELECT
        o.order_id,
        r.review_score,
        CASE
            WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 'On-Time / Early'
            ELSE 'Late Delivery'
        END AS delivery_performance
    FROM orders o
    JOIN dedup_reviews r
        ON o.order_id = r.order_id AND r.rn = 1
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
)

SELECT
    delivery_performance,
    COUNT(order_id) AS total_orders,
    ROUND(
        (COUNT(order_id) * 100.0 / NULLIF(SUM(COUNT(order_id)) OVER (), 0))::numeric, 
        2
    ) AS order_share_pct,
    ROUND(AVG(review_score)::numeric, 2) AS avg_review_score,
    ROUND(
        (COUNT(CASE WHEN review_score = 5 THEN 1 END) * 100.0 / NULLIF(COUNT(order_id), 0))::numeric, 
        2
    ) AS five_star_pct,
    ROUND(
        (COUNT(CASE WHEN review_score = 1 THEN 1 END) * 100.0 / NULLIF(COUNT(order_id), 0))::numeric, 
        2
    ) AS one_star_pct
FROM order_delivery_reviews
GROUP BY delivery_performance
ORDER BY avg_review_score DESC;

/* 
 * Question 15: Seller Pareto Analysis (80/20 Rule)
 * ----------------------------------------------------------------------------
 * What we're trying to analyze here:
 * - Evaluating seller revenue concentration to verify if the Pareto Principle (top 20% sellers generate ~80% revenue) holds true.
 * - Calculating total product revenue per seller for delivered orders.
 * - Ranking sellers and computing cumulative revenue percentage share using window functions.
 * - Segmenting sellers into 'Top 20% Sellers' and 'Bottom 80% Sellers'.
 * - Measuring seller count, total revenue, revenue contribution share, and average revenue per seller.
 */

WITH seller_revenue AS (
    SELECT
        oi.seller_id,
        SUM(oi.price) AS total_seller_revenue,
        COUNT(DISTINCT oi.order_id) AS total_orders
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id
),
seller_ranked AS (
    SELECT
        seller_id,
        total_seller_revenue,
        total_orders,
        NTILE(5) OVER (ORDER BY total_seller_revenue DESC) AS seller_quintile
    FROM seller_revenue
)

SELECT
    CASE 
        WHEN seller_quintile = 1 THEN 'Top 20% Sellers'
        ELSE 'Bottom 80% Sellers'
    END AS seller_tier,
    COUNT(seller_id) AS seller_count,
    ROUND(
        (COUNT(seller_id) * 100.0 / NULLIF(SUM(COUNT(seller_id)) OVER (), 0))::numeric, 
        2
    ) AS seller_share_pct,
    ROUND(SUM(total_seller_revenue)::numeric, 2) AS total_product_revenue,
    ROUND(
        (SUM(total_seller_revenue) * 100.0 / NULLIF(SUM(SUM(total_seller_revenue)) OVER (), 0))::numeric, 
        2
    ) AS revenue_share_pct,
    ROUND(AVG(total_seller_revenue)::numeric, 2) AS avg_revenue_per_seller
FROM seller_ranked
GROUP BY CASE WHEN seller_quintile = 1 THEN 'Top 20% Sellers' ELSE 'Bottom 80% Sellers' END
ORDER BY total_product_revenue DESC;

-- ============================================
-- BUSINESS ANALYSIS - Q1 TO Q15
-- ============================================
-- Project: Olist E-Commerce Marketplace Analysis
-- Dataset: 100K orders, 99K customers, 3K sellers
-- Analysis Type: Revenue, Customer, Product, Geographic
-- SQL Techniques: CTEs, Window Functions, Complex Joins
-- ============================================
-- ANALYSIS ROADMAP
-- ============================================
-- Q1-Q3:   Sales Performance (Revenue, AOV, Status)
-- Q4-Q6:   Geographic & Customer Analysis (States, Cities, Repeat Rate)
-- Q7-Q9:   Product Performance (Categories, Freight, Basket)
-- Q10-Q12: Payment Analysis (Methods, Installments, Vouchers)
-- Q13-Q15: Operations & Seller (Delivery, Reviews, Pareto)
-- ============================================
