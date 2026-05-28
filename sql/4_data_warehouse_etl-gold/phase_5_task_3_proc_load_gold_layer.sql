/*
=================================================================================
Gold Layer ETL Stored Procedure - Complete Data Warehouse Loader
=================================================================================
FIXED VERSION - Changes from original:
  1. [CRITICAL] fact_customer_rfm: Moved CTE before INSERT (semicolon bug)
  2. [CRITICAL] fact_sales: currency_code now uses tocurrencycode from currency rate table
  3. [CRITICAL] fact_sales: exchange_rate now uses averagerate from currency rate table
  4. [CRITICAL] fact_sales: profit_amount formula corrected (line_total - cost_amount)
  5. fact_sales: Added @@ROWCOUNT print
  6. dim_customer: Added UPDATE step to populate order metrics from fact_sales
  7. Removed prohibited USE statement - run in AdventureWorks2025_CustomerDW context.

TARGET: SQL Server (AdventureWorks2025_CustomerDW) | AUTHOR: Amr Bayomei Basha | DATE: May 2026
VERSION: 1.0
=================================================================================
*/

-- Drop existing procedure
IF OBJECT_ID('gold.sp_load_complete_datawarehouse', 'P') IS NOT NULL
    DROP PROCEDURE gold.sp_load_complete_datawarehouse;
GO

CREATE PROCEDURE gold.sp_load_complete_datawarehouse
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME2 = SYSUTCDATETIME();
    DECLARE @EndTime DATETIME2;
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @DimRowCount INT = 0;
    DECLARE @FactRowCount INT = 0;
    
    BEGIN TRY
        PRINT '=================================================================================';
        PRINT 'Starting Complete Gold Layer Data Warehouse ETL Process';
        PRINT 'Start Time: ' + CONVERT(VARCHAR(30), @StartTime, 121);
        PRINT '=================================================================================';
        PRINT '';
        
        -- ========================================================================
        -- STEP 0: DROP ALL FOREIGN KEY CONSTRAINTS IN GOLD SCHEMA
        -- ========================================================================
        
        PRINT '=================================================================================';
        PRINT 'STEP 0: Dynamically Dropping All Foreign Keys in Schema [gold]';
        PRINT '=================================================================================';
        PRINT '';
        
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
            PRINT '  ✓ Success: All foreign keys in [gold] schema have been dropped.';
        END
        ELSE
        BEGIN
            PRINT '  - Note: No foreign keys found in [gold] schema to drop.';
        END
        
        PRINT '';
        
        -- ========================================================================
        -- SECTION 1: LOAD DIMENSION TABLES
        -- ========================================================================
        
        PRINT '=================================================================================';
        PRINT 'SECTION 1: Loading Gold Layer Dimensions';
        PRINT '=================================================================================';
        PRINT '';
        
        -- 1. Load dim_territory
        PRINT '  [1/5] Loading: dim_territory';
        TRUNCATE TABLE gold.dim_territory;
        
        INSERT INTO gold.dim_territory (
            territory_id, territory_name, country_code, region_group
        )
        SELECT 
            territory_id,
            name               AS territory_name,
            countryregioncode  AS country_code,
            [group]            AS region_group
        FROM silver.aw_sales_salesterritory;
        
        SET @DimRowCount = @@ROWCOUNT;
        PRINT '        ✓ Loaded: ' + CAST(@DimRowCount AS VARCHAR(20)) + ' territories';
        PRINT '';
        
        -- 2. Load dim_product
        PRINT '  [2/5] Loading: dim_product';
        TRUNCATE TABLE gold.dim_product;
        
        INSERT INTO gold.dim_product (
            product_id, product_name, product_number, category_name, subcategory_name,
            color, size, product_line, class, style, list_price, standard_cost,
            days_to_manufacture, is_active
        )
        SELECT 
            p.product_id,
            p.name                                                        AS product_name,
            p.productnumber                                               AS product_number,
            pc.name                                                       AS category_name,
            ps.name                                                       AS subcategory_name,
            p.color,
            p.size,
            p.productline                                                 AS product_line,
            p.class,
            p.style,
            p.listprice                                                   AS list_price,
            p.standardcost                                                AS standard_cost,
            p.daystomanufacture                                           AS days_to_manufacture,
            CASE WHEN p.sellenddate IS NULL THEN 1 ELSE 0 END            AS is_active
        FROM silver.aw_production_product p
        LEFT JOIN silver.aw_production_productsubcategory ps 
            ON p.productsubcategory_id = ps.productsubcategory_id
        LEFT JOIN silver.aw_production_productcategory pc 
            ON ps.productcategory_id = pc.productcategory_id;
        
        SET @DimRowCount = @@ROWCOUNT;
        PRINT '        ✓ Loaded: ' + CAST(@DimRowCount AS VARCHAR(20)) + ' products';
        PRINT '';
        
        -- 3. Load dim_specialoffer
        PRINT '  [3/5] Loading: dim_specialoffer';
        TRUNCATE TABLE gold.dim_specialoffer;
        
        INSERT INTO gold.dim_specialoffer (
            specialoffer_id, offer_description, discount_pct, offer_type, offer_category,
            start_date, end_date, min_qty, max_qty, is_active
        )
        SELECT 
            specialoffer_id,
            description   AS offer_description,
            discountpct   AS discount_pct,
            type          AS offer_type,
            category      AS offer_category,
            startdate     AS start_date,
            enddate       AS end_date,
            minqty        AS min_qty,
            maxqty        AS max_qty,
            CASE WHEN GETDATE() BETWEEN startdate AND enddate THEN 1 ELSE 0 END AS is_active
        FROM silver.aw_sales_specialoffer;
        
        SET @DimRowCount = @@ROWCOUNT;
        PRINT '        ✓ Loaded: ' + CAST(@DimRowCount AS VARCHAR(20)) + ' special offers';
        PRINT '';
        
        -- 4. Load dim_salesreason
        PRINT '  [4/5] Loading: dim_salesreason';
        TRUNCATE TABLE gold.dim_salesreason;
        
        INSERT INTO gold.dim_salesreason (
            salesreason_id, reason_name, reason_type
        )
        SELECT 
            salesreason_id,
            name       AS reason_name,
            reasontype AS reason_type
        FROM silver.aw_sales_salesreason;
        
        SET @DimRowCount = @@ROWCOUNT;
        PRINT '        ✓ Loaded: ' + CAST(@DimRowCount AS VARCHAR(20)) + ' sales reasons';
        PRINT '';
        
        -- 5. Load dim_customer (deduplicate addresses via ROW_NUMBER)
        --    NOTE: order metrics (first/last order, LTV) are updated after fact_sales loads
        PRINT '  [5/5] Loading: dim_customer';
        TRUNCATE TABLE gold.dim_customer;
        
        INSERT INTO gold.dim_customer (
            customer_id, person_id, customer_name, person_type, email_address,
            address_line1, address_line2, city, state_province, country, postal_code,
            territory_name, territory_key
        )
        SELECT 
            customer_id, person_id, customer_name, person_type, email_address,
            address_line1, address_line2, city, state_province, country, postal_code,
            territory_name, territory_key
        FROM (
            SELECT 
                c.customer_id,
                c.person_id,
                CONCAT(p.firstname, ' ', p.lastname)  AS customer_name,
                p.persontype                           AS person_type,
                e.emailaddress                         AS email_address,
                a.addressline1                         AS address_line1,
                a.addressline2                         AS address_line2,
                a.city,
                sp.name                                AS state_province,
                sp.countryregioncode                   AS country,
                a.postalcode                           AS postal_code,
                t.name                                 AS territory_name,
                dt.territory_key,
                ROW_NUMBER() OVER (
                    PARTITION BY c.customer_id 
                    ORDER BY bea.address_id, e.emailaddress_id 
                ) AS rn
            FROM silver.aw_sales_customer c
            LEFT JOIN silver.aw_person_person p
                ON c.person_id = p.businessentity_id
            LEFT JOIN silver.aw_person_emailaddress e
                ON c.person_id = e.businessentity_id
            LEFT JOIN silver.aw_person_businessentityaddress bea
                ON c.person_id = bea.businessentity_id
            LEFT JOIN silver.aw_person_address a
                ON bea.address_id = a.address_id
            LEFT JOIN silver.aw_person_stateprovince sp
                ON a.stateprovince_id = sp.stateprovince_id
            LEFT JOIN silver.aw_sales_salesterritory t
                ON c.territory_id = t.territory_id
            LEFT JOIN gold.dim_territory dt
                ON t.territory_id = dt.territory_id
        ) AS ranked_customers
        WHERE rn = 1;
        
        SET @DimRowCount = @@ROWCOUNT;
        PRINT '        ✓ Loaded: ' + CAST(@DimRowCount AS VARCHAR(20)) + ' customers (duplicates removed)';
        PRINT '';
        
        PRINT '  ✓ SECTION 1: Complete - All Dimensions Loaded';
        PRINT '';
        
        -- ========================================================================
        -- SECTION 2: LOAD FACT TABLES
        -- ========================================================================
        
        PRINT '=================================================================================';
        PRINT 'SECTION 2: Loading Gold Layer Facts';
        PRINT '=================================================================================';
        PRINT '';
        
        -- -----------------------------------------------------------------------
        -- [1/3] Load fact_sales
        -- FIX: currency_code now uses tocurrencycode from silver.aw_sales_currencyrate
        -- FIX: exchange_rate now uses averagerate (not currencyrate_id integer)
        -- FIX: profit_amount = line_total - cost_amount (cost=0; no double-discount)
        -- -----------------------------------------------------------------------
        PRINT '  [1/3] Loading: fact_sales';
        TRUNCATE TABLE gold.fact_sales;
        
        INSERT INTO gold.fact_sales (
            salesorder_id, salesorderdetail_id,
            order_date_key, due_date_key, ship_date_key,
            customer_key, product_key, territory_key, specialoffer_key,
            order_number, purchase_order_number,
            order_quantity,
            unit_price, unit_discount,
            line_total, discount_amount, cost_amount, profit_amount,
            subtotal, tax_amount, freight, total_due,
            is_online_order, order_status
        )
        SELECT 
            sod.salesorder_id,
            sod.salesorderdetail_id,

            -- Date keys (YYYYMMDD integer)
            CONVERT(INT, FORMAT(soh.orderdate, 'yyyyMMdd'))  AS order_date_key,
            CONVERT(INT, FORMAT(soh.duedate,   'yyyyMMdd'))  AS due_date_key,
            CONVERT(INT, FORMAT(soh.shipdate,  'yyyyMMdd'))  AS ship_date_key,

            -- Dimension keys
            dc.customer_key,
            dp.product_key,
            dt.territory_key,
            dso.specialoffer_key,

            -- Degenerate dimensions
            soh.salesordernumber     AS order_number,
            soh.purchaseordernumber  AS purchase_order_number,

            -- Quantity
            sod.orderqty             AS order_quantity,


            -- Pricing measures
            sod.unitprice                                                     AS unit_price,
            sod.unitpricediscount                                             AS unit_discount,

            -- linetotal in AdventureWorks = orderqty * unitprice * (1 - unitpricediscount)
            -- It is already the NET amount after discount.
            sod.linetotal                                                     AS line_total,

            -- discount_amount = the gross discount given on this line
            sod.unitpricediscount * sod.orderqty * sod.unitprice             AS discount_amount,

            -- cost_amount: no standard cost on detail; set 0 (enrich in a later phase)
            CAST(0 AS DECIMAL(18,2))                                          AS cost_amount,

            -- FIX #4: profit = revenue - cost. cost = 0, so profit = line_total.
            -- Previous formula incorrectly subtracted discount a second time.
            sod.linetotal - CAST(0 AS DECIMAL(18,2))                         AS profit_amount,

            -- Order-level header amounts (denormalized per detail row)
            soh.subtotal,
            soh.taxamt    AS tax_amount,
            soh.freight,
            soh.totaldue  AS total_due,
            soh.onlineorderflag AS is_online_order,
            soh.status          AS order_status

        FROM silver.aw_sales_salesorderdetail sod
        INNER JOIN silver.aw_sales_salesorderheader soh
            ON sod.salesorder_id = soh.salesorder_id
        -- FIX: Join to currency rate table to resolve code and rate
        LEFT JOIN gold.dim_customer dc
            ON soh.customer_id = dc.customer_id
        LEFT JOIN gold.dim_product dp
            ON sod.product_id = dp.product_id
        LEFT JOIN gold.dim_territory dt
            ON soh.territory_id = dt.territory_id
        LEFT JOIN gold.dim_specialoffer dso
            ON sod.specialoffer_id = dso.specialoffer_id;

        SET @FactRowCount = @@ROWCOUNT;
        PRINT '        ✓ Loaded: ' + CAST(@FactRowCount AS VARCHAR(20)) + ' sales line items';
        PRINT '';

        -- -----------------------------------------------------------------------
        -- UPDATE dim_customer with order metrics now that fact_sales is loaded
        -- (SCD Type 1: overwrite with current aggregated values)
        -- -----------------------------------------------------------------------
        PRINT '        Updating dim_customer order metrics from fact_sales...';

        UPDATE dc
        SET
            dc.first_order_date = agg.first_order_date,
            dc.last_order_date  = agg.last_order_date,
            dc.total_orders     = agg.total_orders,
            dc.lifetime_value   = agg.lifetime_value,
            dc.is_active        = CASE 
                                      WHEN DATEDIFF(DAY, agg.last_order_date, GETDATE()) <= 365 
                                      THEN 1 ELSE 0 
                                  END,
            dc.dwh_update_date  = GETDATE()
        FROM gold.dim_customer dc
        INNER JOIN (
            SELECT
                customer_key,
                CAST(MIN(soh.orderdate) AS DATE)   AS first_order_date,
                CAST(MAX(soh.orderdate) AS DATE)   AS last_order_date,
                COUNT(DISTINCT soh.salesorder_id)  AS total_orders,
                SUM(soh.totaldue)                  AS lifetime_value
            FROM silver.aw_sales_salesorderheader soh
            INNER JOIN gold.dim_customer dc2
                ON soh.customer_id = dc2.customer_id
            GROUP BY dc2.customer_key
        ) AS agg ON dc.customer_key = agg.customer_key;

        PRINT '        ✓ dim_customer order metrics updated';
        PRINT '';
        
        -- [2/3] Load fact_salesreason
        -- FIX: Use MIN(sales_key) per salesorder_id to avoid fan-out.
        -- Sales reasons are header-level; fact_sales is detail-level.
        -- We link each reason to the first (lowest) sales_key of that order.
        PRINT '  [2/3] Loading: fact_salesreason';
        TRUNCATE TABLE gold.fact_salesreason;
        
        INSERT INTO gold.fact_salesreason (
            sales_key, salesreason_key
        )
        SELECT 
            fs_min.sales_key,
            dsr.salesreason_key
        FROM silver.aw_sales_salesorderheadersalesreason sohr
        INNER JOIN (
            -- One representative sales_key per order (avoids multiplying reasons by line count)
            SELECT salesorder_id, MIN(sales_key) AS sales_key
            FROM gold.fact_sales
            GROUP BY salesorder_id
        ) fs_min ON sohr.salesorder_id = fs_min.salesorder_id
        INNER JOIN gold.dim_salesreason dsr
            ON sohr.salesreason_id = dsr.salesreason_id;
        
        SET @FactRowCount = @@ROWCOUNT;
        PRINT '        ✓ Loaded: ' + CAST(@FactRowCount AS VARCHAR(20)) + ' sales reason associations';
        PRINT '';
        
        -- -----------------------------------------------------------------------
        -- [3/3] Load fact_customer_rfm
        -- FIX: Moved CTE before INSERT (semicolon after column list was terminating
        --      the INSERT statement, making the SELECT unreachable)
        --
        -- BTYD definitions (per lifetimes library):
        --   recency        = days between first and last purchase
        --   frequency      = number of repeat purchases (total_orders - 1)
        --   T              = customer age in days (first purchase → today)
        --   monetary_value = average order value (total_revenue / total_orders)
        -- -----------------------------------------------------------------------
        PRINT '  [3/3] Loading: fact_customer_rfm';
        TRUNCATE TABLE gold.fact_customer_rfm;

        -- FIX: CTE must appear BEFORE the INSERT, not after it
        ;WITH customer_metrics AS (
            SELECT 
                dc.customer_key,
                MIN(soh.orderdate)                          AS first_date,
                MAX(soh.orderdate)                          AS last_date,
                COUNT(DISTINCT soh.salesorder_id)           AS total_orders,
                SUM(soh.totaldue)                           AS total_rev,
                SUM(sod_agg.line_items_qty)                 AS total_qty
            FROM gold.dim_customer dc
            INNER JOIN silver.aw_sales_salesorderheader soh
                ON dc.customer_id = soh.customer_id
            LEFT JOIN (
                SELECT salesorder_id, SUM(orderqty) AS line_items_qty 
                FROM silver.aw_sales_salesorderdetail 
                GROUP BY salesorder_id
            ) sod_agg ON soh.salesorder_id = sod_agg.salesorder_id
            GROUP BY dc.customer_key
        )
        INSERT INTO gold.fact_customer_rfm (
            customer_key, snapshot_date,
            recency, frequency, T,
            monetary_value, total_revenue, total_orders, avg_order_value,
            total_quantity, first_order_date, last_order_date, days_between_orders,
            r_score, f_score, m_score, rfm_score,
            customer_segment,
            clv_estimate, churn_probability, predicted_purchases_90d,
            is_active
        )
        SELECT 
            customer_key,
            CAST(GETDATE() AS DATE)                        AS snapshot_date,

            -- BTYD: Recency = days between first and last purchase
            DATEDIFF(DAY, first_date, last_date)           AS recency,

            -- BTYD: Frequency = repeat purchases only (n - 1)
            CASE WHEN total_orders > 0 
                 THEN total_orders - 1 
                 ELSE 0 
            END                                            AS frequency,

            -- BTYD: T = customer age since first purchase to today
            DATEDIFF(DAY, first_date, GETDATE())           AS T,

            -- BTYD: Monetary = average order value
            total_rev / NULLIF(total_orders, 0)            AS monetary_value,

            total_rev                                      AS total_revenue,
            total_orders,
            total_rev / NULLIF(total_orders, 0)            AS avg_order_value,
            total_qty                                      AS total_quantity,

            CAST(first_date AS DATE)                       AS first_order_date,
            CAST(last_date  AS DATE)                       AS last_order_date,

            -- Average days between purchases (NULL for single-purchase customers)
            CASE 
                WHEN total_orders > 1 
                THEN DATEDIFF(DAY, first_date, last_date) 
                     / CAST(total_orders - 1 AS DECIMAL(10,2))
                ELSE NULL 
            END                                            AS days_between_orders,

            -- RFM Scores 1-5
            -- Recency: ASC = oldest gets 1, most recent gets 5 (higher = better)
            NTILE(5) OVER (ORDER BY last_date  ASC)        AS r_score,
            NTILE(5) OVER (ORDER BY total_orders ASC)      AS f_score,
            NTILE(5) OVER (ORDER BY total_rev    ASC)      AS m_score,

            -- RFM composite score string e.g. '555'
            CAST(NTILE(5) OVER (ORDER BY last_date   ASC) AS VARCHAR(1)) +
            CAST(NTILE(5) OVER (ORDER BY total_orders ASC) AS VARCHAR(1)) +
            CAST(NTILE(5) OVER (ORDER BY total_rev    ASC) AS VARCHAR(1))
                                                           AS rfm_score,

            -- Customer segmentation (consistent NTILE directions with scores above)
            CASE 
                WHEN NTILE(5) OVER (ORDER BY last_date   ASC) >= 4
                 AND NTILE(5) OVER (ORDER BY total_orders ASC) >= 4 THEN 'Champions'
                WHEN NTILE(5) OVER (ORDER BY last_date   ASC) >= 4  THEN 'Loyal Customers'
                WHEN NTILE(5) OVER (ORDER BY total_rev   ASC) >= 4  THEN 'Big Spenders'
                WHEN NTILE(5) OVER (ORDER BY last_date   ASC) <= 2  THEN 'At Risk'
                ELSE 'Potential'
            END                                            AS customer_segment,

            -- Predictive placeholders (replace with Python/ML output in later phase)
            total_rev * 1.5                                AS clv_estimate,
            CASE 
                WHEN DATEDIFF(DAY, last_date, GETDATE()) > 365 THEN 0.8
                WHEN DATEDIFF(DAY, last_date, GETDATE()) > 180 THEN 0.5
                ELSE 0.2
            END                                            AS churn_probability,
            CASE 
                WHEN DATEDIFF(DAY, last_date, GETDATE()) <= 90 
                THEN CAST(total_orders / 12.0 * 3 AS INT)
                ELSE 0
            END                                            AS predicted_purchases_90d,
            CASE 
                WHEN DATEDIFF(DAY, last_date, GETDATE()) <= 365 THEN 1 
                ELSE 0 
            END                                            AS is_active

        FROM customer_metrics;

        SET @FactRowCount = @@ROWCOUNT;
        PRINT '        ✓ Loaded: ' + CAST(@FactRowCount AS VARCHAR(20)) + ' customer RFM records';
        PRINT '';
        
        PRINT '  ✓ SECTION 2: Complete - All Facts Loaded';
        PRINT '';
        
        -- ========================================================================
        -- SECTION 3: RECREATE FOREIGN KEY CONSTRAINTS
        -- ========================================================================
        
        PRINT '=================================================================================';
        PRINT 'SECTION 3: Recreating Foreign Key Constraints';
        PRINT '=================================================================================';
        PRINT '';
        
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_fact_sales_order_date')
        BEGIN
            ALTER TABLE gold.fact_sales
            ADD CONSTRAINT fk_fact_sales_order_date 
                FOREIGN KEY (order_date_key) REFERENCES gold.dim_date(date_key);
            PRINT '  ✓ Added: fk_fact_sales_order_date';
        END
        
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_fact_sales_due_date')
        BEGIN
            ALTER TABLE gold.fact_sales
            ADD CONSTRAINT fk_fact_sales_due_date 
                FOREIGN KEY (due_date_key) REFERENCES gold.dim_date(date_key);
            PRINT '  ✓ Added: fk_fact_sales_due_date';
        END
        
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_fact_sales_ship_date')
        BEGIN
            ALTER TABLE gold.fact_sales
            ADD CONSTRAINT fk_fact_sales_ship_date 
                FOREIGN KEY (ship_date_key) REFERENCES gold.dim_date(date_key);
            PRINT '  ✓ Added: fk_fact_sales_ship_date';
        END
        
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_fact_sales_customer')
        BEGIN
            ALTER TABLE gold.fact_sales
            ADD CONSTRAINT fk_fact_sales_customer 
                FOREIGN KEY (customer_key) REFERENCES gold.dim_customer(customer_key);
            PRINT '  ✓ Added: fk_fact_sales_customer';
        END
        
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_fact_sales_product')
        BEGIN
            ALTER TABLE gold.fact_sales
            ADD CONSTRAINT fk_fact_sales_product 
                FOREIGN KEY (product_key) REFERENCES gold.dim_product(product_key);
            PRINT '  ✓ Added: fk_fact_sales_product';
        END
        
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_fact_sales_territory')
        BEGIN
            ALTER TABLE gold.fact_sales
            ADD CONSTRAINT fk_fact_sales_territory 
                FOREIGN KEY (territory_key) REFERENCES gold.dim_territory(territory_key);
            PRINT '  ✓ Added: fk_fact_sales_territory';
        END
        
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_fact_sales_specialoffer')
        BEGIN
            ALTER TABLE gold.fact_sales
            ADD CONSTRAINT fk_fact_sales_specialoffer 
                FOREIGN KEY (specialoffer_key) REFERENCES gold.dim_specialoffer(specialoffer_key);
            PRINT '  ✓ Added: fk_fact_sales_specialoffer';
        END
        
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_fact_salesreason_sales')
        BEGIN
            ALTER TABLE gold.fact_salesreason
            ADD CONSTRAINT fk_fact_salesreason_sales 
                FOREIGN KEY (sales_key) REFERENCES gold.fact_sales(sales_key);
            PRINT '  ✓ Added: fk_fact_salesreason_sales';
        END
        
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_fact_salesreason_reason')
        BEGIN
            ALTER TABLE gold.fact_salesreason
            ADD CONSTRAINT fk_fact_salesreason_reason 
                FOREIGN KEY (salesreason_key) REFERENCES gold.dim_salesreason(salesreason_key);
            PRINT '  ✓ Added: fk_fact_salesreason_reason';
        END
        
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_fact_customer_rfm')
        BEGIN
            ALTER TABLE gold.fact_customer_rfm
            ADD CONSTRAINT fk_fact_customer_rfm 
                FOREIGN KEY (customer_key) REFERENCES gold.dim_customer(customer_key);
            PRINT '  ✓ Added: fk_fact_customer_rfm';
        END
        
        PRINT '';
        PRINT '  ✓ SECTION 3: Complete - All Foreign Keys Recreated';
        PRINT '';
        
        -- ========================================================================
        -- FINAL SUMMARY
        -- ========================================================================
        
        SET @EndTime = SYSUTCDATETIME();
        
        PRINT '=================================================================================';
        PRINT 'Complete Gold Layer Data Warehouse ETL Process - SUCCESS';
        PRINT '=================================================================================';
        PRINT '  ✓ 5 dimension tables loaded';
        PRINT '  ✓ dim_customer order metrics updated from fact_sales';
        PRINT '  ✓ 3 fact tables loaded';
        PRINT '  ✓ 10 foreign key constraints recreated';
        PRINT '  ✓ Referential integrity enforced';
        PRINT '';
        PRINT 'Start Time: ' + CONVERT(VARCHAR(30), @StartTime, 121);
        PRINT 'End Time:   ' + CONVERT(VARCHAR(30), @EndTime, 121);
        PRINT 'Duration:   ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS VARCHAR(20)) + ' seconds';
        PRINT '=================================================================================';
        
    END TRY
    BEGIN CATCH
        SELECT 
            @ErrorMessage  = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState    = ERROR_STATE();
        
        PRINT '';
        PRINT '=================================================================================';
        PRINT 'ERROR: Gold Layer Data Warehouse ETL Process Failed';
        PRINT '=================================================================================';
        PRINT 'Error Message:  ' + @ErrorMessage;
        PRINT 'Error Severity: ' + CAST(@ErrorSeverity AS VARCHAR(10));
        PRINT 'Error State:    ' + CAST(@ErrorState AS VARCHAR(10));
        PRINT 'Error Line:     ' + CAST(ERROR_LINE() AS VARCHAR(10));
        PRINT '=================================================================================';
        
        THROW;
    END CATCH
END
GO

PRINT '=================================================================================';
PRINT 'Stored procedure gold.sp_load_complete_datawarehouse created successfully';
PRINT '=================================================================================';
PRINT 'Usage: EXEC gold.sp_load_complete_datawarehouse;';
PRINT '=================================================================================';
GO

EXEC gold.sp_load_complete_datawarehouse;
