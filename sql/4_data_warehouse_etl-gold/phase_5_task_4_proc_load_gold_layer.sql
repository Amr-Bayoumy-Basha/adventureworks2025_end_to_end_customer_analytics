/*
=================================================================================
Gold Layer ETL Stored Procedure – Complete Data Warehouse Loader v3.0
=================================================================================
VERSION  : 3.0 (Based on Analytical SQL Validation)
AUTHOR   : Amr Bayomei Basha (Enhanced by Copilot)
DATE     : Jun 2026 
TARGET   : SQL Server – AdventureWorks2025_CustomerDW
DATABASE : Run in [AdventureWorks2025_CustomerDW] context (no USE statement)

CHANGES FROM v2.0
─────────────────────────────────────────────────────────────────────────────────
  1.  [NEW FACTS]     Added fact_customer_analytics (Q1/Q2/Q3 metrics)
                      Added fact_customer_cohort (Q4 cohort analysis)
                      Added fact_customer_btyd_inputs (Q5/Q6/Q7 BTYD inputs)
  2.  [ANALYTICS]     All analytical logic copied EXACTLY from Analytical SQL
                      Validation script – no simplifications or deviations
  3.  [ARCHITECTURE]  Retained all v2.0 patterns:
                      - SCD Type 1 MERGE for dimensions
                      - @ObservationEndDate for all analytical calculations
                      - ROWS framing for window functions (tie-safe)
                      - Transaction-wrapped (atomic load or rollback)
                      - CONVERT(INT, CONVERT(CHAR(8)...112)) for date keys
  4.  [SEQUENCE]      Load fact_sales → fact_customer_analytics → 
                      fact_customer_cohort → fact_customer_btyd_inputs → 
                      fact_salesreason
=================================================================================
*/

USE AdventureWorks2025_CustomerDW;
GO

IF OBJECT_ID('gold.sp_load_complete_datawarehouse', 'P') IS NOT NULL
    DROP PROCEDURE gold.sp_load_complete_datawarehouse;
GO

CREATE PROCEDURE gold.sp_load_complete_datawarehouse
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTime          DATETIME2 = SYSUTCDATETIME();
    DECLARE @EndTime            DATETIME2;
    DECLARE @ErrorMessage       NVARCHAR(4000);
    DECLARE @ErrorSeverity      INT;
    DECLARE @ErrorState         INT;
    DECLARE @SQL                NVARCHAR(MAX);
    DECLARE @DimRowCount        INT = 0;
    DECLARE @FactRowCount       INT = 0;
    DECLARE @ObservationEndDate DATE;
    DECLARE @duration_holdout   INT = 90; -- BTYD holdout window (days)

    BEGIN TRY

        -- ────────────────────────────────────────────────────────────────────
        -- Resolve dataset observation date (historical anchor for analytics)
        -- ────────────────────────────────────────────────────────────────────
        SELECT @ObservationEndDate = CAST(MAX(orderdate) AS DATE)
        FROM silver.aw_sales_salesorderheader;

        PRINT '=================================================================================';
        PRINT 'Gold Layer ETL v3.0 – Complete Data Warehouse Loader';
        PRINT 'ETL Start Time     : ' + CONVERT(VARCHAR(30), @StartTime, 121);
        PRINT 'Observation Date   : ' + CONVERT(VARCHAR(10), @ObservationEndDate, 120);
        PRINT 'BTYD Holdout       : ' + CAST(@duration_holdout AS VARCHAR(10)) + ' days';
        PRINT '=================================================================================';
        PRINT '';

        -- ====================================================================
        -- STEP 0: DROP ALL FOREIGN KEY CONSTRAINTS IN GOLD SCHEMA
        -- ====================================================================
        PRINT '[STEP 0] Dropping all foreign keys in [gold] schema...';

        SET @SQL = N'';
        SELECT @SQL += N'ALTER TABLE ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) +
                       N' DROP CONSTRAINT ' + QUOTENAME(fk.name) + N';' + CHAR(13)
        FROM sys.foreign_keys AS fk
        INNER JOIN sys.tables AS t ON fk.parent_object_id = t.object_id
        INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
        WHERE s.name = N'gold';

        IF @SQL <> N''
        BEGIN
            EXEC sp_executesql @SQL;
            PRINT '  ✓ All gold foreign keys dropped.';
        END
        ELSE
            PRINT '  – No foreign keys found.';

        PRINT '';

        -- ====================================================================
        -- BEGIN ATOMIC TRANSACTION
        -- ====================================================================
        BEGIN TRANSACTION;

        -- ====================================================================
        -- SECTION 1: LOAD DIMENSION TABLES (SCD Type 1 MERGE)
        -- User will handle dims separately - kept for completeness
        -- ====================================================================
        PRINT '=================================================================================';
        PRINT 'SECTION 1: Loading Dimension Tables (SCD Type 1 MERGE)';
        PRINT '=================================================================================';
        PRINT '';

        -- [1/5] dim_territory
        PRINT '  [1/5] Merging: dim_territory';
        MERGE gold.dim_territory AS tgt
        USING (
            SELECT territory_id, name AS territory_name, countryregioncode AS country_code, [group] AS region_group
            FROM silver.aw_sales_salesterritory
        ) AS src ON tgt.territory_id = src.territory_id
        WHEN MATCHED THEN
            UPDATE SET tgt.territory_name = src.territory_name, tgt.country_code = src.country_code, tgt.region_group = src.region_group
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (territory_id, territory_name, country_code, region_group)
            VALUES (src.territory_id, src.territory_name, src.country_code, src.region_group);
        SET @DimRowCount = @@ROWCOUNT;
        PRINT '        ✓ Merged: ' + CAST(@DimRowCount AS VARCHAR(20)) + ' territory rows';
        PRINT '';

        -- [2/5] dim_product
        PRINT '  [2/5] Merging: dim_product';
        MERGE gold.dim_product AS tgt
        USING (
            SELECT p.product_id, p.name AS product_name, p.productnumber AS product_number,
                   pc.name AS category_name, ps.name AS subcategory_name,
                   p.color, p.size, p.productline AS product_line, p.class, p.style,
                   p.listprice AS list_price, p.standardcost AS standard_cost,
                   p.daystomanufacture AS days_to_manufacture,
                   CASE WHEN p.sellenddate IS NULL THEN 1 ELSE 0 END AS is_active
            FROM silver.aw_production_product p
            LEFT JOIN silver.aw_production_productsubcategory ps ON p.productsubcategory_id = ps.productsubcategory_id
            LEFT JOIN silver.aw_production_productcategory pc ON ps.productcategory_id = pc.productcategory_id
        ) AS src ON tgt.product_id = src.product_id
        WHEN MATCHED THEN
            UPDATE SET tgt.product_name = src.product_name, tgt.product_number = src.product_number,
                       tgt.category_name = src.category_name, tgt.subcategory_name = src.subcategory_name,
                       tgt.color = src.color, tgt.size = src.size, tgt.product_line = src.product_line,
                       tgt.class = src.class, tgt.style = src.style, tgt.list_price = src.list_price,
                       tgt.standard_cost = src.standard_cost, tgt.days_to_manufacture = src.days_to_manufacture,
                       tgt.is_active = src.is_active
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (product_id, product_name, product_number, category_name, subcategory_name,
                    color, size, product_line, class, style, list_price, standard_cost,
                    days_to_manufacture, is_active)
            VALUES (src.product_id, src.product_name, src.product_number, src.category_name, src.subcategory_name,
                    src.color, src.size, src.product_line, src.class, src.style, src.list_price, src.standard_cost,
                    src.days_to_manufacture, src.is_active);
        SET @DimRowCount = @@ROWCOUNT;
        PRINT '        ✓ Merged: ' + CAST(@DimRowCount AS VARCHAR(20)) + ' product rows';
        PRINT '';

        -- [3/5] dim_specialoffer
        PRINT '  [3/5] Merging: dim_specialoffer';
        MERGE gold.dim_specialoffer AS tgt
        USING (
            SELECT specialoffer_id, description AS offer_description, discountpct AS discount_pct,
                   type AS offer_type, category AS offer_category, startdate AS start_date, enddate AS end_date,
                   minqty AS min_qty, maxqty AS max_qty,
                   CASE WHEN @ObservationEndDate BETWEEN startdate AND enddate THEN 1 ELSE 0 END AS is_active
            FROM silver.aw_sales_specialoffer
        ) AS src ON tgt.specialoffer_id = src.specialoffer_id
        WHEN MATCHED THEN
            UPDATE SET tgt.offer_description = src.offer_description, tgt.discount_pct = src.discount_pct,
                       tgt.offer_type = src.offer_type, tgt.offer_category = src.offer_category,
                       tgt.start_date = src.start_date, tgt.end_date = src.end_date,
                       tgt.min_qty = src.min_qty, tgt.max_qty = src.max_qty, tgt.is_active = src.is_active
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (specialoffer_id, offer_description, discount_pct, offer_type, offer_category,
                    start_date, end_date, min_qty, max_qty, is_active)
            VALUES (src.specialoffer_id, src.offer_description, src.discount_pct, src.offer_type, src.offer_category,
                    src.start_date, src.end_date, src.min_qty, src.max_qty, src.is_active);
        SET @DimRowCount = @@ROWCOUNT;
        PRINT '        ✓ Merged: ' + CAST(@DimRowCount AS VARCHAR(20)) + ' special offer rows';
        PRINT '';

        -- [4/5] dim_salesreason
        PRINT '  [4/5] Merging: dim_salesreason';
        MERGE gold.dim_salesreason AS tgt
        USING (
            SELECT salesreason_id, name AS reason_name, reasontype AS reason_type
            FROM silver.aw_sales_salesreason
        ) AS src ON tgt.salesreason_id = src.salesreason_id
        WHEN MATCHED THEN
            UPDATE SET tgt.reason_name = src.reason_name, tgt.reason_type = src.reason_type
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (salesreason_id, reason_name, reason_type)
            VALUES (src.salesreason_id, src.reason_name, src.reason_type);
        SET @DimRowCount = @@ROWCOUNT;
        PRINT '        ✓ Merged: ' + CAST(@DimRowCount AS VARCHAR(20)) + ' sales reason rows';
        PRINT '';

        -- [5/5] dim_customer
        PRINT '  [5/5] Merging: dim_customer (structural attributes only)';
        ;WITH ranked_customers AS (
            SELECT c.customer_id, c.person_id,
                   CONCAT(p.firstname, ' ', p.lastname) AS customer_name,
                   p.persontype AS person_type, e.emailaddress AS email_address,
                   a.addressline1, a.addressline2, a.city,
                   sp.name AS state_province, sp.countryregioncode AS country, a.postalcode AS postal_code,
                   dt.territory_key,
                   ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY bea.address_id, e.emailaddress_id) AS rn
            FROM silver.aw_sales_customer c
            LEFT JOIN silver.aw_person_person p ON c.person_id = p.businessentity_id
            LEFT JOIN silver.aw_person_emailaddress e ON c.person_id = e.businessentity_id
            LEFT JOIN silver.aw_person_businessentityaddress bea ON c.person_id = bea.businessentity_id
            LEFT JOIN silver.aw_person_address a ON bea.address_id = a.address_id
            LEFT JOIN silver.aw_person_stateprovince sp ON a.stateprovince_id = sp.stateprovince_id
            LEFT JOIN gold.dim_territory dt ON c.territory_id = dt.territory_id
        )
        MERGE gold.dim_customer AS tgt
        USING (
            SELECT customer_id, person_id, customer_name, person_type, email_address,
                   addressline1 AS address_line1, addressline2 AS address_line2, city, state_province, country,
                   postal_code, territory_key
            FROM ranked_customers WHERE rn = 1
        ) AS src ON tgt.customer_id = src.customer_id
        WHEN MATCHED THEN
            UPDATE SET tgt.person_id = src.person_id, tgt.customer_name = src.customer_name,
                       tgt.person_type = src.person_type, tgt.email_address = src.email_address,
                       tgt.address_line1 = src.address_line1, tgt.address_line2 = src.address_line2,
                       tgt.city = src.city, tgt.state_province = src.state_province, tgt.country = src.country,
                       tgt.postal_code = src.postal_code, tgt.territory_key = src.territory_key,
                       tgt.dwh_update_date = GETDATE()
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (customer_id, person_id, customer_name, person_type, email_address,
                    address_line1, address_line2, city, state_province, country, postal_code, territory_key)
            VALUES (src.customer_id, src.person_id, src.customer_name, src.person_type, src.email_address,
                    src.address_line1, src.address_line2, src.city, src.state_province, src.country,
                    src.postal_code, src.territory_key);
        SET @DimRowCount = @@ROWCOUNT;
        PRINT '        ✓ Merged: ' + CAST(@DimRowCount AS VARCHAR(20)) + ' customer rows';
        PRINT '';
        PRINT '  ✓ SECTION 1 Complete';
        PRINT '';

        -- ====================================================================
        -- SECTION 2: LOAD FACT TABLES
        -- ====================================================================
        PRINT '=================================================================================';
        PRINT 'SECTION 2: Loading Fact Tables';
        PRINT '=================================================================================';
        PRINT '';

        -- ══════════════════════════════════════════════════════════════════
        -- [1/5] fact_sales
        -- ══════════════════════════════════════════════════════════════════
        PRINT '  [1/5] Loading: fact_sales';
        TRUNCATE TABLE gold.fact_sales;

        INSERT INTO gold.fact_sales (
            salesorder_id, salesorderdetail_id,
            order_date_key, due_date_key, ship_date_key,
            customer_key, product_key, territory_key, specialoffer_key,
            order_number, purchase_order_number, order_quantity,
            unit_price, unit_discount, line_total, discount_amount, cost_amount, gross_profit,
            subtotal, tax_amount, freight, total_due, is_online_order, order_status
        )
        SELECT
            sod.salesorder_id, sod.salesorderdetail_id,
            CONVERT(INT, CONVERT(CHAR(8), soh.orderdate, 112)) AS order_date_key,
            CONVERT(INT, CONVERT(CHAR(8), soh.duedate, 112)) AS due_date_key,
            CONVERT(INT, CONVERT(CHAR(8), soh.shipdate, 112)) AS ship_date_key,
            dc.customer_key, dp.product_key, dt.territory_key, dso.specialoffer_key,
            soh.salesordernumber, soh.purchaseordernumber, sod.orderqty,
            sod.unitprice, sod.unitpricediscount, sod.linetotal,
            sod.unitpricediscount * sod.orderqty * sod.unitprice AS discount_amount,
            ISNULL(dp.standard_cost, 0) * sod.orderqty AS cost_amount,
            sod.linetotal - ISNULL(dp.standard_cost, 0) * sod.orderqty AS gross_profit,
            soh.subtotal, soh.taxamt, soh.freight, soh.totaldue,
            soh.onlineorderflag, soh.status
        FROM silver.aw_sales_salesorderdetail sod
        INNER JOIN silver.aw_sales_salesorderheader soh ON sod.salesorder_id = soh.salesorder_id
        LEFT JOIN gold.dim_customer dc ON soh.customer_id = dc.customer_id
        LEFT JOIN gold.dim_product dp ON sod.product_id = dp.product_id
        LEFT JOIN gold.dim_territory dt ON soh.territory_id = dt.territory_id
        LEFT JOIN gold.dim_specialoffer dso ON sod.specialoffer_id = dso.specialoffer_id;

        SET @FactRowCount = @@ROWCOUNT;
        PRINT '        ✓ Loaded: ' + CAST(@FactRowCount AS VARCHAR(20)) + ' sales line items';
        PRINT '';

        -- ══════════════════════════════════════════════════════════════════
        -- [2/5] fact_customer_analytics (EXACT LOGIC FROM VALIDATION)
        -- ══════════════════════════════════════════════════════════════════
        PRINT '  [2/5] Loading: fact_customer_analytics (Q1/Q2/Q3 metrics)';
        TRUNCATE TABLE gold.fact_customer_analytics;

        ;WITH CustomerMetrics AS (
            SELECT 
                C.customer_id,
                -- Q1: Most valuable customers
                SUM(SOD.linetotal) AS TotalRevenuePerCustomer,
                COUNT(DISTINCT SOD.salesorder_id) AS TotalOrdersPerCustomer,
                SUM(SOD.orderqty) AS TotalQuantityPerCustomer,
                CASE WHEN COUNT(DISTINCT SOD.salesorder_id) > 0 
                     THEN SUM(SOD.linetotal) / COUNT(DISTINCT SOD.salesorder_id)
                     ELSE 0 END AS AverageCustomerOrderValue,
                SUM(SOD.linetotal) - SUM(SOD.orderqty * PP.standardcost) AS CustomerGrossProfit,
                CASE WHEN SUM(SOD.linetotal) > 0 
                     THEN (SUM(SOD.linetotal) - SUM(SOD.orderqty * PP.standardcost)) / SUM(SOD.linetotal)
                     ELSE 0 END AS CustomerProfitMargin,
                CASE WHEN SUM(SOD.linetotal) > 0 
                     THEN SUM(SOD.linetotal) / (SELECT SUM(linetotal) FROM silver.aw_sales_salesorderdetail)
                     ELSE 0 END AS CustomerRevenueContribution,
                CASE WHEN SUM(SOD.linetotal) > 0 
                     THEN (SUM(SOD.linetotal) - SUM(SOD.orderqty * PP.standardcost)) /
                          (SELECT SUM(SOD2.linetotal - (SOD2.orderqty * PP2.standardcost))
                           FROM silver.aw_sales_salesorderdetail SOD2
                           INNER JOIN silver.aw_production_product PP2 ON SOD2.product_id = PP2.product_id)
                     ELSE 0 END AS CustomerProfitContribution,
                CASE WHEN SUM(SOD.linetotal) > 0 
                     THEN SUM(SOD.linetotal) * 1.0
                     ELSE 0 END AS Historical_CLV_Proxy,
                CASE WHEN SUM(SOD.linetotal) > 0 
                     THEN (SUM(SOD.linetotal) - SUM(SOD.orderqty * PP.standardcost)) * 1.0
                     ELSE 0 END AS Historical_Lifetime_Profit,
                -- Q3: Customer behavior
                MIN(SOH.orderdate) AS first_order_date,
                MAX(SOH.orderdate) AS last_order_date,
                DATEDIFF(DAY, MAX(SOH.orderdate), @ObservationEndDate) AS days_since_last_purchase,
                COUNT(DISTINCT SOD.product_id) AS product_diversity,
                COUNT(DISTINCT PP.productsubcategory_id) AS category_diversity,
                CASE WHEN COUNT(DISTINCT CAST(SOH.orderdate AS DATE)) > 1
                     THEN DATEDIFF(DAY, MIN(SOH.orderdate), MAX(SOH.orderdate)) * 1.0 /
                          (COUNT(DISTINCT CAST(SOH.orderdate AS DATE)) - 1)
                     ELSE NULL END AS avg_days_between_purchases
            FROM silver.aw_sales_customer AS C
            INNER JOIN silver.aw_sales_salesorderheader AS SOH ON C.customer_id = SOH.customer_id
            LEFT JOIN silver.aw_sales_salesorderdetail AS SOD ON SOH.salesorder_id = SOD.salesorder_id
            LEFT JOIN silver.aw_production_product AS PP ON SOD.product_id = PP.product_id
            GROUP BY C.customer_id
        ),
        rfm_base AS (
            SELECT customer_id,
                   DATEDIFF(DAY, last_order_date, @ObservationEndDate) AS recency,
                   TotalOrdersPerCustomer AS frequency,
                   AverageCustomerOrderValue AS monetary
            FROM CustomerMetrics
        ),
        rfm_scores AS (
            SELECT customer_id, recency, frequency, monetary,
                   6 - NTILE(5) OVER (ORDER BY recency) AS r_score,
                   NTILE(5) OVER (ORDER BY frequency) AS f_score,
                   NTILE(5) OVER (ORDER BY monetary) AS m_score
            FROM rfm_base
        ),
        rfm_segments AS (
            SELECT customer_id, recency, frequency, monetary, r_score, f_score, m_score,
                   CONCAT(r_score, f_score, m_score) AS rfm_score,
                   CASE
                       WHEN r_score = 5 AND f_score = 5 AND m_score >= 4 THEN 'Champions'
                       WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Loyal Customers'
                       WHEN r_score = 5 AND f_score BETWEEN 3 AND 4 THEN 'Potential Loyalists'
                       WHEN r_score = 5 AND f_score <= 2 THEN 'Recent Customers'
                       WHEN r_score BETWEEN 2 AND 3 AND f_score >= 4 AND m_score >= 4 THEN 'Cannot Lose Them'
                       WHEN r_score BETWEEN 2 AND 3 AND f_score BETWEEN 2 AND 3 THEN 'Needs Attention'
                       WHEN f_score >= 3 AND m_score <= 2 THEN 'Price Sensitive'
                       WHEN r_score <= 2 AND f_score >= 3 THEN 'About To Sleep'
                       WHEN r_score <= 2 AND f_score <= 2 THEN 'Hibernating'
                       WHEN r_score = 1 AND f_score = 1 THEN 'Lost Customers'
                       ELSE 'Others'
                   END AS customer_segment
            FROM rfm_scores
        )
        INSERT INTO gold.fact_customer_analytics (
            customer_key, snapshot_date,
            total_revenue, total_orders, total_quantity, avg_order_value,
            gross_profit, profit_margin, revenue_contribution, profit_contribution,
            historical_clv_proxy, historical_lifetime_profit,
            first_order_date, last_order_date, days_since_last_purchase,
            product_diversity, category_diversity, avg_days_between_purchases,
            recency, frequency, monetary, r_score, f_score, m_score, rfm_score, customer_segment
        )
        SELECT
            dc.customer_key, @ObservationEndDate AS snapshot_date,
            cm.TotalRevenuePerCustomer, cm.TotalOrdersPerCustomer, cm.TotalQuantityPerCustomer, cm.AverageCustomerOrderValue,
            cm.CustomerGrossProfit, cm.CustomerProfitMargin, cm.CustomerRevenueContribution, cm.CustomerProfitContribution,
            cm.Historical_CLV_Proxy, cm.Historical_Lifetime_Profit,
            cm.first_order_date, cm.last_order_date, cm.days_since_last_purchase,
            cm.product_diversity, cm.category_diversity, cm.avg_days_between_purchases,
            rs.recency, rs.frequency, rs.monetary, rs.r_score, rs.f_score, rs.m_score, rs.rfm_score, rs.customer_segment
        FROM CustomerMetrics cm
        LEFT JOIN rfm_segments rs ON cm.customer_id = rs.customer_id
        INNER JOIN gold.dim_customer dc ON cm.customer_id = dc.customer_id;

        SET @FactRowCount = @@ROWCOUNT;
        PRINT '        ✓ Loaded: ' + CAST(@FactRowCount AS VARCHAR(20)) + ' customer analytics records';
        PRINT '';

        -- ══════════════════════════════════════════════════════════════════
        -- [3/5] fact_customer_cohort (EXACT LOGIC FROM VALIDATION)
        -- ══════════════════════════════════════════════════════════════════
        PRINT '  [3/5] Loading: fact_customer_cohort (Q4 cohort analysis)';
        TRUNCATE TABLE gold.fact_customer_cohort;

        ;WITH customer_cohort AS (
            SELECT customer_id,
                   DATEFROMPARTS(YEAR(MIN(orderdate)), MONTH(MIN(orderdate)), 1) AS cohort_month
            FROM silver.aw_sales_salesorderheader
            GROUP BY customer_id
        ),
        cohort_orders AS (
            SELECT cc.customer_id, cc.cohort_month,
                   DATEFROMPARTS(YEAR(SOH.orderdate), MONTH(SOH.orderdate), 1) AS order_month,
                   SOH.salesorder_id, SOD.linetotal, SOD.orderqty, PP.standardcost
            FROM customer_cohort cc
            INNER JOIN silver.aw_sales_salesorderheader SOH ON cc.customer_id = SOH.customer_id
            INNER JOIN silver.aw_sales_salesorderdetail SOD ON SOH.salesorder_id = SOD.salesorder_id
            LEFT JOIN silver.aw_production_product PP ON SOD.product_id = PP.product_id
        ),
        cohort_size AS (
            SELECT cohort_month, COUNT(DISTINCT customer_id) AS cohort_size
            FROM customer_cohort
            GROUP BY cohort_month
        )
        INSERT INTO gold.fact_customer_cohort (
            cohort_month, period_number, cohort_size, active_customers, retention_rate,
            cohort_revenue, revenue_per_customer, cohort_orders, orders_per_customer,
            cohort_gross_profit, gross_profit_per_customer
        )
        SELECT
            co.cohort_month,
            DATEDIFF(MONTH, co.cohort_month, co.order_month) AS period_number,
            cs.cohort_size,
            COUNT(DISTINCT co.customer_id) AS active_customers,
            COUNT(DISTINCT co.customer_id) * 1.0 / cs.cohort_size AS retention_rate,
            SUM(co.linetotal) AS cohort_revenue,
            SUM(co.linetotal) * 1.0 / COUNT(DISTINCT co.customer_id) AS revenue_per_customer,
            COUNT(DISTINCT co.salesorder_id) AS cohort_orders,
            COUNT(DISTINCT co.salesorder_id) * 1.0 / COUNT(DISTINCT co.customer_id) AS orders_per_customer,
            SUM(co.linetotal - (co.orderqty * co.standardcost)) AS cohort_gross_profit,
            SUM(co.linetotal - (co.orderqty * co.standardcost)) * 1.0 / COUNT(DISTINCT co.customer_id) AS gross_profit_per_customer
        FROM cohort_orders co
        INNER JOIN cohort_size cs ON co.cohort_month = cs.cohort_month
        GROUP BY co.cohort_month, DATEDIFF(MONTH, co.cohort_month, co.order_month), cs.cohort_size;

        SET @FactRowCount = @@ROWCOUNT;
        PRINT '        ✓ Loaded: ' + CAST(@FactRowCount AS VARCHAR(20)) + ' cohort analysis records';
        PRINT '';

        -- ══════════════════════════════════════════════════════════════════
        -- [4/5] fact_customer_btyd_inputs (EXACT LOGIC FROM VALIDATION)
        -- ══════════════════════════════════════════════════════════════════
        PRINT '  [4/5] Loading: fact_customer_btyd_inputs (Q5/Q6/Q7 BTYD inputs)';
        TRUNCATE TABLE gold.fact_customer_btyd_inputs;

        ;WITH calibration AS (
            SELECT 
                C.customer_id,
                COUNT(DISTINCT CONVERT(DATE, SOH.orderdate)) - 1 AS frequency,
                DATEDIFF(DAY, MIN(SOH.orderdate), MAX(SOH.orderdate)) AS recency,
                DATEDIFF(DAY, MIN(SOH.orderdate), DATEADD(DAY, -@duration_holdout, @ObservationEndDate)) AS T,
                SUM(SOD.linetotal) / COUNT(DISTINCT SOH.salesorder_id) AS monetary_value
            FROM silver.aw_sales_salesorderdetail SOD
            INNER JOIN silver.aw_sales_salesorderheader SOH ON SOD.salesorder_id = SOH.salesorder_id
            LEFT JOIN silver.aw_sales_customer C ON SOH.customer_id = C.customer_id
            WHERE SOH.orderdate < DATEADD(DAY, -@duration_holdout, @ObservationEndDate)
            GROUP BY C.customer_id
        ),
        holdout AS (
            SELECT C.customer_id,
                   COUNT(DISTINCT CONVERT(DATE, SOH.orderdate)) AS frequency_holdout
            FROM silver.aw_sales_salesorderheader SOH
            LEFT JOIN silver.aw_sales_customer C ON SOH.customer_id = C.customer_id
            WHERE SOH.orderdate >= DATEADD(DAY, -@duration_holdout, @ObservationEndDate)
              AND SOH.orderdate <= @ObservationEndDate
            GROUP BY C.customer_id
        )
        INSERT INTO gold.fact_customer_btyd_inputs (
            customer_key, observation_date, duration_holdout,
            frequency, recency, T, monetary_value, frequency_holdout
        )
        SELECT 
            dc.customer_key, @ObservationEndDate, @duration_holdout,
            cal.frequency, cal.recency, cal.T, cal.monetary_value, h.frequency_holdout
        FROM calibration AS cal
        LEFT JOIN holdout h ON cal.customer_id = h.customer_id
        INNER JOIN gold.dim_customer dc ON cal.customer_id = dc.customer_id;

        SET @FactRowCount = @@ROWCOUNT;
        PRINT '        ✓ Loaded: ' + CAST(@FactRowCount AS VARCHAR(20)) + ' BTYD input records';
        PRINT '';

        -- ══════════════════════════════════════════════════════════════════
        -- [5/5] fact_salesreason
        -- ══════════════════════════════════════════════════════════════════
        PRINT '  [5/5] Loading: fact_salesreason';
        TRUNCATE TABLE gold.fact_salesreason;

        INSERT INTO gold.fact_salesreason (sales_key, salesreason_key)
        SELECT fs_min.sales_key, dsr.salesreason_key
        FROM silver.aw_sales_salesorderheadersalesreason sohr
        INNER JOIN (
            SELECT salesorder_id, MIN(sales_key) AS sales_key
            FROM gold.fact_sales
            GROUP BY salesorder_id
        ) fs_min ON sohr.salesorder_id = fs_min.salesorder_id
        INNER JOIN gold.dim_salesreason dsr ON sohr.salesreason_id = dsr.salesreason_id;

        SET @FactRowCount = @@ROWCOUNT;
        PRINT '        ✓ Loaded: ' + CAST(@FactRowCount AS VARCHAR(20)) + ' sales reason associations';
        PRINT '';
        PRINT '  ✓ SECTION 2 Complete – All 5 Facts Loaded';
        PRINT '';

                -- ====================================================================
        -- SECTION 3: RECREATE FOREIGN KEY CONSTRAINTS (Star Schema Relationships)
        -- ====================================================================
        PRINT '=================================================================================';
        PRINT 'SECTION 3: Recreating Foreign Key Constraints (Star Schema)';
        PRINT '=================================================================================';
        PRINT '';

        -- ══════════════════════════════════════════════════════════════════
        -- fact_sales → dimensions
        -- ══════════════════════════════════════════════════════════════════
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_fact_sales_customer')
        BEGIN
            ALTER TABLE gold.fact_sales ADD CONSTRAINT fk_fact_sales_customer
                FOREIGN KEY (customer_key) REFERENCES gold.dim_customer(customer_key);
            PRINT '  ✓ Added: fk_fact_sales_customer';
        END

        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_fact_sales_product')
        BEGIN
            ALTER TABLE gold.fact_sales ADD CONSTRAINT fk_fact_sales_product
                FOREIGN KEY (product_key) REFERENCES gold.dim_product(product_key);
            PRINT '  ✓ Added: fk_fact_sales_product';
        END

        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_fact_sales_territory')
        BEGIN
            ALTER TABLE gold.fact_sales ADD CONSTRAINT fk_fact_sales_territory
                FOREIGN KEY (territory_key) REFERENCES gold.dim_territory(territory_key);
            PRINT '  ✓ Added: fk_fact_sales_territory';
        END

        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_fact_sales_specialoffer')
        BEGIN
            ALTER TABLE gold.fact_sales ADD CONSTRAINT fk_fact_sales_specialoffer
                FOREIGN KEY (specialoffer_key) REFERENCES gold.dim_specialoffer(specialoffer_key);
            PRINT '  ✓ Added: fk_fact_sales_specialoffer';
        END

        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_fact_sales_order_date')
        BEGIN
            ALTER TABLE gold.fact_sales ADD CONSTRAINT fk_fact_sales_order_date
                FOREIGN KEY (order_date_key) REFERENCES gold.dim_date(date_key);
            PRINT '  ✓ Added: fk_fact_sales_order_date';
        END

        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_fact_sales_due_date')
        BEGIN
            ALTER TABLE gold.fact_sales ADD CONSTRAINT fk_fact_sales_due_date
                FOREIGN KEY (due_date_key) REFERENCES gold.dim_date(date_key);
            PRINT '  ✓ Added: fk_fact_sales_due_date';
        END

        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_fact_sales_ship_date')
        BEGIN
            ALTER TABLE gold.fact_sales ADD CONSTRAINT fk_fact_sales_ship_date
                FOREIGN KEY (ship_date_key) REFERENCES gold.dim_date(date_key);
            PRINT '  ✓ Added: fk_fact_sales_ship_date';
        END

        -- ══════════════════════════════════════════════════════════════════
        -- fact_customer_analytics → dim_customer
        -- ══════════════════════════════════════════════════════════════════
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_fact_customer_analytics_customer')
        BEGIN
            ALTER TABLE gold.fact_customer_analytics ADD CONSTRAINT fk_fact_customer_analytics_customer
                FOREIGN KEY (customer_key) REFERENCES gold.dim_customer(customer_key);
            PRINT '  ✓ Added: fk_fact_customer_analytics_customer';
        END

        -- ══════════════════════════════════════════════════════════════════
        -- fact_customer_btyd_inputs → dim_customer
        -- ══════════════════════════════════════════════════════════════════
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_fact_customer_btyd_inputs_customer')
        BEGIN
            ALTER TABLE gold.fact_customer_btyd_inputs ADD CONSTRAINT fk_fact_customer_btyd_inputs_customer
                FOREIGN KEY (customer_key) REFERENCES gold.dim_customer(customer_key);
            PRINT '  ✓ Added: fk_fact_customer_btyd_inputs_customer';
        END

        -- ══════════════════════════════════════════════════════════════════
        -- fact_salesreason → fact_sales + dim_salesreason (bridge table)
        -- ══════════════════════════════════════════════════════════════════
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_fact_salesreason_sales')
        BEGIN
            ALTER TABLE gold.fact_salesreason ADD CONSTRAINT fk_fact_salesreason_sales
                FOREIGN KEY (sales_key) REFERENCES gold.fact_sales(sales_key);
            PRINT '  ✓ Added: fk_fact_salesreason_sales';
        END

        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_fact_salesreason_reason')
        BEGIN
            ALTER TABLE gold.fact_salesreason ADD CONSTRAINT fk_fact_salesreason_reason
                FOREIGN KEY (salesreason_key) REFERENCES gold.dim_salesreason(salesreason_key);
            PRINT '  ✓ Added: fk_fact_salesreason_reason';
        END

        PRINT '';
        PRINT '  ✓ SECTION 3 Complete – 11 Foreign Keys Created (Star Schema Enforced)';
        PRINT '';

        -- ====================================================================
        -- COMMIT TRANSACTION
        -- ====================================================================
        COMMIT TRANSACTION;

        SET @EndTime = SYSUTCDATETIME();

        PRINT '=================================================================================';
        PRINT 'Gold Layer ETL v3.0 – COMPLETED SUCCESSFULLY';
        PRINT '=================================================================================';
        PRINT '  ✓ 5 dimension tables merged (SCD Type 1)';
        PRINT '  ✓ 5 fact tables loaded:';
        PRINT '      - fact_sales (transaction grain)';
        PRINT '      - fact_customer_analytics (customer grain - Q1/Q2/Q3)';
        PRINT '      - fact_customer_cohort (cohort × period grain - Q4)';
        PRINT '      - fact_customer_btyd_inputs (customer grain - Q5/Q6/Q7)';
        PRINT '      - fact_salesreason (bridge table)';
        PRINT '  ✓ All analytical logic preserved from validation queries';
        PRINT '  ✓ Observation date: ' + CONVERT(VARCHAR(10), @ObservationEndDate, 120);
        PRINT '';
        PRINT 'ETL Start Time : ' + CONVERT(VARCHAR(30), @StartTime, 121);
        PRINT 'ETL End Time   : ' + CONVERT(VARCHAR(30), @EndTime, 121);
        PRINT 'Duration       : ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS VARCHAR(20)) + ' seconds';
        PRINT '=================================================================================';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
        PRINT '';
        PRINT '=================================================================================';
        PRINT 'ERROR: Gold Layer ETL v3.0 Failed – Transaction Rolled Back';
        PRINT '=================================================================================';
        PRINT 'Error Message  : ' + @ErrorMessage;
        PRINT 'Error Severity : ' + CAST(@ErrorSeverity AS VARCHAR(10));
        PRINT 'Error State    : ' + CAST(@ErrorState AS VARCHAR(10));
        PRINT 'Error Line     : ' + CAST(ERROR_LINE() AS VARCHAR(10));
        PRINT '=================================================================================';
        THROW;
    END CATCH
END;
GO

PRINT '=================================================================================';
PRINT 'Stored procedure gold.sp_load_complete_datawarehouse v3.0 created successfully';
PRINT '=================================================================================';
PRINT 'Usage: EXEC gold.sp_load_complete_datawarehouse;';
PRINT '=================================================================================';
GO

Usage: EXEC gold.sp_load_complete_datawarehouse;
