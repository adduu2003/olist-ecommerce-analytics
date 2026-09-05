-- ============================================
-- Olist E-Commerce Database Setup
-- Author: [ADEEB MUZAFFAR]
-- Date: [05-Sep-2026]
-- Version: 1.0
-- ============================================
-- Purpose: Create normalized schema for Olist data
-- Tables: 9 core tables with relationships
-- Status: Production Ready
-- ============================================

-- ============================================
-- DROP ALL TABLES (Start Fresh)
-- ============================================
DROP TABLE IF EXISTS order_reviews CASCADE;
DROP TABLE IF EXISTS order_payments CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS product_category_name_translation CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS sellers CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS geolocation CASCADE;

-- ============================================
-- 1. CUSTOMERS TABLE
-- ============================================
-- Stores customer master data
-- Primary key: customer_id (unique identifier)
-- Note: customer_unique_id tracks same customer across multiple orders
-- Purpose: Central repository for all customer information

CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INTEGER,
    customer_city VARCHAR(100) NOT NULL,
    customer_state CHAR(2)
);

-- ============================================
-- 2. SELLERS TABLE
-- ============================================
-- Stores seller/merchant information
-- Primary key: seller_id (unique identifier)
-- Relationship: Multiple sellers can have multiple products
-- Purpose: Track all marketplace sellers and their locations

CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INTEGER,
    seller_city VARCHAR(100) NOT NULL,
    seller_state CHAR(2) NOT NULL
);

-- ============================================
-- 3. PRODUCTS TABLE
-- ============================================
-- Stores product catalog information
-- Primary key: product_id (unique identifier)
-- Contains: Category, dimensions, weight, photos metadata
-- Purpose: Central product repository with physical attributes
-- Note: product_category_name can be NULL for unclassified products

CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g DECIMAL(10, 2),
    product_length_cm DECIMAL(10, 2),
    product_height_cm DECIMAL(10, 2),
    product_width_cm DECIMAL(10, 2),
    CHECK (product_weight_g >= 0),
    CHECK (product_length_cm >= 0),
    CHECK (product_height_cm >= 0),
    CHECK (product_width_cm >= 0)
);

-- ============================================
-- 4. GEOLOCATION TABLE
-- ============================================
-- Stores geographic location data (latitude/longitude for zip codes)
-- Allows: Geographic analysis and mapping capabilities
-- Contains: Coordinates and city/state information
-- Purpose: Enable location-based analysis and regional performance tracking
-- Note: May contain duplicate entries for same location (preserved)

CREATE TABLE geolocation (
    geolocation_zip_code_prefix INTEGER,
    geolocation_lat NUMERIC(10, 6) NOT NULL,
    geolocation_lng NUMERIC(10, 6) NOT NULL,
    geolocation_city VARCHAR(100) NOT NULL,
    geolocation_state CHAR(2) NOT NULL,
    CHECK (geolocation_lat BETWEEN -90 AND 90),
    CHECK (geolocation_lng BETWEEN -180 AND 180)
);

-- ============================================
-- 5. PRODUCT CATEGORY TRANSLATION TABLE
-- ============================================
-- Stores product category names in Portuguese and English
-- Primary key: product_category_name (Portuguese)
-- Maps: Portuguese category names to English translations
-- Purpose: Enable bilingual product categorization and analysis

CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100) NOT NULL
);

-- ============================================
-- 6. ORDERS TABLE
-- ============================================
-- Stores order header information
-- Primary key: order_id (unique identifier)
-- Foreign key: customer_id (references customers table)
-- Contains: Order status, purchase timestamp, delivery dates
-- Purpose: Central order transaction log with complete order lifecycle
-- Note: Timestamps can be NULL based on order status (e.g., cancelled orders)

CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    order_status VARCHAR(20) NOT NULL,
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- ============================================
-- 7. ORDER_ITEMS TABLE
-- ============================================
-- Stores individual line items within each order
-- Primary key: (order_id, order_item_id) - composite key
-- Foreign keys: order_id, product_id, seller_id
-- Contains: Product, seller, price, and freight information per item
-- Purpose: Track all products sold in each order with granular detail
-- Relationship: One order can have multiple items, multiple sellers per order

CREATE TABLE order_items (
    order_id VARCHAR(50) NOT NULL,
    order_item_id INTEGER NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    seller_id VARCHAR(50) NOT NULL,
    shipping_limit_date TIMESTAMP NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    freight_value NUMERIC(10, 2),
    
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id),
    CHECK (price > 0),
    CHECK (freight_value >= 0)
);

-- ============================================
-- 8. ORDER_PAYMENTS TABLE
-- ============================================
-- Stores payment information for each order
-- Primary key: (order_id, payment_sequential) - composite key
-- Foreign key: order_id (references orders table)
-- Contains: Payment method, installments, and payment value
-- Purpose: Track all payment transactions and methods used
-- Relationship: One order can have multiple payment records (split payments)
-- Note: payment_installments can be 0 in raw data (preserved as-is)

CREATE TABLE order_payments (
    order_id VARCHAR(50) NOT NULL,
    payment_sequential INTEGER NOT NULL,
    payment_type VARCHAR(30) NOT NULL,
    payment_installments INTEGER NOT NULL,
    payment_value NUMERIC(10, 2) NOT NULL,
    
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- ============================================
-- 9. ORDER_REVIEWS TABLE
-- ============================================
-- Stores customer reviews and ratings for orders
-- Note: review_id is NOT unique (multiple reviews per ID possible)
-- Foreign key: order_id (references orders table)
-- Contains: Review score, comments, and seller response timestamp
-- Purpose: Track customer satisfaction and feedback
-- Relationship: One order can have one review (but review_id may duplicate)
-- Note: Review comments can be NULL (customers can rate without comment)

CREATE TABLE order_reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50) NOT NULL,
    review_score INTEGER NOT NULL,
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date TIMESTAMP NOT NULL,
    review_answer_timestamp TIMESTAMP,
    
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CHECK (review_score BETWEEN 1 AND 5)
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================
-- High-cardinality columns indexed for faster queries
-- Foreign key columns indexed for JOIN performance
-- Date columns indexed for range queries

CREATE INDEX idx_customers_city ON customers(customer_city);
CREATE INDEX idx_customers_state ON customers(customer_state);
CREATE INDEX idx_customers_unique_id ON customers(customer_unique_id);
CREATE INDEX idx_sellers_city ON sellers(seller_city);
CREATE INDEX idx_sellers_state ON sellers(seller_state);
CREATE INDEX idx_products_category ON products(product_category_name);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_orders_purchase_date ON orders(order_purchase_timestamp);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_order_items_seller_id ON order_items(seller_id);
CREATE INDEX idx_order_payments_order_id ON order_payments(order_id);
CREATE INDEX idx_order_reviews_order_id ON order_reviews(order_id);
CREATE INDEX idx_order_reviews_review_id ON order_reviews(review_id);

-- ============================================
-- VERIFY ALL TABLES CREATED
-- ============================================
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- ============================================
-- CHECK ROW COUNTS
-- ============================================
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL
SELECT 'geolocation', COUNT(*) FROM geolocation
UNION ALL
SELECT 'product_category_name_translation', COUNT(*) FROM product_category_name_translation
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
ORDER BY table_name;

-- ============================================
-- SETUP COMPLETE
-- ============================================
-- All 9 tables created successfully
-- Indexes: 14 strategic indexes added
-- Foreign Keys: 6 relationships defined
-- Constraints: Appropriate CHECK constraints applied
-- Next Step: Run validation.sql
-- ============================================


