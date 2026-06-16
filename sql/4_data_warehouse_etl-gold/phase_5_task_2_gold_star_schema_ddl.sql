/*
=================================================================================
Gold Layer - Complete Star Schema DDL (Based on Analytical SQL Validation)
=================================================================================
VERSION  : 3.0
AUTHOR   : Amr Bayomei Basha (Enhanced by Copilot)
DATE     : May 2026
TARGET   : SQL Server - AdventureWorks2025_CustomerDW

ARCHITECTURE:
- Kimball Star Schema
- SCD Type 1 Dimensions (descriptive only)
- No Foreign Key Constraints (ETL-friendly)
- All analytical metrics in fact tables

FACT TABLES (derived from Analytical SQL Validation):
1. fact_sales                    -- Transaction grain
2. fact_customer_analytics       -- Customer grain (Q1/Q2/Q3 metrics)
3. fact_customer_cohort          -- Cohort × Period grain (Q4 metrics)
4. fact_customer_btyd_inputs     -- Customer grain (Q5/Q6/Q7 metrics)
5. fact_salesreason              -- Bridge table

DIMENSIONS (unchanged - descriptive only):
1. dim_date
2. dim_territory
3. dim_product
4. dim_customer
5. dim_specialoffer
6. dim_salesreason
=================================================================================
*/

USE AdventureWorks2025_CustomerDW;
GO

-- =============================================================================
-- DROP EXISTING TABLES (IN DEPENDENCY ORDER)
-- =============================================================================

IF OBJECT_ID('gold.fact_salesreason', 'U') IS NOT NULL DROP TABLE gold.fact_salesreason;
IF OBJECT_ID('gold.fact_customer_btyd_inputs', 'U') IS NOT NULL DROP TABLE gold.fact_customer_btyd_inputs;
IF OBJECT_ID('gold.fact_customer_cohort', 'U') IS NOT NULL DROP TABLE gold.fact_customer_cohort;
IF OBJECT_ID('gold.fact_customer_analytics', 'U') IS NOT NULL DROP TABLE gold.fact_customer_analytics;
IF OBJECT_ID('gold.fact_customer_rfm', 'U') IS NOT NULL DROP TABLE gold.fact_customer_rfm;
IF OBJECT_ID('gold.fact_sales', 'U') IS NOT NULL DROP TABLE gold.fact_sales;
IF OBJECT_ID('gold.dim_salesreason', 'U') IS NOT NULL DROP TABLE gold.dim_salesreason;
IF OBJECT_ID('gold.dim_specialoffer', 'U') IS NOT NULL DROP TABLE gold.dim_specialoffer;
IF OBJECT_ID('gold.dim_customer', 'U') IS NOT NULL DROP TABLE gold.dim_customer;
IF OBJECT_ID('gold.dim_product', 'U') IS NOT NULL DROP TABLE gold.dim_product;
IF OBJECT_ID('gold.dim_territory', 'U') IS NOT NULL DROP TABLE gold.dim_territory;
IF OBJECT_ID('gold.dim_date', 'U') IS NOT NULL DROP TABLE gold.dim_date;
GO

PRINT '=================================================================================';
PRINT 'Creating Gold Layer Dimension Tables (SCD Type 1 - Descriptive Only)';
PRINT '=================================================================================';
PRINT '';

-- =============================================================================
-- DIM_DATE: Standard Date Dimension (Keep as-is)
-- =============================================================================

CREATE TABLE gold.dim_date (
    date_key                INT NOT NULL,
    date                    DATE NOT NULL,
    year                    INT NOT NULL,
    quarter                 INT NOT NULL,
    month                   INT NOT NULL,
    month_name              NVARCHAR(20) NOT NULL,
    day_of_month            INT NOT NULL,
    day_of_week             INT NOT NULL,
    day_name                NVARCHAR(20) NOT NULL,
    week_of_year            INT NOT NULL,
    is_weekend              BIT NOT NULL,
    is_holiday              BIT NOT NULL DEFAULT 0,
    fiscal_year             INT NOT NULL,
    fiscal_quarter          INT NOT NULL,
    fiscal_month            INT NOT NULL,
    year_month              CHAR(10) NOT NULL,
    quarter_name            CHAR(10) NOT NULL,
    
    CONSTRAINT pk_dim_date PRIMARY KEY CLUSTERED (date_key)
);

CREATE UNIQUE NONCLUSTERED INDEX ix_dim_date_date ON gold.dim_date(date);
CREATE NONCLUSTERED INDEX ix_dim_date_year_month ON gold.dim_date(year, month);

PRINT '✓ Dim_Date created';
GO

-- =============================================================================
-- DIM_TERRITORY: Sales Territory Dimension (Keep as-is)
-- =============================================================================

CREATE TABLE gold.dim_territory (
    territory_key           INT IDENTITY(1,1) NOT NULL,
    territory_id            INT NOT NULL,
    territory_name          NVARCHAR(50) NOT NULL,
    country_code            NVARCHAR(3) NOT NULL,
    region_group            NVARCHAR(50) NOT NULL,
    dwh_load_date           DATETIME NOT NULL DEFAULT GETDATE(),
    dwh_update_date         DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT pk_dim_territory PRIMARY KEY CLUSTERED (territory_key)
);

CREATE UNIQUE NONCLUSTERED INDEX ix_dim_territory_id ON gold.dim_territory(territory_id);

PRINT '✓ Dim_Territory created';
GO

-- =============================================================================
-- DIM_PRODUCT: Product Dimension (Keep as-is)
-- =============================================================================

CREATE TABLE gold.dim_product (
    product_key             INT IDENTITY(1,1) NOT NULL,
    product_id              INT NOT NULL,
    product_name            NVARCHAR(100) NOT NULL,
    product_number          NVARCHAR(50) NOT NULL,
    category_name           NVARCHAR(50) NULL,
    subcategory_name        NVARCHAR(50) NULL,
    color                   NVARCHAR(20) NULL,
    size                    NVARCHAR(10) NULL,
    product_line            NVARCHAR(2) NULL,
    class                   NVARCHAR(2) NULL,
    style                   NVARCHAR(2) NULL,
    list_price              DECIMAL(18,2) NOT NULL,
    standard_cost           DECIMAL(18,2) NOT NULL,
    days_to_manufacture     INT NULL,
    is_active               BIT NOT NULL DEFAULT 1,
    dwh_load_date           DATETIME NOT NULL DEFAULT GETDATE(),
    dwh_update_date         DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT pk_dim_product PRIMARY KEY CLUSTERED (product_key)
);

CREATE UNIQUE NONCLUSTERED INDEX ix_dim_product_id ON gold.dim_product(product_id);
CREATE NONCLUSTERED INDEX ix_dim_product_category ON gold.dim_product(category_name, subcategory_name);

PRINT '✓ Dim_Product created';
GO

-- =============================================================================
-- DIM_CUSTOMER: Customer Dimension (Descriptive only - no metrics)
-- =============================================================================

CREATE TABLE gold.dim_customer (
    customer_key            INT IDENTITY(1,1) NOT NULL,
    customer_id             INT NOT NULL,
    
    -- Person information
    person_id               INT NULL,
    customer_name           NVARCHAR(200) NULL,
    person_type             NVARCHAR(2) NULL,
    
    -- Contact information
    email_address           NVARCHAR(100) NULL,
    
    -- Address information (current address only)
    address_line1           NVARCHAR(100) NULL,
    address_line2           NVARCHAR(100) NULL,
    city                    NVARCHAR(50) NULL,
    state_province          NVARCHAR(50) NULL,
    country                 NVARCHAR(50) NULL,
    postal_code             NVARCHAR(20) NULL,
    
    -- Territory (current assignment)
    territory_key           INT NULL,
    
    -- Audit
    dwh_load_date           DATETIME NOT NULL DEFAULT GETDATE(),
    dwh_update_date         DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT pk_dim_customer PRIMARY KEY CLUSTERED (customer_key)
);

CREATE UNIQUE NONCLUSTERED INDEX ix_dim_customer_id ON gold.dim_customer(customer_id);
CREATE NONCLUSTERED INDEX ix_dim_customer_territory ON gold.dim_customer(territory_key);
CREATE NONCLUSTERED INDEX ix_dim_customer_person ON gold.dim_customer(person_id) WHERE person_id IS NOT NULL;

PRINT '✓ Dim_Customer created (descriptive only - all metrics moved to fact tables)';
GO

-- =============================================================================
-- DIM_SPECIALOFFER: Special Offer Dimension (Keep as-is)
-- =============================================================================

CREATE TABLE gold.dim_specialoffer (
    specialoffer_key        INT IDENTITY(1,1) NOT NULL,
    specialoffer_id         INT NOT NULL,
    offer_description       NVARCHAR(100) NOT NULL,
    discount_pct            DECIMAL(5,2) NOT NULL,
    offer_type              NVARCHAR(50) NULL,
    offer_category          NVARCHAR(50) NULL,
    start_date              DATE NOT NULL,
    end_date                DATE NOT NULL,
    min_qty                 INT NULL,
    max_qty                 INT NULL,
    is_active               BIT NOT NULL,
    dwh_load_date           DATETIME NOT NULL DEFAULT GETDATE(),
    dwh_update_date         DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT pk_dim_specialoffer PRIMARY KEY CLUSTERED (specialoffer_key)
);

CREATE UNIQUE NONCLUSTERED INDEX ix_dim_specialoffer_id ON gold.dim_specialoffer(specialoffer_id);

PRINT '✓ Dim_SpecialOffer created';
GO

-- =============================================================================
-- DIM_SALESREASON: Sales Reason Dimension (Keep as-is)
-- =============================================================================

CREATE TABLE gold.dim_salesreason (
    salesreason_key         INT IDENTITY(1,1) NOT NULL,
    salesreason_id          INT NOT NULL,
    reason_name             NVARCHAR(50) NOT NULL,
    reason_type             NVARCHAR(50) NOT NULL,
    dwh_load_date           DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT pk_dim_salesreason PRIMARY KEY CLUSTERED (salesreason_key)
);

CREATE UNIQUE NONCLUSTERED INDEX ix_dim_salesreason_id ON gold.dim_salesreason(salesreason_id);

PRINT '✓ Dim_SalesReason created';
GO

PRINT '';
PRINT '=================================================================================';
PRINT 'Creating Gold Layer Fact Tables (Based on Analytical SQL Validation)';
PRINT '=================================================================================';
PRINT '';

-- =============================================================================
-- FACT_SALES: Transactional Sales Fact Table
-- Source: Analytical SQL Validation - Transactions and sales metrics validation
-- =============================================================================

CREATE TABLE gold.fact_sales (
    sales_key               BIGINT IDENTITY(1,1) NOT NULL,
    
    -- Natural keys
    salesorder_id           INT NOT NULL,
    salesorderdetail_id     INT NOT NULL,
    
    -- Role-playing date dimensions
    order_date_key          INT NOT NULL,
    due_date_key            INT NOT NULL,
    ship_date_key           INT NULL,
    
    -- Dimension foreign keys
    customer_key            INT NOT NULL,
    product_key             INT NOT NULL,
    territory_key           INT NOT NULL,
    specialoffer_key        INT NOT NULL,
    
    -- Degenerate dimensions
    order_number            NVARCHAR(25) NOT NULL,
    purchase_order_number   NVARCHAR(25) NULL,
    
    -- VOLUME METRICS
    order_quantity          INT NOT NULL,
    
    -- Currency support (defaulted)
    currency_code           CHAR(3) NOT NULL DEFAULT 'USD',
    exchange_rate           DECIMAL(10,6) NOT NULL DEFAULT 1.0,
    
    -- PRICE BEHAVIOR
    unit_price              DECIMAL(18,2) NOT NULL,
    unit_discount           DECIMAL(18,2) NOT NULL DEFAULT 0,
    
    -- Revenue (line_total = net amount after discount)
    line_total              DECIMAL(18,2) NOT NULL,
    
    -- DISCOUNT ANALYSIS
    discount_amount         DECIMAL(18,2) NOT NULL DEFAULT 0,
    
    -- COST & PROFITABILITY
    cost_amount             DECIMAL(18,2) NOT NULL DEFAULT 0,
    gross_profit            DECIMAL(18,2) NOT NULL DEFAULT 0,
    
    -- Order-level attributes (denormalized for drill-through)
    subtotal                DECIMAL(18,2) NOT NULL,
    tax_amount              DECIMAL(18,2) NOT NULL,
    freight                 DECIMAL(18,2) NOT NULL,
    total_due               DECIMAL(18,2) NOT NULL,
    
    -- Flags
    is_online_order         BIT NOT NULL,
    order_status            TINYINT NOT NULL,
    
    -- Audit
    dwh_load_date           DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT pk_fact_sales PRIMARY KEY CLUSTERED (sales_key)
);

-- Performance indexes
CREATE NONCLUSTERED INDEX ix_fact_sales_order_date 
    ON gold.fact_sales(order_date_key) INCLUDE (line_total, order_quantity, gross_profit);
CREATE NONCLUSTERED INDEX ix_fact_sales_ship_date 
    ON gold.fact_sales(ship_date_key) INCLUDE (line_total) WHERE ship_date_key IS NOT NULL;
CREATE NONCLUSTERED INDEX ix_fact_sales_customer 
    ON gold.fact_sales(customer_key) INCLUDE (line_total, order_quantity, gross_profit);
CREATE NONCLUSTERED INDEX ix_fact_sales_product 
    ON gold.fact_sales(product_key) INCLUDE (line_total, order_quantity, cost_amount);
CREATE NONCLUSTERED INDEX ix_fact_sales_territory 
    ON gold.fact_sales(territory_key) INCLUDE (line_total, gross_profit);
CREATE UNIQUE NONCLUSTERED INDEX ix_fact_sales_natural_key 
    ON gold.fact_sales(salesorder_id, salesorderdetail_id);

PRINT '✓ Fact_Sales created (transaction grain)';
GO

-- =============================================================================
-- FACT_CUSTOMER_ANALYTICS: Customer-Level Analytical Fact Table
-- Source: Analytical SQL Validation - fact_customer_analytics (Q1/Q2/Q3)
-- Grain: One row per customer per snapshot date
-- =============================================================================

CREATE TABLE gold.fact_customer_analytics (
    customer_analytics_key  BIGINT IDENTITY(1,1) NOT NULL,
    
    -- Dimension foreign key
    customer_key            INT NOT NULL,
    
    -- Snapshot date
    snapshot_date           DATE NOT NULL,
    
    -- =================================================================
    -- Q1: Who are our most valuable customers?
    -- =================================================================
    -- VOLUME METRICS
    total_revenue           DECIMAL(18,2) NULL,
    total_orders            INT NULL,
    total_quantity          INT NULL,
    avg_order_value         DECIMAL(18,2) NULL,
    
    -- PROFITABILITY METRICS
    gross_profit            DECIMAL(18,2) NULL,
    profit_margin           DECIMAL(10,6) NULL,
    
    -- CONTRIBUTION METRICS
    revenue_contribution    DECIMAL(10,6) NULL,
    profit_contribution     DECIMAL(10,6) NULL,
    
    -- LIFETIME VALUE PROXIES
    historical_clv_proxy    DECIMAL(18,2) NULL,
    historical_lifetime_profit DECIMAL(18,2) NULL,
    
    -- =================================================================
    -- Q2: Which customers are unprofitable or risky?
    -- (Metrics already captured in Q1: gross_profit, profit_margin)
    -- =================================================================
    
    -- =================================================================
    -- Q3: How do customers differ in behavior?
    -- =================================================================
    -- CUSTOMER ACTIVITY & DIVERSITY
    first_order_date        DATE NULL,
    last_order_date         DATE NULL,
    days_since_last_purchase INT NULL,
    product_diversity       INT NULL,
    category_diversity      INT NULL,
    avg_days_between_purchases DECIMAL(10,2) NULL,
    
    -- RFM CORE METRICS
    recency                 INT NULL,
    frequency               INT NULL,
    monetary                DECIMAL(18,2) NULL,
    
    -- RFM SCORES (1-5)
    r_score                 INT NULL,
    f_score                 INT NULL,
    m_score                 INT NULL,
    rfm_score               VARCHAR(3) NULL,
    
    -- CUSTOMER SEGMENTATION
    customer_segment        VARCHAR(50) NULL,
    
    -- Audit
    dwh_load_date           DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT pk_fact_customer_analytics PRIMARY KEY CLUSTERED (customer_analytics_key)
);

CREATE UNIQUE NONCLUSTERED INDEX ix_fact_customer_analytics_customer_snapshot 
    ON gold.fact_customer_analytics(customer_key, snapshot_date);
CREATE NONCLUSTERED INDEX ix_fact_customer_analytics_segment 
    ON gold.fact_customer_analytics(customer_segment) INCLUDE (total_revenue, gross_profit);
CREATE NONCLUSTERED INDEX ix_fact_customer_analytics_rfm 
    ON gold.fact_customer_analytics(rfm_score) INCLUDE (recency, frequency, monetary);
CREATE NONCLUSTERED INDEX ix_fact_customer_analytics_snapshot 
    ON gold.fact_customer_analytics(snapshot_date) INCLUDE (customer_key);

PRINT '✓ Fact_Customer_Analytics created (customer grain - Q1/Q2/Q3 metrics)';
GO

-- =============================================================================
-- FACT_CUSTOMER_COHORT: Cohort Retention & Quality Analysis
-- Source: Analytical SQL Validation - fact_customer_cohort (Q4)
-- Grain: One row per cohort_month × period_number
-- =============================================================================

CREATE TABLE gold.fact_customer_cohort (
    cohort_key              BIGINT IDENTITY(1,1) NOT NULL,
    
    -- Cohort definition
    cohort_month            DATE NOT NULL,
    period_number           INT NOT NULL,
    
    -- =================================================================
    -- Q4: Are newer customer cohorts better or worse?
    -- =================================================================
    -- RETENTION METRICS
    cohort_size             INT NOT NULL,
    active_customers        INT NOT NULL,
    retention_rate          DECIMAL(10,6) NULL,
    
    -- REVENUE METRICS
    cohort_revenue          DECIMAL(18,2) NULL,
    revenue_per_customer    DECIMAL(18,2) NULL,
    
    -- ORDER METRICS
    cohort_orders           INT NULL,
    orders_per_customer     DECIMAL(10,2) NULL,
    
    -- PROFIT METRICS
    cohort_gross_profit     DECIMAL(18,2) NULL,
    gross_profit_per_customer DECIMAL(18,2) NULL,
    
    -- Audit
    dwh_load_date           DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT pk_fact_customer_cohort PRIMARY KEY CLUSTERED (cohort_key)
);

CREATE UNIQUE NONCLUSTERED INDEX ix_fact_customer_cohort_month_period 
    ON gold.fact_customer_cohort(cohort_month, period_number);
CREATE NONCLUSTERED INDEX ix_fact_customer_cohort_month 
    ON gold.fact_customer_cohort(cohort_month) INCLUDE (cohort_size, retention_rate);

PRINT '✓ Fact_Customer_Cohort created (cohort × period grain - Q4 metrics)';
GO

-- =============================================================================
-- FACT_CUSTOMER_BTYD_INPUTS: Predictive Modeling Inputs (Lifetimes Package)
-- Source: Analytical SQL Validation - fact_customer_btyd_inputs (Q5/Q6/Q7)
-- Grain: One row per customer per observation date
-- =============================================================================

CREATE TABLE gold.fact_customer_btyd_inputs (
    btyd_key                BIGINT IDENTITY(1,1) NOT NULL,
    
    -- Dimension foreign key
    customer_key            INT NOT NULL,
    
    -- Observation metadata
    observation_date        DATE NOT NULL,
    duration_holdout        INT NOT NULL,
    
    -- =================================================================
    -- Q5: Who is likely still active vs "dead"?
    -- Q6: What actions should we take? (Prescriptive Foundation)
    -- Q7: What is the value of our overall customer base?
    -- =================================================================
    -- BTYD CORE METRICS (Calibration Period)
    frequency               INT NOT NULL,           -- Repeat purchase count
    recency                 INT NOT NULL,           -- Days between first and last purchase
    T                       INT NOT NULL,           -- Customer age during calibration
    
    -- MONETARY METRICS (Gamma-Gamma Inputs)
    monetary_value          DECIMAL(18,2) NULL,     -- Average monetary value per transaction
    
    -- HOLDOUT VALIDATION METRICS
    frequency_holdout       INT NULL,               -- Actual purchases in holdout period
    
    -- Audit
    dwh_load_date           DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT pk_fact_customer_btyd_inputs PRIMARY KEY CLUSTERED (btyd_key)
);

CREATE UNIQUE NONCLUSTERED INDEX ix_fact_customer_btyd_customer_obs 
    ON gold.fact_customer_btyd_inputs(customer_key, observation_date);
CREATE NONCLUSTERED INDEX ix_fact_customer_btyd_obs 
    ON gold.fact_customer_btyd_inputs(observation_date) INCLUDE (customer_key, frequency, recency, T);

PRINT '✓ Fact_Customer_BTYD_Inputs created (customer grain - Q5/Q6/Q7 metrics)';
GO

-- =============================================================================
-- FACT_SALESREASON: Bridge Table (Many-to-Many: Orders ↔ Sales Reasons)
-- =============================================================================

CREATE TABLE gold.fact_salesreason (
    sales_key               BIGINT NOT NULL,
    salesreason_key         INT NOT NULL,
    dwh_load_date           DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT pk_fact_salesreason PRIMARY KEY CLUSTERED (sales_key, salesreason_key)
);

CREATE NONCLUSTERED INDEX ix_fact_salesreason_reason 
    ON gold.fact_salesreason(salesreason_key);

PRINT '✓ Fact_SalesReason (Bridge) created';
GO

PRINT '';
PRINT '=================================================================================';
PRINT 'Gold Layer Creation Complete!';
PRINT '=================================================================================';
PRINT '';
PRINT 'Schema Summary:';
PRINT '  ✓ 6 Dimensions (all SCD Type 1 - descriptive only)';
PRINT '  ✓ 5 Fact Tables (all metrics from Analytical SQL Validation)';
PRINT '  ✓ No Foreign Key Constraints (ETL-friendly)';
PRINT '';
PRINT 'Fact Tables:';
PRINT '  1. fact_sales                  - Transaction grain';
PRINT '  2. fact_customer_analytics     - Customer grain (Q1/Q2/Q3)';
PRINT '  3. fact_customer_cohort        - Cohort × Period grain (Q4)';
PRINT '  4. fact_customer_btyd_inputs   - Customer grain (Q5/Q6/Q7)';
PRINT '  5. fact_salesreason            - Bridge table';
PRINT '';
PRINT 'Key Features:';
PRINT '  • All analytical metrics from validation queries preserved';
PRINT '  • Dimensions remain descriptive only (no metrics)';
PRINT '  • BTYD-ready predictive modeling inputs';
PRINT '  • Cohort retention analysis support';
PRINT '  • Customer segmentation & RFM analysis';
PRINT '=================================================================================';
GO
