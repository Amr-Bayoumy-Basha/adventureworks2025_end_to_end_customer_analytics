/*
=================================================================================
Gold Layer ETL Stored Procedure – Production Data Warehouse Loader
=================================================================================
VERSION  : 2.0
AUTHOR   : Amr Bayomei Basha
DATE     : May 2026
TARGET   : SQL Server – AdventureWorks2025_CustomerDW
DATABASE : Run in [AdventureWorks2025_CustomerDW] context (no USE statement)

CHANGES FROM v1.0
─────────────────────────────────────────────────────────────────────────────────
  1.  [ARCHITECTURE]  TRUNCATE+INSERT replaced with SCD Type 1 MERGE for all 5
                      dimension tables – surrogate keys are now preserved across
                      every ETL run.
  2.  [COGS/MARGIN]   cost_amount  = dim_product.standard_cost × order_quantity
                      gross_profit = line_total − cost_amount
                      (Column renamed from profit_amount throughout.)
  3.  [REVENUE]       All customer-analytics revenue now consistently uses
                      SUM(fact_sales.line_total).  soh.totaldue (which includes
                      tax + freight) is no longer used for analytics.
  4.  [PARETO]        Restored dim_customer Pareto columns
                      (revenue_cumulative, revenue_pareto_pct,
                       qty_cumulative,     qty_pareto_pct)
                      populated via a dedicated UPDATE after order-metrics phase.
                      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW used to
                      prevent tie-inflation from default RANGE framing.
  5.  [DATES]         @ObservationEndDate = MAX(orderdate) replaces GETDATE() in
                      all analytical logic.  GETDATE() retained only for ETL
                      audit timestamps (dwh_update_date / dwh_load_date).
  6.  [PERF]          Date-key conversion: CONVERT(INT, CONVERT(CHAR(8),...,112))
                      – FORMAT() never used.
  7.  [RFM CTEs]      order_metrics CTE prevents duplication; scored CTE
                      calculates NTILE scores once and reuses downstream.
  8.  [TRANSACTION]   Full BEGIN / COMMIT TRANSACTION with ROLLBACK in CATCH –
                      prevents partial warehouse loads.
  9.  [SEQUENCE]      Load fact_sales → update order metrics → update Pareto →
                      load fact_salesreason → load fact_customer_rfm → recreate FKs.
=================================================================================
*/

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
    DECLARE @ObservationEndDate DATE;           -- dataset anchor; replaces GETDATE() for analytics

    BEGIN TRY

        -- ────────────────────────────────────────────────────────────────────
        -- Resolve the dataset observation date once.
        -- Every analytical calculation (RFM, BTYD, churn, active flag, etc.)
        -- must reference @ObservationEndDate instead of GETDATE() so that the
        -- warehouse remains historically reproducible on a static dataset.
        -- ────────────────────────────────────────────────────────────────────
        SELECT @ObservationEndDate = CAST(MAX(orderdate) AS DATE)
        FROM silver.aw_sales_salesorderheader;

        PRINT '=================================================================================';
        PRINT 'Gold Layer ETL  –  Complete Data Warehouse Loader  v2.0';
        PRINT 'ETL Start Time     : ' + CONVERT(VARCHAR(30), @StartTime, 121);
        PRINT 'Observation Date   : ' + CONVERT(VARCHAR(10), @ObservationEndDate, 120);
        PRINT '=================================================================================';
        PRINT '';

        -- ====================================================================
        -- STEP 0: DROP ALL FOREIGN KEY CONSTRAINTS IN GOLD SCHEMA
        -- Must run before BEGIN TRANSACTION so that ALTER TABLE DDL for FK
        -- recreation inside the transaction does not cause implicit commits.
        -- ====================================================================
        PRINT '[STEP 0] Dropping all foreign keys in [gold] schema...';

        SET @SQL = N'';

        SELECT @SQL += N'ALTER TABLE '
                     + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
                     + N' DROP CONSTRAINT ' + QUOTENAME(fk.name) + N';' + CHAR(13)
        FROM sys.foreign_keys  AS fk
        INNER JOIN sys.tables  AS t  ON fk.parent_object_id = t.object_id
        INNER JOIN sys.schemas AS s  ON t.schema_id         = s.schema_id
        WHERE s.name = N'gold';

        IF @SQL <> N''
        BEGIN
            EXEC sp_executesql @SQL;
            PRINT '  ✓ All gold foreign keys dropped.';
        END
        ELSE
            PRINT '  – No foreign keys found in [gold] schema.';

        PRINT '';

        -- ====================================================================
        -- BEGIN ATOMIC TRANSACTION
        -- All dimension merges, fact loads, metric updates and FK recreations
        -- are wrapped in a single transaction.  Any failure triggers a full
        -- rollback so the warehouse is never left in a partial state.
        -- ====================================================================
        BEGIN TRANSACTION;

        -- ====================================================================
        -- SECTION 1: LOAD DIMENSION TABLES  (SCD Type 1 MERGE)
        -- MERGE preserves surrogate keys for existing rows.
        -- New source rows receive a new identity surrogate key on INSERT.
        -- Missing source rows are NOT deleted (no WHEN NOT MATCHED BY SOURCE).
        -- ====================================================================
        PRINT '=================================================================================';
        PRINT 'SECTION 1: Loading Dimension Tables  (SCD Type 1 MERGE)';
        PRINT '=================================================================================';
        PRINT '';

        -- ──────────────────────────────────────────────────────────────────
        -- [1/5] dim_territory
        -- ──────────────────────────────────────────────────────────────────
        PRINT '  [1/5] Merging: dim_territory';

        MERGE gold.dim_territory AS tgt
        USING (
            SELECT
                territory_id,
                name              AS territory_name,
                countryregioncode AS country_code,
                [group]           AS region_group
            FROM silver.aw_sales_salesterritory
        ) AS src
            ON tgt.territory_id = src.territory_id
        WHEN MATCHED THEN
            UPDATE SET
                tgt.territory_name = src.territory_name,
                tgt.country_code   = src.country_code,
                tgt.region_group   = src.region_group
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (territory_id, territory_name, country_code, region_group)
            VALUES (src.territory_id, src.territory_name, src.country_code, src.region_group);
        -- (no WHEN NOT MATCHED BY SOURCE clause = no hard deletes)

        SET @DimRowCount = @@ROWCOUNT;
        PRINT '        ✓ Merged: ' + CAST(@DimRowCount AS VARCHAR(20)) + ' territory rows affected';
        PRINT '';

        -- ──────────────────────────────────────────────────────────────────
        -- [2/5] dim_product
        -- standard_cost is brought into the dimension so that fact_sales can
        -- join once at load time and calculate COGS without a silver re-read.
        -- ──────────────────────────────────────────────────────────────────
        PRINT '  [2/5] Merging: dim_product';

        MERGE gold.dim_product AS tgt
        USING (
            SELECT
                p.product_id,
                p.name                                             AS product_name,
                p.productnumber                                    AS product_number,
                pc.name                                            AS category_name,
                ps.name                                            AS subcategory_name,
                p.color,
                p.size,
                p.productline                                      AS product_line,
                p.class,
                p.style,
                p.listprice                                        AS list_price,
                p.standardcost                                     AS standard_cost,
                p.daystomanufacture                                AS days_to_manufacture,
                CASE WHEN p.sellenddate IS NULL THEN 1 ELSE 0 END AS is_active
            FROM silver.aw_production_product p
            LEFT JOIN silver.aw_production_productsubcategory ps
                ON p.productsubcategory_id = ps.productsubcategory_id
            LEFT JOIN silver.aw_production_productcategory pc
                ON ps.productcategory_id = pc.productcategory_id
        ) AS src
            ON tgt.product_id = src.product_id
        WHEN MATCHED THEN
            UPDATE SET
                tgt.product_name        = src.product_name,
                tgt.product_number      = src.product_number,
                tgt.category_name       = src.category_name,
                tgt.subcategory_name    = src.subcategory_name,
                tgt.color               = src.color,
                tgt.size                = src.size,
                tgt.product_line        = src.product_line,
                tgt.class               = src.class,
                tgt.style               = src.style,
                tgt.list_price          = src.list_price,
                tgt.standard_cost       = src.standard_cost,
                tgt.days_to_manufacture = src.days_to_manufacture,
                tgt.is_active           = src.is_active
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                product_id, product_name, product_number, category_name, subcategory_name,
                color, size, product_line, class, style,
                list_price, standard_cost, days_to_manufacture, is_active
            )
            VALUES (
                src.product_id, src.product_name, src.product_number, src.category_name, src.subcategory_name,
                src.color, src.size, src.product_line, src.class, src.style,
                src.list_price, src.standard_cost, src.days_to_manufacture, src.is_active
            );

        SET @DimRowCount = @@ROWCOUNT;
        PRINT '        ✓ Merged: ' + CAST(@DimRowCount AS VARCHAR(20)) + ' product rows affected';
        PRINT '';

        -- ──────────────────────────────────────────────────────────────────
        -- [3/5] dim_specialoffer
        -- is_active uses @ObservationEndDate (not GETDATE()) so that the flag
        -- correctly reflects offer activity at the dataset's observation point.
        -- ──────────────────────────────────────────────────────────────────
        PRINT '  [3/5] Merging: dim_specialoffer';

        MERGE gold.dim_specialoffer AS tgt
        USING (
            SELECT
                specialoffer_id,
                description AS offer_description,
                discountpct AS discount_pct,
                type        AS offer_type,
                category    AS offer_category,
                startdate   AS start_date,
                enddate     AS end_date,
                minqty      AS min_qty,
                maxqty      AS max_qty,
                -- Analytical active flag: anchored to dataset observation date, not wall-clock
                CASE WHEN @ObservationEndDate BETWEEN startdate AND enddate
                     THEN 1 ELSE 0
                END         AS is_active
            FROM silver.aw_sales_specialoffer
        ) AS src
            ON tgt.specialoffer_id = src.specialoffer_id
        WHEN MATCHED THEN
            UPDATE SET
                tgt.offer_description = src.offer_description,
                tgt.discount_pct      = src.discount_pct,
                tgt.offer_type        = src.offer_type,
                tgt.offer_category    = src.offer_category,
                tgt.start_date        = src.start_date,
                tgt.end_date          = src.end_date,
                tgt.min_qty           = src.min_qty,
                tgt.max_qty           = src.max_qty,
                tgt.is_active         = src.is_active
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                specialoffer_id, offer_description, discount_pct, offer_type, offer_category,
                start_date, end_date, min_qty, max_qty, is_active
            )
            VALUES (
                src.specialoffer_id, src.offer_description, src.discount_pct, src.offer_type, src.offer_category,
                src.start_date, src.end_date, src.min_qty, src.max_qty, src.is_active
            );

        SET @DimRowCount = @@ROWCOUNT;
        PRINT '        ✓ Merged: ' + CAST(@DimRowCount AS VARCHAR(20)) + ' special offer rows affected';
        PRINT '';

        -- ──────────────────────────────────────────────────────────────────
        -- [4/5] dim_salesreason
        -- ──────────────────────────────────────────────────────────────────
        PRINT '  [4/5] Merging: dim_salesreason';

        MERGE gold.dim_salesreason AS tgt
        USING (
            SELECT
                salesreason_id,
                name       AS reason_name,
                reasontype AS reason_type
            FROM silver.aw_sales_salesreason
        ) AS src
            ON tgt.salesreason_id = src.salesreason_id
        WHEN MATCHED THEN
            UPDATE SET
                tgt.reason_name = src.reason_name,
                tgt.reason_type = src.reason_type
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (salesreason_id, reason_name, reason_type)
            VALUES (src.salesreason_id, src.reason_name, src.reason_type);

        SET @DimRowCount = @@ROWCOUNT;
        PRINT '        ✓ Merged: ' + CAST(@DimRowCount AS VARCHAR(20)) + ' sales reason rows affected';
        PRINT '';

        -- ──────────────────────────────────────────────────────────────────
        -- [5/5] dim_customer – structural attributes only
        -- Address deduplication via ROW_NUMBER on (address_id, emailaddress_id).
        -- NOTE: territory_key only (no territory_name) – avoids redundant
        -- descriptive duplication; join to dim_territory for the name.
        -- Order-metric columns (first/last order, LTV, Pareto) are populated
        -- in dedicated UPDATE steps below, after fact_sales has loaded.
        -- dwh_update_date uses GETDATE() – this is an ETL audit timestamp,
        -- not an analytical date, so it correctly reflects wall-clock time.
        -- ──────────────────────────────────────────────────────────────────
        PRINT '  [5/5] Merging: dim_customer (structural attributes; order metrics updated later)';

        ;WITH ranked_customers AS (
            SELECT
                c.customer_id,
                c.person_id,
                CONCAT(p.firstname, ' ', p.lastname) AS customer_name,
                p.persontype                          AS person_type,
                e.emailaddress                        AS email_address,
                a.addressline1                        AS address_line1,
                a.addressline2                        AS address_line2,
                a.city,
                sp.name                               AS state_province,
                sp.countryregioncode                  AS country,
                a.postalcode                          AS postal_code,
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
            LEFT JOIN gold.dim_territory dt
                ON c.territory_id = dt.territory_id
        )
        MERGE gold.dim_customer AS tgt
        USING (
            SELECT customer_id, person_id, customer_name, person_type, email_address,
                   address_line1, address_line2, city, state_province, country,
                   postal_code, territory_key
            FROM ranked_customers
            WHERE rn = 1
        ) AS src
            ON tgt.customer_id = src.customer_id
        WHEN MATCHED THEN
            UPDATE SET
                tgt.person_id      = src.person_id,
                tgt.customer_name  = src.customer_name,
                tgt.person_type    = src.person_type,
                tgt.email_address  = src.email_address,
                tgt.address_line1  = src.address_line1,
                tgt.address_line2  = src.address_line2,
                tgt.city           = src.city,
                tgt.state_province = src.state_province,
                tgt.country        = src.country,
                tgt.postal_code    = src.postal_code,
                tgt.territory_key  = src.territory_key,
                tgt.dwh_update_date = GETDATE()   -- ETL audit metadata – intentional GETDATE()
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                customer_id, person_id, customer_name, person_type, email_address,
                address_line1, address_line2, city, state_province, country,
                postal_code, territory_key
            )
            VALUES (
                src.customer_id, src.person_id, src.customer_name, src.person_type, src.email_address,
                src.address_line1, src.address_line2, src.city, src.state_province, src.country,
                src.postal_code, src.territory_key
            );

        SET @DimRowCount = @@ROWCOUNT;
        PRINT '        ✓ Merged: ' + CAST(@DimRowCount AS VARCHAR(20)) + ' customer rows affected (duplicates deduplicated via ROW_NUMBER)';
        PRINT '';
        PRINT '  ✓ SECTION 1 Complete – All 5 Dimensions Merged (SCD Type 1, surrogate keys preserved)';
        PRINT '';

        -- ====================================================================
        -- SECTION 2: LOAD FACT TABLES
        -- Sequence: fact_sales → dim_customer order metrics → dim_customer
        --           Pareto → fact_salesreason → fact_customer_rfm
        -- ====================================================================
        PRINT '=================================================================================';
        PRINT 'SECTION 2: Loading Fact Tables';
        PRINT '=================================================================================';
        PRINT '';

        -- ──────────────────────────────────────────────────────────────────
        -- [1/3] fact_sales
        --
        -- COGS / Gross Profit:
        --   cost_amount  = ISNULL(dim_product.standard_cost, 0) × order_quantity
        --   gross_profit = line_total − cost_amount
        --   (renamed from profit_amount; no longer zeroed out)
        --
        -- Revenue definition:
        --   line_total  = orderqty × unitprice × (1 − unitpricediscount)
        --   This is the net post-discount amount and is the warehouse's single
        --   canonical revenue measure.  soh.totaldue (tax + freight included)
        --   is stored for drill-through but NOT used in analytics.
        --
        -- Date key conversion: CONVERT(INT, CONVERT(CHAR(8), col, 112))
        --   Avoids FORMAT() overhead while producing clean YYYYMMDD integers.
        -- ──────────────────────────────────────────────────────────────────
        PRINT '  [1/3] Loading: fact_sales';
        TRUNCATE TABLE gold.fact_sales;

        INSERT INTO gold.fact_sales (
            salesorder_id, salesorderdetail_id,
            order_date_key, due_date_key, ship_date_key,
            customer_key, product_key, territory_key, specialoffer_key,
            order_number, purchase_order_number,
            order_quantity,
            unit_price, unit_discount,
            line_total, discount_amount, cost_amount, gross_profit,
            subtotal, tax_amount, freight, total_due,
            is_online_order, order_status
        )
        SELECT
            sod.salesorder_id,
            sod.salesorderdetail_id,

            -- ── Date keys (YYYYMMDD integer; no FORMAT() overhead) ──────
            CONVERT(INT, CONVERT(CHAR(8), soh.orderdate, 112)) AS order_date_key,
            CONVERT(INT, CONVERT(CHAR(8), soh.duedate,   112)) AS due_date_key,
            CONVERT(INT, CONVERT(CHAR(8), soh.shipdate,  112)) AS ship_date_key,

            -- ── Dimension keys ──────────────────────────────────────────
            dc.customer_key,
            dp.product_key,
            dt.territory_key,
            dso.specialoffer_key,

            -- ── Degenerate dimensions ───────────────────────────────────
            soh.salesordernumber    AS order_number,
            soh.purchaseordernumber AS purchase_order_number,

            -- ── Quantity ────────────────────────────────────────────────
            sod.orderqty            AS order_quantity,

            -- ── Pricing measures ────────────────────────────────────────
            sod.unitprice           AS unit_price,
            sod.unitpricediscount   AS unit_discount,

            -- Net revenue after discount (AW computed column)
            sod.linetotal           AS line_total,

            -- Gross discount surrendered on this line
            sod.unitpricediscount * sod.orderqty * sod.unitprice          AS discount_amount,

            -- COGS: standard_cost × units (0 when no standard cost on record)
            ISNULL(dp.standard_cost, 0) * sod.orderqty                    AS cost_amount,

            -- Gross profit = net revenue − COGS
            sod.linetotal - ISNULL(dp.standard_cost, 0) * sod.orderqty    AS gross_profit,

            -- ── Order-header amounts (denormalised; informational only) ──
            soh.subtotal,
            soh.taxamt   AS tax_amount,
            soh.freight,
            soh.totaldue AS total_due,   -- stored for drill-through; NOT used in analytics

            soh.onlineorderflag AS is_online_order,
            soh.status          AS order_status

        FROM silver.aw_sales_salesorderdetail sod
        INNER JOIN silver.aw_sales_salesorderheader soh
            ON sod.salesorder_id = soh.salesorder_id
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

        -- ──────────────────────────────────────────────────────────────────
        -- UPDATE dim_customer – ORDER METRICS
        -- Revenue: SUM(fact_sales.line_total) via an order-level aggregation
        -- CTE.  Using soh.totaldue would inflate LTV with tax and freight.
        -- is_active uses @ObservationEndDate (historical dataset anchor).
        -- dwh_update_date uses GETDATE() (ETL audit timestamp – intentional).
        -- ──────────────────────────────────────────────────────────────────
        PRINT '        Updating dim_customer order metrics from fact_sales...';

        ;WITH order_metrics AS (
            -- Aggregate to order level first to prevent detail-row fan-out
            SELECT
                customer_key,
                salesorder_id,
                SUM(line_total)     AS order_revenue,
                SUM(order_quantity) AS order_qty
            FROM gold.fact_sales
            GROUP BY customer_key, salesorder_id
        ),
        customer_agg AS (
            SELECT
                om.customer_key,
                CAST(MIN(soh.orderdate) AS DATE)  AS first_order_date,
                CAST(MAX(soh.orderdate) AS DATE)  AS last_order_date,
                COUNT(DISTINCT om.salesorder_id)  AS total_orders,
                SUM(om.order_revenue)             AS lifetime_value
            FROM order_metrics om
            INNER JOIN silver.aw_sales_salesorderheader soh
                ON om.salesorder_id = soh.salesorder_id
            GROUP BY om.customer_key
        )
        UPDATE dc
        SET
            dc.first_order_date = ca.first_order_date,
            dc.last_order_date  = ca.last_order_date,
            dc.total_orders     = ca.total_orders,
            dc.lifetime_value   = ca.lifetime_value,
            -- is_active: anchored to dataset observation date, not wall-clock
            dc.is_active        = CASE
                                      WHEN DATEDIFF(DAY, ca.last_order_date, @ObservationEndDate) <= 365
                                      THEN 1 ELSE 0
                                  END,
            dc.dwh_update_date  = GETDATE()   -- ETL audit timestamp – intentional GETDATE()
        FROM gold.dim_customer dc
        INNER JOIN customer_agg ca
            ON dc.customer_key = ca.customer_key;

        PRINT '        ✓ dim_customer order metrics updated (revenue = SUM(fact_sales.line_total))';
        PRINT '';

        -- ──────────────────────────────────────────────────────────────────
        -- UPDATE dim_customer – PARETO (ABC) METRICS
        -- Uses ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW in the window
        -- frame to prevent cumulative sum inflation caused by tied revenue
        -- values (SQL Server default RANGE framing groups ties, overstating
        -- the running total for all but the last tied row).
        -- ──────────────────────────────────────────────────────────────────
        PRINT '        Updating dim_customer Pareto (ABC) metrics...';

        ;WITH CustomerTotals AS (
            SELECT
                customer_key,
                SUM(line_total)     AS total_revenue,
                SUM(order_quantity) AS total_qty
            FROM gold.fact_sales
            GROUP BY customer_key
        ),
        ParetoCalc AS (
            SELECT
                customer_key,
                -- Running cumulative revenue ranked highest-to-lowest
                SUM(total_revenue) OVER (
                    ORDER BY total_revenue DESC
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                )                                    AS revenue_cumulative,
                -- Running cumulative quantity ranked highest-to-lowest
                SUM(total_qty) OVER (
                    ORDER BY total_qty DESC
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                )                                    AS qty_cumulative,
                SUM(total_revenue) OVER ()           AS grand_total_revenue,
                SUM(total_qty)     OVER ()           AS grand_total_qty
            FROM CustomerTotals
        )
        UPDATE dc
        SET
            dc.revenue_cumulative = p.revenue_cumulative,
            dc.revenue_pareto_pct = CAST(
                                        p.revenue_cumulative
                                        / NULLIF(p.grand_total_revenue, 0) * 100
                                    AS DECIMAL(10, 4)),
            dc.qty_cumulative     = p.qty_cumulative,
            dc.qty_pareto_pct     = CAST(
                                        p.qty_cumulative * 1.0 -- Forcing decimal division because order_quantity is an INT
                                        / NULLIF(p.grand_total_qty, 0) * 100
                                    AS DECIMAL(10, 4)),
            dc.dwh_update_date    = GETDATE()   -- ETL audit timestamp – intentional GETDATE()
        FROM gold.dim_customer dc
        INNER JOIN ParetoCalc p
            ON dc.customer_key = p.customer_key;

        PRINT '        ✓ dim_customer Pareto metrics updated (ROWS framing; tie-safe)';
        PRINT '';

        -- ──────────────────────────────────────────────────────────────────
        -- [2/3] fact_salesreason
        -- Sales reasons are header-level; fact_sales is detail-level.
        -- Anti-fan-out: MIN(sales_key) per salesorder_id links each reason
        -- to a single representative row rather than multiplying by line count.
        -- ──────────────────────────────────────────────────────────────────
        PRINT '  [2/3] Loading: fact_salesreason';
        TRUNCATE TABLE gold.fact_salesreason;

        INSERT INTO gold.fact_salesreason (sales_key, salesreason_key)
        SELECT
            fs_min.sales_key,
            dsr.salesreason_key
        FROM silver.aw_sales_salesorderheadersalesreason sohr
        INNER JOIN (
            -- One representative fact_sales key per order (lowest = most stable)
            SELECT salesorder_id, MIN(sales_key) AS sales_key
            FROM gold.fact_sales
            GROUP BY salesorder_id
        ) fs_min
            ON sohr.salesorder_id = fs_min.salesorder_id
        INNER JOIN gold.dim_salesreason dsr
            ON sohr.salesreason_id = dsr.salesreason_id;

        SET @FactRowCount = @@ROWCOUNT;
        PRINT '        ✓ Loaded: ' + CAST(@FactRowCount AS VARCHAR(20)) + ' sales reason associations';
        PRINT '';

        -- ──────────────────────────────────────────────────────────────────
        -- [3/3] fact_customer_rfm
        --
        -- Revenue source: gold.fact_sales.line_total (consistent with rest
        -- of warehouse; never soh.totaldue which includes tax + freight).
        --
        -- Architecture: three-layer CTE pipeline
        --   order_metrics    → order-level aggregation (prevents fan-out)
        --   customer_metrics → customer-level rollup from order_metrics
        --   scored           → NTILE scores calculated once (r/f/m each NTILE(5))
        --
        -- BTYD model definitions (per lifetimes library convention):
        --   recency        = days between first and last purchase
        --   frequency      = repeat purchases (total_orders − 1)
        --   T              = customer age: first purchase → @ObservationEndDate
        --   monetary_value = average order value (total_revenue / total_orders)
        --
        -- All analytical date comparisons reference @ObservationEndDate so
        -- the model is reproducible on a static historical dataset.
        -- ──────────────────────────────────────────────────────────────────
        PRINT '  [3/3] Loading: fact_customer_rfm';
        TRUNCATE TABLE gold.fact_customer_rfm;

        ;WITH order_metrics AS (
            -- Layer 1: aggregate to order level to prevent detail fan-out
            SELECT
                customer_key,
                salesorder_id,
                SUM(line_total)     AS order_revenue,
                SUM(order_quantity) AS order_qty
            FROM gold.fact_sales
            GROUP BY customer_key, salesorder_id
        ),
        customer_metrics AS (
            -- Layer 2: roll up to customer level using order-level aggregates
            SELECT
                om.customer_key,
                MIN(soh.orderdate)               AS first_date,
                MAX(soh.orderdate)               AS last_date,
                COUNT(DISTINCT om.salesorder_id) AS total_orders,
                SUM(om.order_revenue)            AS total_rev,
                SUM(om.order_qty)                AS total_qty
            FROM order_metrics om
            INNER JOIN silver.aw_sales_salesorderheader soh
                ON om.salesorder_id = soh.salesorder_id
            GROUP BY om.customer_key
        ),
        scored AS (
            -- Layer 3: calculate all three NTILE scores exactly once
            -- Higher bucket = better customer on each dimension
            SELECT
                customer_key,
                first_date,
                last_date,
                total_orders,
                total_rev,
                total_qty,
                NTILE(5) OVER (ORDER BY last_date    ASC) AS r_score,   -- most recent → 5
                NTILE(5) OVER (ORDER BY total_orders ASC) AS f_score,   -- most frequent → 5
                NTILE(5) OVER (ORDER BY total_rev    ASC) AS m_score    -- highest spend → 5
            FROM customer_metrics
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
            @ObservationEndDate                                    AS snapshot_date,

            -- ── BTYD: Recency = days between first and last purchase ─────
            DATEDIFF(DAY, first_date, last_date)                   AS recency,

            -- ── BTYD: Frequency = repeat purchases only (n − 1) ─────────
            CASE WHEN total_orders > 0 THEN total_orders - 1 ELSE 0 END
                                                                   AS frequency,

            -- ── BTYD: T = customer age from first purchase to observation ─
            DATEDIFF(DAY, first_date, @ObservationEndDate)         AS T,

            -- ── BTYD: Monetary = average order value (line_total revenue) ─
            total_rev / NULLIF(total_orders, 0)                    AS monetary_value,

            total_rev                                              AS total_revenue,
            total_orders,
            total_rev / NULLIF(total_orders, 0)                    AS avg_order_value,
            total_qty                                              AS total_quantity,

            CAST(first_date AS DATE)                               AS first_order_date,
            CAST(last_date  AS DATE)                               AS last_order_date,

            -- Average inter-purchase interval (NULL for one-time buyers)
            CASE
                WHEN total_orders > 1
                THEN DATEDIFF(DAY, first_date, last_date)
                     / CAST(total_orders - 1 AS DECIMAL(10, 2))
                ELSE NULL
            END                                                    AS days_between_orders,

            -- ── RFM scores (from scored CTE – calculated once above) ─────
            r_score,
            f_score,
            m_score,

            -- Composite score string e.g. '555' = Champion
            CAST(r_score AS VARCHAR(1)) +
            CAST(f_score AS VARCHAR(1)) +
            CAST(m_score AS VARCHAR(1))                            AS rfm_score,

            -- ── Customer segmentation (aligned with NTILE direction: 5=best) ─
            CASE
                WHEN r_score >= 4 AND f_score >= 4 THEN 'Champions'
                WHEN r_score >= 4                  THEN 'Loyal Customers'
                WHEN m_score >= 4                  THEN 'Big Spenders'
                WHEN r_score <= 2                  THEN 'At Risk'
                ELSE                                    'Potential'
            END                                                    AS customer_segment,

            -- ── Predictive placeholders ──────────────────────────────────
            -- Replace with Python/ML pipeline output in a later phase.
            -- CLV uses line_total-based revenue for warehouse consistency.
            total_rev * 1.5                                        AS clv_estimate,

            -- Churn probability: anchored to @ObservationEndDate (not GETDATE())
            CASE
                WHEN DATEDIFF(DAY, last_date, @ObservationEndDate) > 365 THEN 0.8
                WHEN DATEDIFF(DAY, last_date, @ObservationEndDate) > 180 THEN 0.5
                ELSE                                                       0.2
            END                                                    AS churn_probability,

            -- Predicted purchases in next 90 days from observation date
            CASE
                WHEN DATEDIFF(DAY, last_date, @ObservationEndDate) <= 90
                THEN CAST(total_orders / 12.0 * 3 AS INT)
                ELSE 0
            END                                                    AS predicted_purchases_90d,

            -- Active within 365 days of observation date
            CASE
                WHEN DATEDIFF(DAY, last_date, @ObservationEndDate) <= 365 THEN 1
                ELSE 0
            END                                                    AS is_active

        FROM scored;

        SET @FactRowCount = @@ROWCOUNT;
        PRINT '        ✓ Loaded: ' + CAST(@FactRowCount AS VARCHAR(20)) + ' customer RFM records';
        PRINT '';
        PRINT '  ✓ SECTION 2 Complete – All Facts Loaded';
        PRINT '';

        -- ====================================================================
        -- SECTION 3: RECREATE FOREIGN KEY CONSTRAINTS
        -- All FK recreation occurs after every fact table has loaded so that
        -- referential integrity is enforced on a complete, consistent dataset.
        -- ====================================================================
        PRINT '=================================================================================';
        PRINT 'SECTION 3: Recreating Foreign Key Constraints';
        PRINT '=================================================================================';
        PRINT '';

        -- ── fact_sales → dim_date ──────────────────────────────────────────
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

        -- ── fact_sales → dimensions ────────────────────────────────────────
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

        -- ── fact_salesreason → fact_sales / dim_salesreason ───────────────
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

        -- ── fact_customer_rfm → dim_customer ──────────────────────────────
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_fact_customer_rfm')
        BEGIN
            ALTER TABLE gold.fact_customer_rfm ADD CONSTRAINT fk_fact_customer_rfm
                FOREIGN KEY (customer_key) REFERENCES gold.dim_customer(customer_key);
            PRINT '  ✓ Added: fk_fact_customer_rfm';
        END

        PRINT '';
        PRINT '  ✓ SECTION 3 Complete – All 10 Foreign Keys Recreated';
        PRINT '';

        -- ====================================================================
        -- COMMIT TRANSACTION
        -- ====================================================================
        COMMIT TRANSACTION;

        SET @EndTime = SYSUTCDATETIME();

        PRINT '=================================================================================';
        PRINT 'Gold Layer ETL Process – COMPLETED SUCCESSFULLY';
        PRINT '=================================================================================';
        PRINT '  ✓ 5 dimension tables merged  (SCD Type 1 – surrogate keys preserved)';
        PRINT '  ✓ dim_customer order metrics updated  (revenue = SUM(fact_sales.line_total))';
        PRINT '  ✓ dim_customer Pareto metrics updated (ROWS framing – tie-safe cumulative sums)';
        PRINT '  ✓ 3 fact tables loaded';
        PRINT '  ✓ 10 foreign key constraints recreated';
        PRINT '  ✓ Referential integrity enforced';
        PRINT '  ✓ Observation date used: ' + CONVERT(VARCHAR(10), @ObservationEndDate, 120);
        PRINT '';
        PRINT 'ETL Start Time : ' + CONVERT(VARCHAR(30), @StartTime, 121);
        PRINT 'ETL End Time   : ' + CONVERT(VARCHAR(30), @EndTime,   121);
        PRINT 'Duration       : ' + CAST(DATEDIFF(SECOND, @StartTime, @EndTime) AS VARCHAR(20)) + ' seconds';
        PRINT '=================================================================================';

    END TRY
    BEGIN CATCH
        -- Roll back the entire ETL run; partial loads are never committed
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SELECT
            @ErrorMessage  = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState    = ERROR_STATE();

        PRINT '';
        PRINT '=================================================================================';
        PRINT 'ERROR: Gold Layer ETL Process Failed – Transaction Rolled Back';
        PRINT '=================================================================================';
        PRINT 'Error Message  : ' + @ErrorMessage;
        PRINT 'Error Severity : ' + CAST(@ErrorSeverity AS VARCHAR(10));
        PRINT 'Error State    : ' + CAST(@ErrorState    AS VARCHAR(10));
        PRINT 'Error Line     : ' + CAST(ERROR_LINE()   AS VARCHAR(10));
        PRINT '=================================================================================';

        THROW;
    END CATCH
END;
GO

PRINT '=================================================================================';
PRINT 'Stored procedure gold.sp_load_complete_datawarehouse v2.0 created successfully';
PRINT '=================================================================================';
PRINT 'Usage: EXEC gold.sp_load_complete_datawarehouse;';
PRINT '=================================================================================';
GO

EXEC gold.sp_load_complete_datawarehouse;
