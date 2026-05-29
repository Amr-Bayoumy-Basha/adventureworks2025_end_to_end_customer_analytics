/*
=================================================================================
Gold Layer Validation Script - Silver → Gold Load Verification
=================================================================================
Checks:
  1. Row count comparison (silver source vs gold target)
  2. NULL checks on critical NOT NULL columns
  3. Orphaned foreign key checks (referential integrity)
  4. Duplicate key checks
  5. RFM BTYD business rules
  6. fact_sales financial sanity
  7. dim_customer metrics consistency
  8. Customer segment distribution
=================================================================================
Expected result for checks 1-7: ALL violation_count / orphan_count values = 0
=================================================================================

Created By Amr Bayomei Basha | Date May-26
*/

-- ============================================================
-- CHECK 1: Row Count Comparison — Silver Source vs Gold Target
-- ============================================================
-- NOTE: dim_customer diff may be non-zero if customers have no person record;
--       fact_customer_rfm diff may be non-zero for customers with no orders.

-- ============================================================
PRINT 'CHECK 1: Row Count Comparison';

SELECT 'dim_territory'      AS gold_table,
       COUNT(*)              AS gold_rows,
       (SELECT COUNT(*) FROM silver.aw_sales_salesterritory) AS silver_rows,
       COUNT(*) - (SELECT COUNT(*) FROM silver.aw_sales_salesterritory) AS diff
FROM gold.dim_territory
UNION ALL
SELECT 'dim_product',
       COUNT(*),
       (SELECT COUNT(*) FROM silver.aw_production_product),
       COUNT(*) - (SELECT COUNT(*) FROM silver.aw_production_product)
FROM gold.dim_product
UNION ALL
SELECT 'dim_specialoffer',
       COUNT(*),
       (SELECT COUNT(*) FROM silver.aw_sales_specialoffer),
       COUNT(*) - (SELECT COUNT(*) FROM silver.aw_sales_specialoffer)
FROM gold.dim_specialoffer
UNION ALL
SELECT 'dim_salesreason',
       COUNT(*),
       (SELECT COUNT(*) FROM silver.aw_sales_salesreason),
       COUNT(*) - (SELECT COUNT(*) FROM silver.aw_sales_salesreason)
FROM gold.dim_salesreason
UNION ALL
SELECT 'dim_customer',
       COUNT(*),
       (SELECT COUNT(*) FROM silver.aw_sales_customer),
       COUNT(*) - (SELECT COUNT(*) FROM silver.aw_sales_customer)
FROM gold.dim_customer
UNION ALL
SELECT 'fact_sales',
       COUNT(*),
       (SELECT COUNT(*) FROM silver.aw_sales_salesorderdetail),
       COUNT(*) - (SELECT COUNT(*) FROM silver.aw_sales_salesorderdetail)
FROM gold.fact_sales
UNION ALL
SELECT 'fact_salesreason',
       COUNT(*),
       (SELECT COUNT(*) FROM silver.aw_sales_salesorderheadersalesreason),
       COUNT(*) - (SELECT COUNT(*) FROM silver.aw_sales_salesorderheadersalesreason)
FROM gold.fact_salesreason
UNION ALL
SELECT 'fact_customer_rfm',
       COUNT(*),
       (SELECT COUNT(DISTINCT customer_id) FROM silver.aw_sales_customer),
       COUNT(*) - (SELECT COUNT(DISTINCT customer_id) FROM silver.aw_sales_customer)
FROM gold.fact_customer_rfm;

-- ============================================================
-- CHECK 2: NULL Checks on Critical Columns
-- ============================================================
-- Expected: ALL violation_count = 0
-- ============================================================
PRINT 'CHECK 2: NULL Checks on Critical Columns';

SELECT 'fact_sales - NULL customer_key'          AS check_name, COUNT(*) AS violation_count FROM gold.fact_sales WHERE customer_key IS NULL
UNION ALL
SELECT 'fact_sales - NULL product_key',          COUNT(*) FROM gold.fact_sales WHERE product_key IS NULL
UNION ALL
SELECT 'fact_sales - NULL territory_key',        COUNT(*) FROM gold.fact_sales WHERE territory_key IS NULL
UNION ALL
SELECT 'fact_sales - NULL specialoffer_key',     COUNT(*) FROM gold.fact_sales WHERE specialoffer_key IS NULL
UNION ALL
SELECT 'fact_sales - NULL order_date_key',       COUNT(*) FROM gold.fact_sales WHERE order_date_key IS NULL
UNION ALL
SELECT 'fact_sales - NULL due_date_key',         COUNT(*) FROM gold.fact_sales WHERE due_date_key IS NULL
UNION ALL
SELECT 'dim_customer - NULL customer_name',      COUNT(*) FROM gold.dim_customer WHERE customer_name IS NULL
UNION ALL
SELECT 'dim_customer - NULL territory_key',      COUNT(*) FROM gold.dim_customer WHERE territory_key IS NULL
UNION ALL
SELECT 'fact_customer_rfm - NULL rfm_score',     COUNT(*) FROM gold.fact_customer_rfm WHERE rfm_score IS NULL
UNION ALL
SELECT 'fact_customer_rfm - NULL customer_segment', COUNT(*) FROM gold.fact_customer_rfm WHERE customer_segment IS NULL;

-- ============================================================
-- CHECK 3: Orphaned Foreign Keys (Referential Integrity)
-- ============================================================
-- Expected: ALL orphan_count = 0
-- ============================================================
PRINT 'CHECK 3: Orphaned Foreign Key Checks';

SELECT 'fact_sales → dim_customer (orphaned customer_key)'          AS check_name, COUNT(*) AS orphan_count
FROM gold.fact_sales fs
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_customer dc WHERE dc.customer_key = fs.customer_key)
UNION ALL
SELECT 'fact_sales → dim_product (orphaned product_key)',           COUNT(*)
FROM gold.fact_sales fs
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_product dp WHERE dp.product_key = fs.product_key)
UNION ALL
SELECT 'fact_sales → dim_territory (orphaned territory_key)',       COUNT(*)
FROM gold.fact_sales fs
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_territory dt WHERE dt.territory_key = fs.territory_key)
UNION ALL
SELECT 'fact_sales → dim_specialoffer (orphaned specialoffer_key)', COUNT(*)
FROM gold.fact_sales fs
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_specialoffer ds WHERE ds.specialoffer_key = fs.specialoffer_key)
UNION ALL
SELECT 'fact_salesreason → fact_sales (orphaned sales_key)',        COUNT(*)
FROM gold.fact_salesreason fsr
WHERE NOT EXISTS (SELECT 1 FROM gold.fact_sales fs WHERE fs.sales_key = fsr.sales_key)
UNION ALL
SELECT 'fact_salesreason → dim_salesreason (orphaned salesreason_key)', COUNT(*)
FROM gold.fact_salesreason fsr
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_salesreason dr WHERE dr.salesreason_key = fsr.salesreason_key)
UNION ALL
SELECT 'fact_customer_rfm → dim_customer (orphaned customer_key)', COUNT(*)
FROM gold.fact_customer_rfm rfm
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_customer dc WHERE dc.customer_key = rfm.customer_key);

-- ============================================================
-- CHECK 4: Duplicate Key Checks
-- ============================================================
-- Expected: ALL duplicate_count = 0
-- ============================================================
PRINT 'CHECK 4: Duplicate Key Checks';

SELECT 'dim_territory - duplicate territory_id'                              AS check_name, COUNT(*) AS duplicate_count
FROM (SELECT territory_id FROM gold.dim_territory GROUP BY territory_id HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'dim_product - duplicate product_id',                                 COUNT(*)
FROM (SELECT product_id FROM gold.dim_product GROUP BY product_id HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'dim_customer - duplicate customer_id',                               COUNT(*)
FROM (SELECT customer_id FROM gold.dim_customer GROUP BY customer_id HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'dim_specialoffer - duplicate specialoffer_id',                       COUNT(*)
FROM (SELECT specialoffer_id FROM gold.dim_specialoffer GROUP BY specialoffer_id HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'dim_salesreason - duplicate salesreason_id',                         COUNT(*)
FROM (SELECT salesreason_id FROM gold.dim_salesreason GROUP BY salesreason_id HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'fact_sales - duplicate (salesorder_id + salesorderdetail_id)',       COUNT(*)
FROM (SELECT salesorder_id, salesorderdetail_id FROM gold.fact_sales GROUP BY salesorder_id, salesorderdetail_id HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'fact_customer_rfm - duplicate (customer_key + snapshot_date)',       COUNT(*)
FROM (SELECT customer_key, snapshot_date FROM gold.fact_customer_rfm GROUP BY customer_key, snapshot_date HAVING COUNT(*) > 1) x;

-- ============================================================
-- CHECK 5: RFM BTYD Business Rules
-- ============================================================
-- Expected: ALL violation_count = 0
-- ============================================================
PRINT 'CHECK 5: RFM BTYD Business Rules';

SELECT 'rfm - recency < 0 (impossible)'                        AS check_name, COUNT(*) AS violation_count FROM gold.fact_customer_rfm WHERE recency < 0
UNION ALL
SELECT 'rfm - frequency < 0 (impossible)',                      COUNT(*) FROM gold.fact_customer_rfm WHERE frequency < 0
UNION ALL
SELECT 'rfm - T < 0 (impossible)',                              COUNT(*) FROM gold.fact_customer_rfm WHERE T < 0
UNION ALL
SELECT 'rfm - T < recency (T must always >= recency)',          COUNT(*) FROM gold.fact_customer_rfm WHERE T < recency
UNION ALL
SELECT 'rfm - monetary_value <= 0',                             COUNT(*) FROM gold.fact_customer_rfm WHERE monetary_value <= 0
UNION ALL
SELECT 'rfm - r_score out of range 1-5',                        COUNT(*) FROM gold.fact_customer_rfm WHERE r_score NOT BETWEEN 1 AND 5
UNION ALL
SELECT 'rfm - f_score out of range 1-5',                        COUNT(*) FROM gold.fact_customer_rfm WHERE f_score NOT BETWEEN 1 AND 5
UNION ALL
SELECT 'rfm - m_score out of range 1-5',                        COUNT(*) FROM gold.fact_customer_rfm WHERE m_score NOT BETWEEN 1 AND 5
UNION ALL
SELECT 'rfm - rfm_score length != 3',                           COUNT(*) FROM gold.fact_customer_rfm WHERE LEN(rfm_score) != 3
UNION ALL
SELECT 'rfm - last_order_date < first_order_date',              COUNT(*) FROM gold.fact_customer_rfm WHERE last_order_date < first_order_date
UNION ALL
SELECT 'rfm - frequency > 0 but recency = 0 (inconsistent)',   COUNT(*) FROM gold.fact_customer_rfm WHERE frequency > 0 AND recency = 0;

-- ============================================================
-- CHECK 6: fact_sales Financial Sanity
-- ============================================================
-- Expected: ALL violation_count = 0
-- ============================================================
PRINT 'CHECK 6: fact_sales Financial Sanity';

SELECT 'fact_sales - line_total <= 0'                       AS check_name, COUNT(*) AS violation_count FROM gold.fact_sales WHERE line_total <= 0
UNION ALL
SELECT 'fact_sales - unit_price <= 0',                      COUNT(*) FROM gold.fact_sales WHERE unit_price <= 0
UNION ALL
SELECT 'fact_sales - order_quantity <= 0',                  COUNT(*) FROM gold.fact_sales WHERE order_quantity <= 0
UNION ALL
SELECT 'fact_sales - discount_amount < 0',                  COUNT(*) FROM gold.fact_sales WHERE discount_amount < 0
UNION ALL
SELECT 'fact_sales - ship_date_key < order_date_key',       COUNT(*) FROM gold.fact_sales WHERE ship_date_key IS NOT NULL AND ship_date_key < order_date_key
UNION ALL
SELECT 'fact_sales - due_date_key < order_date_key',        COUNT(*) FROM gold.fact_sales WHERE due_date_key < order_date_key;

-- ============================================================
-- CHECK 7: dim_customer Metrics Consistency
-- ============================================================
-- Expected: ALL violation_count = 0
-- ============================================================
PRINT 'CHECK 7: dim_customer Metrics Consistency';

DECLARE @ObservationEndDate DATE;
SELECT @ObservationEndDate = MAX(orderdate)
FROM silver.aw_sales_salesorderheader;-- Set observation end date to today for consistency checks

SELECT 'dim_customer - last_order_date < first_order_date'              AS check_name, COUNT(*) AS violation_count FROM gold.dim_customer WHERE last_order_date < first_order_date
UNION ALL
SELECT 'dim_customer - total_orders = 0 but has order dates',           COUNT(*) FROM gold.dim_customer WHERE total_orders = 0 AND first_order_date IS NOT NULL
UNION ALL
SELECT 'dim_customer - lifetime_value = 0 but total_orders > 0',        COUNT(*) FROM gold.dim_customer WHERE lifetime_value = 0 AND total_orders > 0
UNION ALL
SELECT 'dim_customer - is_active=1 but last order > 365 days ago',      COUNT(*) FROM gold.dim_customer WHERE is_active = 1 AND DATEDIFF(DAY, last_order_date, @ObservationEndDate) > 365
UNION ALL
SELECT 'dim_customer - territory_key not in dim_territory',             COUNT(*) FROM gold.dim_customer dc WHERE dc.territory_key IS NOT NULL AND NOT EXISTS (SELECT 1 FROM gold.dim_territory dt WHERE dt.territory_key = dc.territory_key);

-- ============================================================
-- CHECK 8: Customer Segment Distribution (Informational)
-- ============================================================
-- Expected: All 5 segments present with reasonable distribution
-- ============================================================
PRINT 'CHECK 8: Customer Segment Distribution';

SELECT
    customer_segment,
    COUNT(*)                                                                AS customer_count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2))         AS pct_of_total
FROM gold.fact_customer_rfm
GROUP BY customer_segment
ORDER BY customer_count DESC;

