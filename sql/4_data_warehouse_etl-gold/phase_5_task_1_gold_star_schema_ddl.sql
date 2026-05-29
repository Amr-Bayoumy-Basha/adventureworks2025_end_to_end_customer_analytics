/*
=================================================================================
Gold Layer - Star Schema DDL (FINAL VERSION - SCD Type 1 - No FK Constraints)
=================================================================================
Features:
1. SCD Type 1 for all dimensions (overwrite changes)
2. Role-playing dates in Fact_Sales (order/due/ship)
3. Currency support (code + exchange rate)
4. BTYD-ready RFM metrics
5. NO foreign key constraints (for easier data loading)
6. Pareto analysis columns on dim_customer (qty + revenue based)

TARGET: SQL Server (AdventureWorks2025_CustomerDW) | AUTHOR: Amr Bayomei Basha | DATE: May 2026
VERSION: 1.1

=================================================================================
*/

USE AdventureWorks2025_CustomerDW;
GO

-- =================================================================================
-- DROP EXISTING TABLES (IN DEPENDENCY ORDER)
-- =================================================================================

IF OBJECT_ID('gold.fact_salesreason', 'U') IS NOT NULL DROP TABLE gold.fact_salesreason;
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
PRINT 'Creating Gold Layer Dimension Tables (SCD Type 1)';
PRINT '=================================================================================';
PRINT '';

-- =================================================================================
-- DIM_DATE: Standard Date Dimension
-- =================================================================================

CREATE TABLE gold.dim_date (
    date_key                INT NOT NULL,           -- YYYYMMDD format
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

-- =================================================================================
-- DIM_TERRITORY: Sales Territory Dimension (SCD Type 1)
-- =================================================================================

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

-- =================================================================================
-- DIM_PRODUCT: Product Dimension (SCD Type 1)
-- =================================================================================

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

-- =================================================================================
-- DIM_CUSTOMER: Customer Dimension (SCD Type 1 - Overwrites)
-- =================================================================================

CREATE TABLE gold.dim_customer (
    customer_key            INT IDENTITY(1,1) NOT NULL,
    customer_id             INT NOT NULL,
    
    -- Person information
    person_id               INT NULL,
    customer_name           NVARCHAR(200) NULL,
    person_type             NVARCHAR(2) NULL,
    
    -- Contact information
    email_address           NVARCHAR(100) NULL,
    
    -- Address information (denormalized - current address only)
    address_line1           NVARCHAR(100) NULL,
    address_line2           NVARCHAR(100) NULL,
    city                    NVARCHAR(50) NULL,
    state_province          NVARCHAR(50) NULL,
    country                 NVARCHAR(50) NULL,
    postal_code             NVARCHAR(20) NULL,
    
    -- Territory (current assignment)
    territory_name          NVARCHAR(50) NULL,
    territory_key           INT NULL,
    
    -- Customer metrics (SCD Type 1 - updated)
    first_order_date        DATE NULL,
    last_order_date         DATE NULL,
    total_orders            INT NULL DEFAULT 0,
    lifetime_value          DECIMAL(18,2) NULL DEFAULT 0,
    
    -- Pareto analysis - Revenue based
    -- Populated by ETL after fact_sales is loaded
    revenue_cumulative      DECIMAL(18,2) NULL,         -- Running total of revenue (desc rank)
    revenue_pareto_pct      DECIMAL(7,4) NULL,          -- Cumulative revenue % of grand total

    -- Pareto analysis - Quantity based
    qty_cumulative          BIGINT NULL,                -- Running total of qty (desc rank)
    qty_pareto_pct          DECIMAL(7,4) NULL,          -- Cumulative qty % of grand total

    -- Status
    is_active               BIT NOT NULL DEFAULT 1,
    
    -- Audit
    dwh_load_date           DATETIME NOT NULL DEFAULT GETDATE(),
    dwh_update_date         DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT pk_dim_customer PRIMARY KEY CLUSTERED (customer_key)
);

CREATE UNIQUE NONCLUSTERED INDEX ix_dim_customer_id ON gold.dim_customer(customer_id);
CREATE NONCLUSTERED INDEX ix_dim_customer_territory ON gold.dim_customer(territory_key);
CREATE NONCLUSTERED INDEX ix_dim_customer_person ON gold.dim_customer(person_id) WHERE person_id IS NOT NULL;
CREATE NONCLUSTERED INDEX ix_dim_customer_pareto ON gold.dim_customer(revenue_pareto_pct, qty_pareto_pct);

PRINT '✓ Dim_Customer created (SCD Type 1 + Pareto columns)';
GO

-- =================================================================================
-- DIM_SPECIALOFFER: Special Offer Dimension (SCD Type 1)
-- =================================================================================

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

-- =================================================================================
-- DIM_SALESREASON: Sales Reason Dimension
-- =================================================================================

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
PRINT 'Creating Gold Layer Fact Tables';
PRINT '=================================================================================';
PRINT '';

-- =================================================================================
-- FACT_SALES: Main Sales Fact Table (NO FK CONSTRAINTS)
-- =================================================================================

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
    
    -- Measures - Quantities
    order_quantity          INT NOT NULL,
    
    -- Currency support
    currency_code           CHAR(3) NOT NULL DEFAULT 'USD',
    exchange_rate           DECIMAL(10,6) NULL DEFAULT 1.0,
    
    -- Measures - Amounts (in transaction currency)
    unit_price              DECIMAL(18,2) NOT NULL,
    unit_discount           DECIMAL(18,2) NOT NULL DEFAULT 0,
    line_total              DECIMAL(18,2) NOT NULL,
    discount_amount         DECIMAL(18,2) NOT NULL DEFAULT 0,
    cost_amount             DECIMAL(18,2) NOT NULL DEFAULT 0,
    -- gross_profit = revenue (line_total) - COGS (cost_amount)
    gross_profit            DECIMAL(18,2) NOT NULL DEFAULT 0,
    
    -- Base currency amounts (for cross-currency aggregation)
    line_total_base         AS (line_total * exchange_rate) PERSISTED,
    gross_profit_base       AS (gross_profit * exchange_rate) PERSISTED,
    
    -- Order-level attributes
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
    ON gold.fact_sales(order_date_key) INCLUDE (line_total, order_quantity);
CREATE NONCLUSTERED INDEX ix_fact_sales_ship_date 
    ON gold.fact_sales(ship_date_key) INCLUDE (line_total) WHERE ship_date_key IS NOT NULL;
CREATE NONCLUSTERED INDEX ix_fact_sales_customer 
    ON gold.fact_sales(customer_key) INCLUDE (line_total, order_quantity, gross_profit);
CREATE NONCLUSTERED INDEX ix_fact_sales_product 
    ON gold.fact_sales(product_key) INCLUDE (line_total, order_quantity);
CREATE NONCLUSTERED INDEX ix_fact_sales_territory 
    ON gold.fact_sales(territory_key) INCLUDE (line_total);
CREATE UNIQUE NONCLUSTERED INDEX ix_fact_sales_natural_key 
    ON gold.fact_sales(salesorder_id, salesorderdetail_id);

PRINT '✓ Fact_Sales created (gross_profit = revenue - COGS, no FK constraints)';
GO

-- =================================================================================
-- FACT_SALESREASON: Bridge Table (NO FK CONSTRAINTS)
-- =================================================================================

CREATE TABLE gold.fact_salesreason (
    sales_key               BIGINT NOT NULL,
    salesreason_key         INT NOT NULL,
    dwh_load_date           DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT pk_fact_salesreason PRIMARY KEY CLUSTERED (sales_key, salesreason_key)
);

PRINT '✓ Fact_SalesReason (Bridge) created (without FK constraints)';
GO

-- =================================================================================
-- FACT_CUSTOMER_RFM: Analytical Snapshot for BTYD Model (NO FK CONSTRAINTS)
-- =================================================================================

CREATE TABLE gold.fact_customer_rfm (
    rfm_key                 BIGINT IDENTITY(1,1) NOT NULL,
    customer_key            INT NOT NULL,
    snapshot_date           DATE NOT NULL,
    
    -- BTYD-compliant metrics
    recency                 INT NOT NULL,                   -- Days between first and last purchase
    frequency               INT NOT NULL,                   -- Number of REPEAT purchases (n-1)
    T                       INT NOT NULL,                   -- Customer age (first purchase to snapshot)
    monetary_value          DECIMAL(18,2) NOT NULL,         -- Avg order value
    
    -- Supporting metrics
    total_revenue           DECIMAL(18,2) NOT NULL,
    total_orders            INT NOT NULL,
    avg_order_value         DECIMAL(18,2) NULL,
    total_quantity          INT NULL,
    
    -- Key dates
    first_order_date        DATE NOT NULL,
    last_order_date         DATE NOT NULL,
    
    -- Behavioral metrics
    days_between_orders     DECIMAL(10,2) NULL,
    
    -- RFM Scores (1-5)
    r_score                 INT NULL,
    f_score                 INT NULL,
    m_score                 INT NULL,
    rfm_score               VARCHAR(3) NULL,
    
    -- Segmentation
    customer_segment        VARCHAR(20) NULL,
    
    -- Predictive (placeholder for Python output)
    clv_estimate            DECIMAL(18,2) NULL,
    churn_probability       DECIMAL(5,4) NULL,
    predicted_purchases_90d INT NULL,
    
    -- Status
    is_active               BIT NOT NULL,
    
    -- Audit
    dwh_load_date           DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT pk_fact_customer_rfm PRIMARY KEY CLUSTERED (rfm_key)
);

CREATE UNIQUE NONCLUSTERED INDEX ix_fact_customer_rfm_snapshot 
    ON gold.fact_customer_rfm(customer_key, snapshot_date);
CREATE NONCLUSTERED INDEX ix_fact_customer_rfm_segment 
    ON gold.fact_customer_rfm(customer_segment) INCLUDE (recency, frequency, monetary_value);
CREATE NONCLUSTERED INDEX ix_fact_customer_rfm_date 
    ON gold.fact_customer_rfm(snapshot_date) INCLUDE (customer_key, rfm_score);

PRINT '✓ Fact_CustomerRFM created (without FK constraints)';
GO

PRINT '';
PRINT '=================================================================================';
PRINT 'Gold Layer Creation Complete!';
PRINT '=================================================================================';
PRINT '';
PRINT 'Schema Summary:';
PRINT '  ✓ 6 Dimensions (all SCD Type 1)';
PRINT '  ✓ 1 Fact Table with 3 date roles';
PRINT '  ✓ 1 Bridge Table';
PRINT '  ✓ 1 Analytical Fact (BTYD-ready)';
PRINT '  ✓ Currency support enabled';
PRINT '  ✓ Role-playing dates configured';
PRINT '  ✓ NO foreign key constraints (for easier data loading)';
PRINT '';
PRINT 'Key Features:';
PRINT '  • SCD Type 1: Simple overwrites (no history)';
PRINT '  • Role-playing dates: order/due/ship';
PRINT '  • Currency: code + exchange rate + base amounts';
PRINT '  • BTYD: recency, frequency, T, monetary_value';
PRINT '  • Gross Profit = Revenue - COGS (standard_cost * qty)';
PRINT '  • Pareto columns on dim_customer: revenue + qty based';
PRINT '  • No FK constraints: Allows TRUNCATE and faster loads';
PRINT '=================================================================================';
GO
