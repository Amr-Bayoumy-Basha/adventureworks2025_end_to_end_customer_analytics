/* 
=================================================================================================

This script is to validate analytical requirements using sql before loading of the gold layer 
and before automation process to ensure that every metric in reliable and relevant the bussiness 
use cases we defined at the begninning of the project 

TARGET: SQL Server (AdventureWorks2025_CustomerDW) | AUTHOR: Amr Bayomei Basha | DATE: Jun 2026 
VERSION: 1.1

=================================================================================================
*/ 

/*
===============================================================================
Silver Layer Validation – Core Sales & Financial Metrics
Grain: Sales Order Detail (Transaction Level)
Purpose: Foundation for Gold Layer (Revenue, Profit, Discount, Volume KPIs)
===============================================================================
*/

-- ===================================================
-- 1- Transactions and sales metrics validation
-- ===================================================


/*
Revenue
Quantity
Number of Orders
Number of Customers
Unit Price
Unit Discount
AverageOrderValue
Average Selling Price
Cost Amount
GrossProfit
Gross Margin
Discount Amount
Discount Rate
*/


SELECT 
    -- =========================
    -- VOLUME METRICS
    -- =========================
    SUM(SOD.linetotal) AS Revenue,
    SUM(SOD.orderqty) AS Quantity,
    COUNT(DISTINCT SOD.salesorder_id) AS NumberOfOrders,
    COUNT(DISTINCT SOH.customer_id) AS NumberOfCustomers,

    -- =========================
    -- PRICE BEHAVIOR
    -- =========================
    AVG(SOD.unitprice) AS AvgUnitPrice,
    AVG(SOD.unitpricediscount) AS AvgUnitDiscount,
    SUM(SOD.unitprice * SOD.orderqty) / NULLIF(SUM(SOD.orderqty), 0) AS AvgSellingPrice,

    -- =========================
    -- COST & PROFITABILITY
    -- =========================
    SUM(SOD.orderqty * PP.standardcost) AS CostAmount,
    SUM(SOD.linetotal) - SUM(SOD.orderqty * PP.standardcost) AS GrossProfit,
    
    (SUM(SOD.linetotal) - SUM(SOD.orderqty * PP.standardcost))
        / NULLIF(SUM(SOD.linetotal), 0) AS GrossMargin,

    -- =========================
    -- DISCOUNT ANALYSIS
    -- =========================
    SUM(SOD.unitpricediscount * SOD.orderqty * SOD.unitprice) AS DiscountAmount,
    
    SUM(SOD.unitpricediscount * SOD.orderqty * SOD.unitprice) 
        / NULLIF(SUM(SOD.linetotal), 0) AS DiscountRate

FROM silver.aw_sales_salesorderdetail AS SOD

INNER JOIN silver.aw_sales_salesorderheader AS SOH
    ON SOD.salesorder_id = SOH.salesorder_id

LEFT JOIN silver.aw_production_product AS PP
    ON SOD.product_id = PP.product_id

group by SOD.salesorder_id, SOD.product_id


-- Agg Results:
/* 
Revenue: 109846381.399888
Quantity: 274914
NumberOfOrders 31465
NumberOfCustomers: 19119
AvgUnitPrice: 465.0934	
AvgUnitDiscount: 0.0028	
AvgSellingPrice: 401.4851	
CostAmount: 100474477.7735	
GrossProfit: 9371903.626388	
GrossMargin: 0.085318	
DiscountAmount: 527507.9262	
DiscountRate: 0.00480223307747976
*/

---------------------------------------------------------------------------------------

/*
===============================================================================
Customer Value Metrics Validation (Silver Layer)
Grain: Customer Level
Purpose: Base dataset for RFM, Pareto, CLV, Gold Layer
===============================================================================
*/


/* NOTE : there are 701 Customers doesnt exist in the person table and dosen't have sales order header record 
and they are not included in the result set because of the left join with the person table 
and sales order header table */
-- NOTE 11649 CUSTOMERS HAVE ONLY 1 PURCHASE AND 7465 CUSTOMERS HAVE MORE THAN 1 PURCHASE 
-- AND 701 CUSTOMERS HAVE NO PURCHASES

-- =========================================
-- 1- fact_customer_analytics
-- =========================================

-- Q1 — Who are our most valuable customers?
/* 
Total Revenue	
Total Orders	
Total Quantity	
Average Order Value	
Gross Profit	
Gross Margin %	
Revenue Contribution %	
Profit Contribution %	
Historical CLV Proxy	
Historical Lifetime Profit 
*/

-- Q2 - Which customers are unprofitable or risky?
/* 
Gross Profit	
Gross Margin % 


-- Q3 — How do customers differ in behavior?

----- Customer Activity & Diversity 

first_order_date
last_order_date
days_since_last_purchase
product_diversity
category_diversity
avg_days_between_purchases 

----- RFM Core 

recency
frequency
monetary
r_score
f_score
m_score
rfm_score
customer_segment
*/


Declare @SnapshotDate DATE = (SELECT MAX(orderdate) FROM silver.aw_sales_salesorderheader);

WITH CustomerMetrics AS (
SELECT 
    C.customer_id,

    -- Total Revenue per Customer
    SUM(SOD.linetotal) AS TotalRevenuePerCustomer,

    -- Total Orders per Customer
    COUNT(DISTINCT SOD.salesorder_id) AS TotalOrdersPerCustomer,

    -- Total Quantity per Customer
    SUM(SOD.orderqty) AS TotalQuantityPerCustomer,

    -- Average Customer Order Value (AOV)
    CASE 
        WHEN COUNT(DISTINCT SOD.salesorder_id) > 0 
        THEN SUM(SOD.linetotal) / COUNT(DISTINCT SOD.salesorder_id)
        ELSE 0
    END AS AverageCustomerOrderValue,

    -- Customer Gross Profit
    SUM(SOD.linetotal) - SUM(SOD.orderqty * PP.standardcost) AS CustomerGrossProfit,

    -- Customer Profit Margin
    CASE 
        WHEN SUM(SOD.linetotal) > 0 
        THEN (SUM(SOD.linetotal) - SUM(SOD.orderqty * PP.standardcost)) 
             / SUM(SOD.linetotal)
        ELSE 0
    END AS CustomerProfitMargin,

    -- Customer Revenue Contribution
    CASE 
        WHEN SUM(SOD.linetotal) > 0 
        THEN SUM(SOD.linetotal) 
             / (SELECT SUM(linetotal) FROM silver.aw_sales_salesorderdetail)
        ELSE 0
    END AS CustomerRevenueContribution,

    -- Customer Profit Contribution
    CASE 
        WHEN SUM(SOD.linetotal) > 0 
        THEN (SUM(SOD.linetotal) - SUM(SOD.orderqty * PP.standardcost))
             / (
                 SELECT SUM(SOD2.linetotal - (SOD2.orderqty * PP2.standardcost))
                 FROM silver.aw_sales_salesorderdetail SOD2
                 INNER JOIN silver.aw_production_product PP2 
                     ON SOD2.product_id = PP2.product_id
             )
        ELSE 0
    END AS CustomerProfitContribution,

    -- Customer Lifetime Value (historical proxy)
    CASE 
        WHEN SUM(SOD.linetotal) > 0 
        THEN SUM(SOD.linetotal) * 1.0
        ELSE 0
    END AS Historical_CLV_Proxy,

    -- Customer Lifetime Profit (historical proxy)
    CASE 
        WHEN SUM(SOD.linetotal) > 0 
        THEN (SUM(SOD.linetotal) - SUM(SOD.orderqty * PP.standardcost)) * 1.0
        ELSE 0
    END AS Historical_Lifetime_Profit,

    -- Customer Activity & Diversity Metrics
    MIN(SOH.orderdate) AS first_order_date,
    MAX(SOH.orderdate) AS last_order_date,
    DATEDIFF(DAY, MAX(SOH.orderdate), @SnapshotDate) AS days_since_last_purchase,
    COUNT(DISTINCT SOD.product_id) AS product_diversity,
    COUNT(DISTINCT PP.productsubcategory_id) AS category_diversity,
   CASE
    WHEN COUNT(DISTINCT CAST(SOH.orderdate AS DATE)) > 1
    THEN
        DATEDIFF(
            DAY,
            MIN(SOH.orderdate),
            MAX(SOH.orderdate)
        ) * 1.0
        /
        (COUNT(DISTINCT CAST(SOH.orderdate AS DATE)) - 1)

    ELSE NULL
END AS avg_days_between_purchases

FROM silver.aw_sales_customer AS C

INNER JOIN silver.aw_sales_salesorderheader AS SOH
    ON C.customer_id = SOH.customer_id

LEFT JOIN silver.aw_sales_salesorderdetail AS SOD
    ON SOH.salesorder_id = SOD.salesorder_id

LEFT JOIN silver.aw_person_person AS P
    ON C.person_id = P.businessentity_id

LEFT JOIN silver.aw_production_product AS PP
    ON SOD.product_id = PP.product_id

GROUP BY 
    C.customer_id
),
rfm_base AS (
SELECT 
    customer_id,
    DATEDIFF(DAY, last_order_date, @SnapshotDate) AS recency,
    TotalOrdersPerCustomer AS frequency,
    AverageCustomerOrderValue AS monetary
    FROM CustomerMetrics
),
rfm_scores AS (
SELECT 
    customer_id,
    recency,
    frequency,
    monetary,
    -- RFM Scoring (1-5)
    6 - NTILE(5) OVER (ORDER BY recency) AS r_score,
    NTILE(5) OVER (ORDER BY frequency ) AS f_score,
    NTILE(5) OVER (ORDER BY monetary) AS m_score
    FROM rfm_base
),
rfm_segments AS (

    SELECT
        customer_id,
        recency,
        frequency,
        monetary,

        r_score,
        f_score,
        m_score,

        CONCAT(r_score, f_score, m_score) AS rfm_score,

        CASE

            -- Best customers
            WHEN r_score = 5
             AND f_score = 5
             AND m_score >= 4
                THEN 'Champions'

            -- Strong repeat customers
            WHEN r_score >= 4
             AND f_score >= 4
             AND m_score >= 4
                THEN 'Loyal Customers'

            -- Recent customers becoming loyal
            WHEN r_score = 5
             AND f_score BETWEEN 3 AND 4
                THEN 'Potential Loyalists'

            -- Very recent but not yet frequent
            WHEN r_score = 5
             AND f_score <= 2
                THEN 'Recent Customers'

            -- Valuable customers starting to disengage
            WHEN r_score BETWEEN 2 AND 3
             AND f_score >= 4
             AND m_score >= 4
                THEN 'Cannot Lose Them'

            -- Mid-range customers needing attention
            WHEN r_score BETWEEN 2 AND 3
             AND f_score BETWEEN 2 AND 3
                THEN 'Needs Attention'

            -- Frequency exists but spend is low
            WHEN f_score >= 3
             AND m_score <= 2
                THEN 'Price Sensitive'

            -- Becoming inactive
            WHEN r_score <= 2
             AND f_score >= 3
                THEN 'About To Sleep'

            -- Long inactive
            WHEN r_score <= 2
             AND f_score <= 2
                THEN 'Hibernating'

            -- Worst customers
            WHEN r_score = 1
             AND f_score = 1
                THEN 'Lost Customers'

            ELSE 'Others'

        END AS customer_segment

    FROM rfm_scores

)
SELECT
    cm.*,
    rs.recency,
    rs.frequency,
    rs.monetary,
    rs.r_score,
    rs.f_score,
    rs.m_score,
    rs.rfm_score,
    rs.customer_segment
from CustomerMetrics cm 
LEFT JOIN rfm_segments rs
    ON cm.customer_id = rs.customer_id

----------------------------------------------------------------------------------------

-- ===========================================
-- 2- fact_customer_cohort
-- ===========================================

-- Q4 — Are newer customer cohorts better or worse?
/*
This fact table tracks customer retention and value
by acquisition cohort over time.

A cohort is defined as the month of a customer's
first purchase.

The objective is to evaluate whether newer customer
groups are improving or deteriorating compared to
earlier cohorts.

-- Cohort Definition Metrics
cohort_month
cohort_size
-- Retention Metrics
active_customers
retention_rate
-- Revenue Metrics
cohort_revenue
revenue_per_customer
-- Order Metrics
cohort_orders
orders_per_customer
-- Time Metrics
period_number
months_since_acquisition
*/
/*
A cohort is defined as the month of a customer’s first purchase
Cohort size is the number of unique customers in that cohort
Active customers are customers who made at least one purchase in a given period after acquisition
Retention rate is active customers divided by cohort size
Cohort revenue is the total revenue generated by the cohort over time
Revenue per customer is cohort revenue divided by active customers
Orders per customer is total orders divided by active customers
Period number represents the number of months since the cohort’s acquisition month
*/

WITH customer_cohort AS (

    SELECT
        customer_id,

        DATEFROMPARTS(
            YEAR(MIN(orderdate)),
            MONTH(MIN(orderdate)),
            1
        ) AS cohort_month

    FROM silver.aw_sales_salesorderheader

    GROUP BY customer_id

),

cohort_orders AS (

    SELECT

        cc.customer_id,
        cc.cohort_month,

        DATEFROMPARTS(
            YEAR(SOH.orderdate),
            MONTH(SOH.orderdate),
            1
        ) AS order_month,

        SOH.salesorder_id,

        SOD.linetotal,

        SOD.orderqty,

        PP.standardcost

    FROM customer_cohort cc

    INNER JOIN silver.aw_sales_salesorderheader SOH
        ON cc.customer_id = SOH.customer_id

    INNER JOIN silver.aw_sales_salesorderdetail SOD
        ON SOH.salesorder_id = SOD.salesorder_id

    LEFT JOIN silver.aw_production_product PP
        ON SOD.product_id = PP.product_id

),

cohort_size AS (

    SELECT

        cohort_month,

        COUNT(DISTINCT customer_id) AS cohort_size

    FROM customer_cohort

    GROUP BY cohort_month

)

SELECT

    co.cohort_month,

    DATEDIFF(
        MONTH,
        co.cohort_month,
        co.order_month
    ) AS period_number,

    cs.cohort_size,

    COUNT(DISTINCT co.customer_id) AS active_customers,

    COUNT(DISTINCT co.customer_id) * 1.0
        / cs.cohort_size AS retention_rate,

    SUM(co.linetotal) AS cohort_revenue,

    SUM(co.linetotal) * 1.0
        / COUNT(DISTINCT co.customer_id)
        AS revenue_per_customer,

    COUNT(DISTINCT co.salesorder_id)
        AS cohort_orders,

    COUNT(DISTINCT co.salesorder_id) * 1.0
        / COUNT(DISTINCT co.customer_id)
        AS orders_per_customer,

    SUM(
        co.linetotal -
        (co.orderqty * co.standardcost)
    ) AS cohort_gross_profit,

    SUM(
        co.linetotal -
        (co.orderqty * co.standardcost)
    ) * 1.0
        / COUNT(DISTINCT co.customer_id)
        AS gross_profit_per_customer

FROM cohort_orders co

INNER JOIN cohort_size cs
    ON co.cohort_month = cs.cohort_month

GROUP BY

    co.cohort_month,

    DATEDIFF(
        MONTH,
        co.cohort_month,
        co.order_month
    ),

    cs.cohort_size

ORDER BY
    co.cohort_month,
    period_number;

-- ===========================================
-- 3- fact_customer_btyd_inputs
-- ===========================================

-- Q5 — Who is likely still active vs "dead"?
/*
This fact table provides the calibration and holdout metrics required
for Buy-Till-You-Die (BTYD) modeling using BG/NBD and Gamma-Gamma models.

The objective is to estimate future customer purchasing behavior,
identify customers likely to remain active, and validate model accuracy
using holdout data.

----- BTYD Core Metrics
frequency -- Repeat purchase count (distinct purchase days - 1)
recency -- Time between first and last purchase
T -- Customer age during calibration period

----- Monetary Metrics (Gamma-Gamma Inputs)
monetary_value -- Average monetary value per transaction

----- Holdout Validation Metrics
frequency_holdout -- Actual purchases observed in holdout period
duration_holdout -- Holdout window length used for validation
*/

-- Q6 — What actions should we take? (Prescriptive Foundation)
/*
This table does not directly answer prescriptive questions.

Instead, it provides the required behavioral inputs used by
BG/NBD and Gamma-Gamma models to generate:

Predicted Future Transactions
Predicted Customer Lifetime Value (CLV)
Expected Future Revenue
Customer Churn Risk

These outputs will later support retention,
marketing, and customer investment decisions.
*/

-- Q7 — What is the value of our overall customer base?
/*
This table serves as the predictive foundation for Customer-Based
Corporate Valuation (CBCV) and Customer Equity calculations.

The BTYD outputs generated from this dataset will later be aggregated
to estimate:

Customer Equity
Average Predicted CLV
Customer Asset Growth
Future Revenue Potential
Customer Portfolio Value

Therefore, this table acts as the behavioral modeling layer
between descriptive customer analytics and enterprise valuation.
*/


DECLARE 
    @observation_date DATE = (SELECT MAX(orderdate) FROM silver.aw_sales_salesorderheader),
    @duration_holdout INT = 90;   -- example: 90‑day holdout window

-----------------------------------------
-- CALIBRATION PERIOD (before holdout)
-----------------------------------------
WITH calibration AS (
    SELECT 
        C.customer_id,
        
        -- Frequency (repeat purchase days)
        COUNT(DISTINCT CONVERT(DATE, SOH.orderdate)) - 1 AS frequency,

        -- Recency (days between first and last purchase)
        DATEDIFF(DAY, MIN(SOH.orderdate), MAX(SOH.orderdate)) AS recency,

        -- T (customer age at end of calibration)
        DATEDIFF(
            DAY, 
            MIN(SOH.orderdate), 
            DATEADD(DAY, -@duration_holdout, @observation_date)
        ) AS T,

        -- Monetary value (Gamma-Gamma input)
        SUM(SOD.linetotal) / COUNT(DISTINCT SOH.salesorder_id) AS monetary_value

    FROM silver.aw_sales_salesorderdetail SOD
    INNER JOIN silver.aw_sales_salesorderheader SOH
        ON SOD.salesorder_id = SOH.salesorder_id
    LEFT JOIN silver.aw_sales_customer C
        ON SOH.customer_id = C.customer_id
    LEFT JOIN silver.aw_person_person P
        ON C.person_id = P.businessentity_id
    WHERE SOH.orderdate < DATEADD(DAY, -@duration_holdout, @observation_date)
    GROUP BY 
        C.customer_id

),

-----------------------------------------
-- HOLDOUT PERIOD (after calibration)
-----------------------------------------
holdout AS (
    SELECT
        C.customer_id,
        COUNT(DISTINCT CONVERT(DATE, SOH.orderdate)) AS frequency_holdout
    FROM silver.aw_sales_salesorderheader SOH
    LEFT JOIN silver.aw_sales_customer C
        ON SOH.customer_id = C.customer_id
    WHERE 
        SOH.orderdate >= DATEADD(DAY, -@duration_holdout, @observation_date)
        AND SOH.orderdate <= @observation_date
    GROUP BY C.customer_id
)

-----------------------------------------
-- FINAL MERGE
-----------------------------------------

SELECT 
    cal.*,
    frequency_holdout,
    @duration_holdout AS duration_holdout
FROM calibration AS cal 
LEFT JOIN holdout h ON cal.customer_id = h.customer_id 









