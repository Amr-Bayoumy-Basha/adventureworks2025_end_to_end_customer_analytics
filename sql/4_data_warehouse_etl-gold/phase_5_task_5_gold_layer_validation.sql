/*
=================================================================================
Gold Layer Validation Script v3.0 - Silver → Gold Load Verification
=================================================================================
PURPOSE:
Validates the complete Gold Layer ETL v3.0 including all 5 fact tables.

CHECKS:
  1. Row count comparison (silver source vs gold target)
  2. NULL checks on critical NOT NULL columns
  3. Orphaned foreign key checks (referential integrity)
  4. Duplicate key checks
  5. fact_customer_analytics business rules
  6. fact_customer_cohort business rules
  7. fact_customer_btyd_inputs (BTYD) business rules
  8. fact_sales financial sanity
  9. Customer segment distribution

Expected result: ALL violation_count / orphan_count values = 0

AUTHOR: Amr Bayomei Basha (Enhanced by Copilot)
DATE: Jun 2026 
=================================================================================
*/

USE AdventureWorks2025_CustomerDW;
GO

DECLARE @ObservationEndDate DATE;
SELECT @ObservationEndDate = MAX(orderdate) FROM silver.aw_sales_salesorderheader;

PRINT '=================================================================================';
PRINT 'Gold Layer Validation v3.0';
PRINT 'Observation Date: ' + CONVERT(VARCHAR(10), @ObservationEndDate, 120);
PRINT '=================================================================================';
PRINT '';

-- ============================================================
-- CHECK 1: Row Count Comparison
-- ============================================================
PRINT 'CHECK 1: Row Count Comparison';

SELECT 'dim_territory' AS gold_table, COUNT(*) AS gold_rows,
       (SELECT COUNT(*) FROM silver.aw_sales_salesterritory) AS silver_rows,
       COUNT(*) - (SELECT COUNT(*) FROM silver.aw_sales_salesterritory) AS diff
FROM gold.dim_territory
UNION ALL
SELECT 'dim_product', COUNT(*),
       (SELECT COUNT(*) FROM silver.aw_production_product),
       COUNT(*) - (SELECT COUNT(*) FROM silver.aw_production_product)
FROM gold.dim_product
UNION ALL
SELECT 'dim_specialoffer', COUNT(*),
       (SELECT COUNT(*) FROM silver.aw_sales_specialoffer),
       COUNT(*) - (SELECT COUNT(*) FROM silver.aw_sales_specialoffer)
FROM gold.dim_specialoffer
UNION ALL
SELECT 'dim_salesreason', COUNT(*),
       (SELECT COUNT(*) FROM silver.aw_sales_salesreason),
       COUNT(*) - (SELECT COUNT(*) FROM silver.aw_sales_salesreason)
FROM gold.dim_salesreason
UNION ALL
SELECT 'dim_customer', COUNT(*),
       (SELECT COUNT(*) FROM silver.aw_sales_customer),
       COUNT(*) - (SELECT COUNT(*) FROM silver.aw_sales_customer)
FROM gold.dim_customer
UNION ALL
SELECT 'fact_sales', COUNT(*),
       (SELECT COUNT(*) FROM silver.aw_sales_salesorderdetail),
       COUNT(*) - (SELECT COUNT(*) FROM silver.aw_sales_salesorderdetail)
FROM gold.fact_sales
UNION ALL
SELECT 'fact_salesreason', COUNT(*),
       (SELECT COUNT(*) FROM silver.aw_sales_salesorderheadersalesreason),
       COUNT(*) - (SELECT COUNT(*) FROM silver.aw_sales_salesorderheadersalesreason)
FROM gold.fact_salesreason
UNION ALL
SELECT 'fact_customer_analytics', COUNT(*),
       (SELECT COUNT(DISTINCT customer_id) FROM silver.aw_sales_customer),
       COUNT(*) - (SELECT COUNT(DISTINCT customer_id) FROM silver.aw_sales_customer)
FROM gold.fact_customer_analytics
UNION ALL
SELECT 'fact_customer_cohort', COUNT(*), NULL AS silver_rows, NULL AS diff
FROM gold.fact_customer_cohort
UNION ALL
SELECT 'fact_customer_btyd_inputs', COUNT(*), NULL, NULL
FROM gold.fact_customer_btyd_inputs;

PRINT '';

-- ============================================================
-- CHECK 2: NULL Checks on Critical Columns
-- ============================================================
PRINT 'CHECK 2: NULL Checks on Critical Columns';

SELECT 'fact_sales - NULL customer_key' AS check_name, COUNT(*) AS violation_count 
FROM gold.fact_sales WHERE customer_key IS NULL
UNION ALL
SELECT 'fact_sales - NULL product_key', COUNT(*) 
FROM gold.fact_sales WHERE product_key IS NULL
UNION ALL
SELECT 'fact_sales - NULL territory_key', COUNT(*) 
FROM gold.fact_sales WHERE territory_key IS NULL
UNION ALL
SELECT 'fact_sales - NULL specialoffer_key', COUNT(*) 
FROM gold.fact_sales WHERE specialoffer_key IS NULL
UNION ALL
SELECT 'fact_sales - NULL order_date_key', COUNT(*) 
FROM gold.fact_sales WHERE order_date_key IS NULL
UNION ALL
SELECT 'fact_sales - NULL due_date_key', COUNT(*) 
FROM gold.fact_sales WHERE due_date_key IS NULL
UNION ALL
SELECT 'fact_customer_analytics - NULL customer_key', COUNT(*) 
FROM gold.fact_customer_analytics WHERE customer_key IS NULL
UNION ALL
SELECT 'fact_customer_analytics - NULL snapshot_date', COUNT(*) 
FROM gold.fact_customer_analytics WHERE snapshot_date IS NULL
UNION ALL
SELECT 'fact_customer_analytics - NULL rfm_score', COUNT(*) 
FROM gold.fact_customer_analytics WHERE rfm_score IS NULL
UNION ALL
SELECT 'fact_customer_analytics - NULL customer_segment', COUNT(*) 
FROM gold.fact_customer_analytics WHERE customer_segment IS NULL
UNION ALL
SELECT 'fact_customer_cohort - NULL cohort_month', COUNT(*) 
FROM gold.fact_customer_cohort WHERE cohort_month IS NULL
UNION ALL
SELECT 'fact_customer_btyd_inputs - NULL customer_key', COUNT(*) 
FROM gold.fact_customer_btyd_inputs WHERE customer_key IS NULL;

PRINT '';

-- ============================================================
-- CHECK 3: Orphaned Foreign Keys
-- ============================================================
PRINT 'CHECK 3: Orphaned Foreign Key Checks';

SELECT 'fact_sales → dim_customer' AS check_name, COUNT(*) AS orphan_count
FROM gold.fact_sales fs
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_customer dc WHERE dc.customer_key = fs.customer_key)
UNION ALL
SELECT 'fact_sales → dim_product', COUNT(*)
FROM gold.fact_sales fs
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_product dp WHERE dp.product_key = fs.product_key)
UNION ALL
SELECT 'fact_sales → dim_territory', COUNT(*)
FROM gold.fact_sales fs
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_territory dt WHERE dt.territory_key = fs.territory_key)
UNION ALL
SELECT 'fact_sales → dim_specialoffer', COUNT(*)
FROM gold.fact_sales fs
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_specialoffer ds WHERE ds.specialoffer_key = fs.specialoffer_key)
UNION ALL
SELECT 'fact_salesreason → fact_sales', COUNT(*)
FROM gold.fact_salesreason fsr
WHERE NOT EXISTS (SELECT 1 FROM gold.fact_sales fs WHERE fs.sales_key = fsr.sales_key)
UNION ALL
SELECT 'fact_salesreason → dim_salesreason', COUNT(*)
FROM gold.fact_salesreason fsr
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_salesreason dr WHERE dr.salesreason_key = fsr.salesreason_key)
UNION ALL
SELECT 'fact_customer_analytics → dim_customer', COUNT(*)
FROM gold.fact_customer_analytics fca
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_customer dc WHERE dc.customer_key = fca.customer_key)
UNION ALL
SELECT 'fact_customer_btyd_inputs → dim_customer', COUNT(*)
FROM gold.fact_customer_btyd_inputs fbi
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_customer dc WHERE dc.customer_key = fbi.customer_key);

PRINT '';

-- ============================================================
-- CHECK 4: Duplicate Key Checks
-- ============================================================
PRINT 'CHECK 4: Duplicate Key Checks';

SELECT 'dim_territory - duplicate territory_id' AS check_name, COUNT(*) AS duplicate_count
FROM (SELECT territory_id FROM gold.dim_territory GROUP BY territory_id HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'dim_product - duplicate product_id', COUNT(*)
FROM (SELECT product_id FROM gold.dim_product GROUP BY product_id HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'dim_customer - duplicate customer_id', COUNT(*)
FROM (SELECT customer_id FROM gold.dim_customer GROUP BY customer_id HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'dim_specialoffer - duplicate specialoffer_id', COUNT(*)
FROM (SELECT specialoffer_id FROM gold.dim_specialoffer GROUP BY specialoffer_id HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'dim_salesreason - duplicate salesreason_id', COUNT(*)
FROM (SELECT salesreason_id FROM gold.dim_salesreason GROUP BY salesreason_id HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'fact_sales - duplicate (salesorder_id + salesorderdetail_id)', COUNT(*)
FROM (SELECT salesorder_id, salesorderdetail_id FROM gold.fact_sales GROUP BY salesorder_id, salesorderdetail_id HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'fact_customer_analytics - duplicate (customer_key + snapshot_date)', COUNT(*)
FROM (SELECT customer_key, snapshot_date FROM gold.fact_customer_analytics GROUP BY customer_key, snapshot_date HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'fact_customer_cohort - duplicate (cohort_month + period_number)', COUNT(*)
FROM (SELECT cohort_month, period_number FROM gold.fact_customer_cohort GROUP BY cohort_month, period_number HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'fact_customer_btyd_inputs - duplicate (customer_key + observation_date)', COUNT(*)
FROM (SELECT customer_key, observation_date FROM gold.fact_customer_btyd_inputs GROUP BY customer_key, observation_date HAVING COUNT(*) > 1) x;

PRINT '';

-- ============================================================
-- CHECK 5: fact_customer_analytics Business Rules
-- ============================================================
PRINT 'CHECK 5: fact_customer_analytics Business Rules';

SELECT 'analytics - total_revenue < 0' AS check_name, COUNT(*) AS violation_count 
FROM gold.fact_customer_analytics WHERE total_revenue < 0
UNION ALL
SELECT 'analytics - total_orders <= 0', COUNT(*) 
FROM gold.fact_customer_analytics WHERE total_orders <= 0
UNION ALL
SELECT 'analytics - total_quantity < 0', COUNT(*) 
FROM gold.fact_customer_analytics WHERE total_quantity < 0
UNION ALL
SELECT 'analytics - avg_order_value < 0', COUNT(*) 
FROM gold.fact_customer_analytics WHERE avg_order_value < 0
UNION ALL
SELECT 'analytics - recency < 0', COUNT(*) 
FROM gold.fact_customer_analytics WHERE recency < 0
UNION ALL
SELECT 'analytics - frequency < 0', COUNT(*) 
FROM gold.fact_customer_analytics WHERE frequency < 0
UNION ALL
SELECT 'analytics - monetary <= 0', COUNT(*) 
FROM gold.fact_customer_analytics WHERE monetary <= 0
UNION ALL
SELECT 'analytics - r_score out of range 1-5', COUNT(*) 
FROM gold.fact_customer_analytics WHERE r_score NOT BETWEEN 1 AND 5
UNION ALL
SELECT 'analytics - f_score out of range 1-5', COUNT(*) 
FROM gold.fact_customer_analytics WHERE f_score NOT BETWEEN 1 AND 5
UNION ALL
SELECT 'analytics - m_score out of range 1-5', COUNT(*) 
FROM gold.fact_customer_analytics WHERE m_score NOT BETWEEN 1 AND 5
UNION ALL
SELECT 'analytics - rfm_score length != 3', COUNT(*) 
FROM gold.fact_customer_analytics WHERE LEN(rfm_score) != 3
UNION ALL
SELECT 'analytics - last_order_date < first_order_date', COUNT(*) 
FROM gold.fact_customer_analytics WHERE last_order_date < first_order_date;

PRINT '';

-- ============================================================
-- CHECK 6: fact_customer_cohort Business Rules
-- ============================================================
PRINT 'CHECK 6: fact_customer_cohort Business Rules';

SELECT 'cohort - cohort_size <= 0' AS check_name, COUNT(*) AS violation_count 
FROM gold.fact_customer_cohort WHERE cohort_size <= 0
UNION ALL
SELECT 'cohort - active_customers > cohort_size', COUNT(*) 
FROM gold.fact_customer_cohort WHERE active_customers > cohort_size
UNION ALL
SELECT 'cohort - retention_rate < 0', COUNT(*) 
FROM gold.fact_customer_cohort WHERE retention_rate < 0
UNION ALL
SELECT 'cohort - retention_rate > 1', COUNT(*) 
FROM gold.fact_customer_cohort WHERE retention_rate > 1
UNION ALL
SELECT 'cohort - cohort_revenue < 0', COUNT(*) 
FROM gold.fact_customer_cohort WHERE cohort_revenue < 0
UNION ALL
SELECT 'cohort - period_number < 0', COUNT(*) 
FROM gold.fact_customer_cohort WHERE period_number < 0;

PRINT '';

-- ============================================================
-- CHECK 7: fact_customer_btyd_inputs (BTYD) Business Rules
-- ============================================================
PRINT 'CHECK 7: fact_customer_btyd_inputs (BTYD) Business Rules';

SELECT 'btyd - frequency < 0' AS check_name, COUNT(*) AS violation_count 
FROM gold.fact_customer_btyd_inputs WHERE frequency < 0
UNION ALL
SELECT 'btyd - recency < 0', COUNT(*) 
FROM gold.fact_customer_btyd_inputs WHERE recency < 0
UNION ALL
SELECT 'btyd - T < 0', COUNT(*) 
FROM gold.fact_customer_btyd_inputs WHERE T < 0
UNION ALL
SELECT 'btyd - T < recency', COUNT(*) 
FROM gold.fact_customer_btyd_inputs WHERE T < recency
UNION ALL
SELECT 'btyd - monetary_value <= 0', COUNT(*) 
FROM gold.fact_customer_btyd_inputs WHERE monetary_value <= 0
UNION ALL
SELECT 'btyd - frequency_holdout < 0', COUNT(*) 
FROM gold.fact_customer_btyd_inputs WHERE frequency_holdout < 0
UNION ALL
SELECT 'btyd - duration_holdout <= 0', COUNT(*) 
FROM gold.fact_customer_btyd_inputs WHERE duration_holdout <= 0;

PRINT '';

-- ============================================================
-- CHECK 8: fact_sales Financial Sanity
-- ============================================================
PRINT 'CHECK 8: fact_sales Financial Sanity';

SELECT 'fact_sales - line_total <= 0' AS check_name, COUNT(*) AS violation_count 
FROM gold.fact_sales WHERE line_total <= 0
UNION ALL
SELECT 'fact_sales - unit_price <= 0', COUNT(*) 
FROM gold.fact_sales WHERE unit_price <= 0
UNION ALL
SELECT 'fact_sales - order_quantity <= 0', COUNT(*) 
FROM gold.fact_sales WHERE order_quantity <= 0
UNION ALL
SELECT 'fact_sales - discount_amount < 0', COUNT(*) 
FROM gold.fact_sales WHERE discount_amount < 0
UNION ALL
SELECT 'fact_sales - ship_date_key < order_date_key', COUNT(*) 
FROM gold.fact_sales WHERE ship_date_key IS NOT NULL AND ship_date_key < order_date_key
UNION ALL
SELECT 'fact_sales - due_date_key < order_date_key', COUNT(*) 
FROM gold.fact_sales WHERE due_date_key < order_date_key
UNION ALL
SELECT 'fact_sales - cost_amount < 0', COUNT(*) 
FROM gold.fact_sales WHERE cost_amount < 0
UNION ALL
SELECT 'fact_sales - gross_profit != line_total - cost_amount (tolerance ±0.01)', COUNT(*)
FROM gold.fact_sales WHERE ABS(gross_profit - (line_total - cost_amount)) > 0.01;

PRINT '';

-- ============================================================
-- CHECK 9: Customer Segment Distribution (Informational)
-- ============================================================
PRINT 'CHECK 9: Customer Segment Distribution';

SELECT customer_segment, COUNT(*) AS customer_count,
       CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS pct_of_total
FROM gold.fact_customer_analytics
GROUP BY customer_segment
ORDER BY customer_count DESC;

PRINT '';
PRINT '=================================================================================';
PRINT 'Gold Layer Validation v3.0 Complete';
PRINT '=================================================================================';
GO
