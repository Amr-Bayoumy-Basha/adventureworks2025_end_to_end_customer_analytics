/*
=================================================================================
Silver Layer ETL Stored Procedure - REFACTORED VERSION
=================================================================================
This version drops foreign keys before truncation and recreates them after loading.
This approach is cleaner and more reliable than disable/enable.

TARGET: SQL Server (AdventureWorks2025_CustomerDW) | AUTHOR: Amr Bayomei Basha | DATE: May 2026
VERSION: 1.0
=================================================================================
*/

USE AdventureWorks2025_CustomerDW;
GO

-- Drop existing procedure
IF OBJECT_ID('dbo.proc_load_silver_tables', 'P') IS NOT NULL
    DROP PROCEDURE dbo.proc_load_silver_tables;
GO

CREATE PROCEDURE dbo.proc_load_silver_tables
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME2 = SYSUTCDATETIME();
    DECLARE @LoadDate DATETIME = GETDATE();
    DECLARE @RowsAffected INT;
    DECLARE @TotalRows INT = 0;
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    DECLARE @SQL NVARCHAR(MAX);
    
    BEGIN TRY
        PRINT '=================================================================================';
        PRINT 'Starting Silver Layer ETL Process';
        PRINT 'Start Time: ' + CONVERT(VARCHAR(30), @StartTime, 121);
        PRINT '=================================================================================';
        PRINT '';
        
        -- ========================================================================
        -- STEP 0: DROP ALL FOREIGN KEY CONSTRAINTS
        -- ========================================================================
        
        PRINT '=================================================================================';
        PRINT 'STEP 0: Dynamically Dropping All Foreign Keys in Schema [silver]';
        PRINT '=================================================================================';
        PRINT '';
        
        SET @SQL = N'';
        
        -- Generate DROP statements for all FKs in the 'silver' schema
        SELECT @SQL += N'ALTER TABLE ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + 
                       N' DROP CONSTRAINT ' + QUOTENAME(fk.name) + N';' + CHAR(13)
        FROM sys.foreign_keys AS fk
        INNER JOIN sys.tables AS t ON fk.parent_object_id = t.object_id
        INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
        WHERE s.name = N'silver';
        
        -- Execute the generated SQL if any FKs were found
        IF @SQL <> N''
        BEGIN
            EXEC sp_executesql @SQL;
            PRINT '  ✓ Success: All foreign keys in [silver] schema have been dropped.';
        END
        ELSE
        BEGIN
            PRINT '  - Note: No foreign keys found in [silver] schema to drop.';
        END
        
        PRINT '';
        
        -- ========================================================================
        -- SECTION 1: LOAD FOUNDATION TABLES (No Dependencies)
        -- ========================================================================
        
        PRINT 'SECTION 1: Loading foundation tables...';
        PRINT '';
        
        -- 1. Load silver.aw_person_person
        PRINT '  Loading: aw_person_person';
        BEGIN TRANSACTION;
        TRUNCATE TABLE silver.aw_person_person;
        
        INSERT INTO silver.aw_person_person (
            businessentity_id, persontype, namestyle, title, firstname, middlename, lastname, suffix,
            emailpromotion, additionalcontactinfo, demographics, rowguid, modifieddate, dwh_load_date
        )
        SELECT 
            businessentity_id, persontype, namestyle, LTRIM(RTRIM(title)), LTRIM(RTRIM(firstname)),
            LTRIM(RTRIM(middlename)), LTRIM(RTRIM(lastname)), LTRIM(RTRIM(suffix)), emailpromotion,
            additionalcontactinfo, demographics, rowguid, modifieddate, @LoadDate
        FROM bronze.aw_person_person
        WHERE persontype IN ('IN', 'SC') AND firstname IS NOT NULL AND lastname IS NOT NULL;
        
        SET @RowsAffected = @@ROWCOUNT;
        SET @TotalRows = @TotalRows + @RowsAffected;
        COMMIT TRANSACTION;
        PRINT '    ✓ Loaded: ' + CAST(@RowsAffected AS VARCHAR(20)) + ' rows';
        PRINT '';
        
        -- 2. Load silver.aw_sales_salesterritory
        PRINT '  Loading: aw_sales_salesterritory';
        BEGIN TRANSACTION;
        TRUNCATE TABLE silver.aw_sales_salesterritory;
        
        INSERT INTO silver.aw_sales_salesterritory (
            territory_id, name, countryregioncode, [group], salesytd, saleslastyear, 
            costytd, costlastyear, rowguid, modifieddate, dwh_load_date
        )
        SELECT 
            territory_id, LTRIM(RTRIM(name)), LTRIM(RTRIM(countryregioncode)), LTRIM(RTRIM([group_name])),
            salesytd, saleslastyear, costytd, costlastyear, rowguid, modifieddate, @LoadDate
        FROM bronze.aw_sales_salesterritory;
        
        SET @RowsAffected = @@ROWCOUNT;
        SET @TotalRows = @TotalRows + @RowsAffected;
        COMMIT TRANSACTION;
        PRINT '    ✓ Loaded: ' + CAST(@RowsAffected AS VARCHAR(20)) + ' rows';
        PRINT '';
        
        -- 3. Load silver.aw_production_productcategory
        PRINT '  Loading: aw_production_productcategory';
        BEGIN TRANSACTION;
        TRUNCATE TABLE silver.aw_production_productcategory;
        
        INSERT INTO silver.aw_production_productcategory (
            productcategory_id, name, rowguid, modifieddate, dwh_load_date
        )
        SELECT productcategory_id, LTRIM(RTRIM(name)), rowguid, modifieddate, @LoadDate
        FROM bronze.aw_production_productcategory;
        
        SET @RowsAffected = @@ROWCOUNT;
        SET @TotalRows = @TotalRows + @RowsAffected;
        COMMIT TRANSACTION;
        PRINT '    ✓ Loaded: ' + CAST(@RowsAffected AS VARCHAR(20)) + ' rows';
        PRINT '';
        
        -- 4. Load silver.aw_person_stateprovince
        PRINT '  Loading: aw_person_stateprovince';
        BEGIN TRANSACTION;
        TRUNCATE TABLE silver.aw_person_stateprovince;
        
        INSERT INTO silver.aw_person_stateprovince (
            stateprovince_id, stateprovincecode, countryregioncode, isonlystateprovinceflag,
            name, territory_id, rowguid, modifieddate, dwh_load_date
        )
        SELECT 
            stateprovince_id, LTRIM(RTRIM(stateprovincecode)), LTRIM(RTRIM(countryregioncode)),
            isonlystateprovinceflag, LTRIM(RTRIM(name)), territory_id, rowguid, modifieddate, @LoadDate
        FROM bronze.aw_person_stateprovince;
        
        SET @RowsAffected = @@ROWCOUNT;
        SET @TotalRows = @TotalRows + @RowsAffected;
        COMMIT TRANSACTION;
        PRINT '    ✓ Loaded: ' + CAST(@RowsAffected AS VARCHAR(20)) + ' rows';
        PRINT '';
        
        -- 5. Load silver.aw_person_addresstype
        PRINT '  Loading: aw_person_addresstype';
        BEGIN TRANSACTION;
        TRUNCATE TABLE silver.aw_person_addresstype;
        
        INSERT INTO silver.aw_person_addresstype (addresstype_id, name, rowguid, modifieddate, dwh_load_date)
        SELECT addresstype_id, LTRIM(RTRIM(name)), rowguid, modifieddate, @LoadDate
        FROM bronze.aw_person_addresstype;
        
        SET @RowsAffected = @@ROWCOUNT;
        SET @TotalRows = @TotalRows + @RowsAffected;
        COMMIT TRANSACTION;
        PRINT '    ✓ Loaded: ' + CAST(@RowsAffected AS VARCHAR(20)) + ' rows';
        PRINT '';
        
        -- 6. Load silver.aw_sales_salesreason
        PRINT '  Loading: aw_sales_salesreason';
        BEGIN TRANSACTION;
        TRUNCATE TABLE silver.aw_sales_salesreason;
        
        INSERT INTO silver.aw_sales_salesreason (salesreason_id, name, reasontype, modifieddate, dwh_load_date)
        SELECT salesreason_id, LTRIM(RTRIM(name)), LTRIM(RTRIM(reasontype)), modifieddate, @LoadDate
        FROM bronze.aw_sales_salesreason;
        
        SET @RowsAffected = @@ROWCOUNT;
        SET @TotalRows = @TotalRows + @RowsAffected;
        COMMIT TRANSACTION;
        PRINT '    ✓ Loaded: ' + CAST(@RowsAffected AS VARCHAR(20)) + ' rows';
        PRINT '';
        
        -- 7. Load silver.aw_sales_specialoffer
        PRINT '  Loading: aw_sales_specialoffer';
        BEGIN TRANSACTION;
        TRUNCATE TABLE silver.aw_sales_specialoffer;
        
        INSERT INTO silver.aw_sales_specialoffer (
            specialoffer_id, description, discountpct, type, category, startdate, enddate,
            minqty, maxqty, rowguid, modifieddate, dwh_load_date
        )
        SELECT 
            specialoffer_id, LTRIM(RTRIM(description)), discountpct, LTRIM(RTRIM(type)),
            LTRIM(RTRIM(category)), startdate, enddate, minqty, maxqty, rowguid, modifieddate, @LoadDate
        FROM bronze.aw_sales_specialoffer;
        
        SET @RowsAffected = @@ROWCOUNT;
        SET @TotalRows = @TotalRows + @RowsAffected;
        COMMIT TRANSACTION;
        PRINT '    ✓ Loaded: ' + CAST(@RowsAffected AS VARCHAR(20)) + ' rows';
        PRINT '';
        
        PRINT 'SECTION 1: Complete';
        PRINT '';
        
        -- ========================================================================
        -- SECTION 2: LOAD DEPENDENT DIMENSION TABLES
        -- ========================================================================
        
        PRINT 'SECTION 2: Loading dependent dimension tables...';
        PRINT '';
        
        -- 8. Load silver.aw_production_productsubcategory
        PRINT '  Loading: aw_production_productsubcategory';
        BEGIN TRANSACTION;
        TRUNCATE TABLE silver.aw_production_productsubcategory;
        
        INSERT INTO silver.aw_production_productsubcategory (
            productsubcategory_id, productcategory_id, name, rowguid, modifieddate, dwh_load_date
        )
        SELECT productsubcategory_id, productcategory_id, LTRIM(RTRIM(name)), rowguid, modifieddate, @LoadDate
        FROM bronze.aw_production_productsubcategory;
        
        SET @RowsAffected = @@ROWCOUNT;
        SET @TotalRows = @TotalRows + @RowsAffected;
        COMMIT TRANSACTION;
        PRINT '    ✓ Loaded: ' + CAST(@RowsAffected AS VARCHAR(20)) + ' rows';
        PRINT '';
        
        -- 9. Load silver.aw_person_address
        PRINT '  Loading: aw_person_address';
        BEGIN TRANSACTION;
        TRUNCATE TABLE silver.aw_person_address;
        
        INSERT INTO silver.aw_person_address (
            address_id, addressline1, addressline2, city, stateprovince_id, postalcode,
            spatiallocation, rowguid, modifieddate, dwh_load_date
        )
        SELECT 
            address_id, LTRIM(RTRIM(addressline1)), LTRIM(RTRIM(addressline2)), LTRIM(RTRIM(city)),
            stateprovince_id, LTRIM(RTRIM(postalcode)), spatiallocation, rowguid, modifieddate, @LoadDate
        FROM bronze.aw_person_address;
        
        SET @RowsAffected = @@ROWCOUNT;
        SET @TotalRows = @TotalRows + @RowsAffected;
        COMMIT TRANSACTION;
        PRINT '    ✓ Loaded: ' + CAST(@RowsAffected AS VARCHAR(20)) + ' rows';
        PRINT '';
        
        -- 10. Load silver.aw_production_product
        PRINT '  Loading: aw_production_product';
        BEGIN TRANSACTION;
        TRUNCATE TABLE silver.aw_production_product;
        
        INSERT INTO silver.aw_production_product (
            product_id, name, productnumber, makeflag, finishedgoodsflag, color, safetystocklevel,
            reorderpoint, standardcost, listprice, size, sizeunitmeasurecode, weight, weightunitmeasurecode,
            daystomanufacture, productline, class, style, productsubcategory_id, productmodel_id,
            sellstartdate, sellenddate, discontinueddate, rowguid, modifieddate, dwh_load_date
        )
        SELECT 
            product_id, LTRIM(RTRIM(name)), LTRIM(RTRIM(productnumber)), makeflag, finishedgoodsflag,
            LTRIM(RTRIM(color)), safetystocklevel, reorderpoint, standardcost, listprice,
            LTRIM(RTRIM(size)), LTRIM(RTRIM(sizeunitmeasurecode)), weight, LTRIM(RTRIM(weightunitmeasurecode)),
            daystomanufacture, LTRIM(RTRIM(productline)), LTRIM(RTRIM(class)), LTRIM(RTRIM(style)),
            productsubcategory_id, productmodel_id, sellstartdate, sellenddate, discontinueddate,
            rowguid, modifieddate, @LoadDate
        FROM bronze.aw_production_product;
        
        SET @RowsAffected = @@ROWCOUNT;
        SET @TotalRows = @TotalRows + @RowsAffected;
        COMMIT TRANSACTION;
        PRINT '    ✓ Loaded: ' + CAST(@RowsAffected AS VARCHAR(20)) + ' rows';
        PRINT '';
        
        -- 11. Load silver.aw_sales_customer
        PRINT '  Loading: aw_sales_customer';
        BEGIN TRANSACTION;
        TRUNCATE TABLE silver.aw_sales_customer;
        
        INSERT INTO silver.aw_sales_customer (
            customer_id, person_id, store_id, territory_id, accountnumber, rowguid, modifieddate, dwh_load_date
        )
        SELECT 
            customer_id,
            CASE WHEN person_id IS NOT NULL THEN person_id ELSE NULL END,
            CASE WHEN person_id IS NOT NULL THEN NULL ELSE store_id END,
            territory_id, LTRIM(RTRIM(accountnumber)), rowguid, modifieddate, @LoadDate
        FROM bronze.aw_sales_customer;
        
        SET @RowsAffected = @@ROWCOUNT;
        SET @TotalRows = @TotalRows + @RowsAffected;
        COMMIT TRANSACTION;
        PRINT '    ✓ Loaded: ' + CAST(@RowsAffected AS VARCHAR(20)) + ' rows (mutual exclusivity applied)';
        PRINT '';
        
        PRINT 'SECTION 2: Complete';
        PRINT '';
        
        -- ========================================================================
        -- SECTION 3: LOAD FACT TABLES
        -- ========================================================================
        
        PRINT 'SECTION 3: Loading fact tables...';
        PRINT '';
        
        -- 12. Load silver.aw_sales_salesorderheader
        PRINT '  Loading: aw_sales_salesorderheader';
        BEGIN TRANSACTION;
        TRUNCATE TABLE silver.aw_sales_salesorderheader;
        
        INSERT INTO silver.aw_sales_salesorderheader (
            salesorder_id, revisionnumber, salesordernumber, purchaseordernumber, accountnumber,
            orderdate, duedate, shipdate, status, onlineorderflag, customer_id, salesperson_id,
            territory_id, billtoaddress_id, shiptoaddress_id, shipmethod_id, creditcard_id,
            creditcardapprovalcode, currencyrate_id, subtotal, taxamt, freight, totaldue,
            comment, rowguid, modifieddate, dwh_load_date
        )
        SELECT 
            salesorder_id, revisionnumber, LTRIM(RTRIM(salesordernumber)), LTRIM(RTRIM(purchaseordernumber)),
            LTRIM(RTRIM(accountnumber)), orderdate, duedate, shipdate, status, onlineorderflag,
            customer_id, salesperson_id, territory_id, billtoaddress_id, shiptoaddress_id, shipmethod_id,
            creditcard_id, LTRIM(RTRIM(creditcardapprovalcode)), currencyrate_id, subtotal, taxamt,
            freight, totaldue, LTRIM(RTRIM(comment)), rowguid, modifieddate, @LoadDate
        FROM bronze.aw_sales_salesorderheader;
        
        SET @RowsAffected = @@ROWCOUNT;
        SET @TotalRows = @TotalRows + @RowsAffected;
        COMMIT TRANSACTION;
        PRINT '    ✓ Loaded: ' + CAST(@RowsAffected AS VARCHAR(20)) + ' rows';
        PRINT '';
        
        -- 13. Load silver.aw_sales_salesorderdetail
        PRINT '  Loading: aw_sales_salesorderdetail';
        BEGIN TRANSACTION;
        TRUNCATE TABLE silver.aw_sales_salesorderdetail;
        
        INSERT INTO silver.aw_sales_salesorderdetail (
            salesorder_id, salesorderdetail_id, carriertrackingnumber, orderqty, product_id,
            specialoffer_id, unitprice, unitpricediscount, rowguid, modifieddate, dwh_load_date
        )
        SELECT 
            salesorder_id, salesorderdetail_id, LTRIM(RTRIM(carriertrackingnumber)), orderqty,
            product_id, specialoffer_id, unitprice, unitpricediscount, rowguid, modifieddate, @LoadDate
        FROM bronze.aw_sales_salesorderdetail;
        
        SET @RowsAffected = @@ROWCOUNT;
        SET @TotalRows = @TotalRows + @RowsAffected;
        COMMIT TRANSACTION;
        PRINT '    ✓ Loaded: ' + CAST(@RowsAffected AS VARCHAR(20)) + ' rows';
        PRINT '';
        
        PRINT 'SECTION 3: Complete';
        PRINT '';
        
        -- ========================================================================
        -- SECTION 4: LOAD BRIDGE/JUNCTION TABLES
        -- ========================================================================
        
        PRINT 'SECTION 4: Loading bridge/junction tables...';
        PRINT '';
        
        -- 14. Load silver.aw_sales_specialofferproduct
        PRINT '  Loading: aw_sales_specialofferproduct';
        BEGIN TRANSACTION;
        TRUNCATE TABLE silver.aw_sales_specialofferproduct;
        
        INSERT INTO silver.aw_sales_specialofferproduct (
            specialoffer_id, product_id, rowguid, modifieddate, dwh_load_date
        )
        SELECT specialoffer_id, product_id, rowguid, modifieddate, @LoadDate
        FROM bronze.aw_sales_specialofferproduct;
        
        SET @RowsAffected = @@ROWCOUNT;
        SET @TotalRows = @TotalRows + @RowsAffected;
        COMMIT TRANSACTION;
        PRINT '    ✓ Loaded: ' + CAST(@RowsAffected AS VARCHAR(20)) + ' rows';
        PRINT '';
        
        -- 15. Load silver.aw_person_businessentityaddress
        PRINT '  Loading: aw_person_businessentityaddress';
        BEGIN TRANSACTION;
        TRUNCATE TABLE silver.aw_person_businessentityaddress;
        
        INSERT INTO silver.aw_person_businessentityaddress (
            businessentity_id, address_id, addresstype_id, rowguid, modifieddate, dwh_load_date
        )
        SELECT b.business_entity_id, b.address_id, b.addresstype_id, b.rowguid, b.modifieddate, @LoadDate
        FROM bronze.aw_person_businessentityaddress b
        -- JOIN to Silver person table to ensure referential integrity
        INNER JOIN silver.aw_person_person p 
            ON b.business_entity_id = p.businessentity_id;
        
        SET @RowsAffected = @@ROWCOUNT;
        SET @TotalRows = @TotalRows + @RowsAffected;
        COMMIT TRANSACTION;
        PRINT '    ✓ Loaded: ' + CAST(@RowsAffected AS VARCHAR(20)) + ' rows';
        
        -- 16. Load silver.aw_person_emailaddress
        PRINT '  Loading: aw_person_emailaddress';
        BEGIN TRANSACTION;
        TRUNCATE TABLE silver.aw_person_emailaddress;
        
        INSERT INTO silver.aw_person_emailaddress (
            businessentity_id, emailaddress_id, emailaddress, rowguid, modifieddate, dwh_load_date
        )
        SELECT e.business_entity_id, e.emailaddress_id, LTRIM(RTRIM(e.emailaddress)), e.rowguid, e.modifieddate, @LoadDate
        FROM bronze.aw_person_emailaddress e
        -- JOIN to Silver person table to ensure referential integrity
        INNER JOIN silver.aw_person_person p 
            ON e.business_entity_id = p.businessentity_id;
        
        SET @RowsAffected = @@ROWCOUNT;
        SET @TotalRows = @TotalRows + @RowsAffected;
        COMMIT TRANSACTION;
        PRINT '    ✓ Loaded: ' + CAST(@RowsAffected AS VARCHAR(20)) + ' rows';
        -- 17. Load silver.aw_sales_salesorderheadersalesreason
        PRINT '  Loading: aw_sales_salesorderheadersalesreason';
        BEGIN TRANSACTION;
        TRUNCATE TABLE silver.aw_sales_salesorderheadersalesreason;
        
        INSERT INTO silver.aw_sales_salesorderheadersalesreason (
            salesorder_id, salesreason_id, modifieddate, dwh_load_date
        )
        SELECT salesorder_id, salesreason_id, modifieddate, @LoadDate
        FROM bronze.aw_sales_salesorderheadersalesreason;
        
        SET @RowsAffected = @@ROWCOUNT;
        SET @TotalRows = @TotalRows + @RowsAffected;
        COMMIT TRANSACTION;
        PRINT '    ✓ Loaded: ' + CAST(@RowsAffected AS VARCHAR(20)) + ' rows';
        PRINT '';
        
        PRINT 'SECTION 4: Complete';
        PRINT '';
        
        -- ========================================================================
        -- STEP 5: RECREATE ALL FOREIGN KEY CONSTRAINTS
        -- ========================================================================
        
        PRINT '=================================================================================';
        PRINT 'STEP 5: Recreating Foreign Key Constraints to Silver Layer';
        PRINT '=================================================================================';
        PRINT '';
        
        -- Customer -> Person
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_silver_customer_person')
        BEGIN
            ALTER TABLE silver.aw_sales_customer
            ADD CONSTRAINT fk_silver_customer_person
                FOREIGN KEY (person_id)
                REFERENCES silver.aw_person_person (businessentity_id);
            PRINT '  ✓ Added: fk_silver_customer_person';
        END
        
        -- Customer -> Territory
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_silver_customer_territory')
        BEGIN
            ALTER TABLE silver.aw_sales_customer
            ADD CONSTRAINT fk_silver_customer_territory
                FOREIGN KEY (territory_id)
                REFERENCES silver.aw_sales_salesterritory (territory_id);
            PRINT '  ✓ Added: fk_silver_customer_territory';
        END
        
        -- SalesOrderHeader -> Customer
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_silver_salesorderheader_customer')
        BEGIN
            ALTER TABLE silver.aw_sales_salesorderheader
            ADD CONSTRAINT fk_silver_salesorderheader_customer
                FOREIGN KEY (customer_id)
                REFERENCES silver.aw_sales_customer (customer_id);
            PRINT '  ✓ Added: fk_silver_salesorderheader_customer';
        END
        
        -- SalesOrderHeader -> Territory
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_silver_salesorderheader_territory')
        BEGIN
            ALTER TABLE silver.aw_sales_salesorderheader
            ADD CONSTRAINT fk_silver_salesorderheader_territory
                FOREIGN KEY (territory_id)
                REFERENCES silver.aw_sales_salesterritory (territory_id);
            PRINT '  ✓ Added: fk_silver_salesorderheader_territory';
        END
        
        -- SalesOrderDetail -> SalesOrderHeader
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_silver_salesorderdetail_header')
        BEGIN
            ALTER TABLE silver.aw_sales_salesorderdetail
            ADD CONSTRAINT fk_silver_salesorderdetail_header
                FOREIGN KEY (salesorder_id)
                REFERENCES silver.aw_sales_salesorderheader (salesorder_id);
            PRINT '  ✓ Added: fk_silver_salesorderdetail_header';
        END
        
        -- SalesOrderDetail -> Product
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_silver_salesorderdetail_product')
        BEGIN
            ALTER TABLE silver.aw_sales_salesorderdetail
            ADD CONSTRAINT fk_silver_salesorderdetail_product
                FOREIGN KEY (product_id)
                REFERENCES silver.aw_production_product (product_id);
            PRINT '  ✓ Added: fk_silver_salesorderdetail_product';
        END
        
        -- SalesOrderDetail -> SpecialOfferProduct (Composite FK)
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_silver_salesorderdetail_specialoffer')
        BEGIN
            ALTER TABLE silver.aw_sales_salesorderdetail
            ADD CONSTRAINT fk_silver_salesorderdetail_specialoffer
                FOREIGN KEY (specialoffer_id, product_id)
                REFERENCES silver.aw_sales_specialofferproduct (specialoffer_id, product_id);
            PRINT '  ✓ Added: fk_silver_salesorderdetail_specialoffer';
        END
        
        -- Product -> ProductSubcategory
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_silver_product_subcategory')
        BEGIN
            ALTER TABLE silver.aw_production_product
            ADD CONSTRAINT fk_silver_product_subcategory
                FOREIGN KEY (productsubcategory_id)
                REFERENCES silver.aw_production_productsubcategory (productsubcategory_id);
            PRINT '  ✓ Added: fk_silver_product_subcategory';
        END
        
        -- ProductSubcategory -> ProductCategory
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_silver_productsubcategory_category')
        BEGIN
            ALTER TABLE silver.aw_production_productsubcategory
            ADD CONSTRAINT fk_silver_productsubcategory_category
                FOREIGN KEY (productcategory_id)
                REFERENCES silver.aw_production_productcategory (productcategory_id);
            PRINT '  ✓ Added: fk_silver_productsubcategory_category';
        END
        
        -- SpecialOfferProduct -> SpecialOffer
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_silver_specialofferproduct_offer')
        BEGIN
            ALTER TABLE silver.aw_sales_specialofferproduct
            ADD CONSTRAINT fk_silver_specialofferproduct_offer
                FOREIGN KEY (specialoffer_id)
                REFERENCES silver.aw_sales_specialoffer (specialoffer_id);
            PRINT '  ✓ Added: fk_silver_specialofferproduct_offer';
        END
        
        -- SpecialOfferProduct -> Product
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_silver_specialofferproduct_product')
        BEGIN
            ALTER TABLE silver.aw_sales_specialofferproduct
            ADD CONSTRAINT fk_silver_specialofferproduct_product
                FOREIGN KEY (product_id)
                REFERENCES silver.aw_production_product (product_id);
            PRINT '  ✓ Added: fk_silver_specialofferproduct_product';
        END
        
        -- Address -> StateProvince
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_silver_address_stateprovince')
        BEGIN
            ALTER TABLE silver.aw_person_address
            ADD CONSTRAINT fk_silver_address_stateprovince
                FOREIGN KEY (stateprovince_id)
                REFERENCES silver.aw_person_stateprovince (stateprovince_id);
            PRINT '  ✓ Added: fk_silver_address_stateprovince';
        END
        
        -- StateProvince -> Territory
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_silver_stateprovince_territory')
        BEGIN
            ALTER TABLE silver.aw_person_stateprovince
            ADD CONSTRAINT fk_silver_stateprovince_territory
                FOREIGN KEY (territory_id)
                REFERENCES silver.aw_sales_salesterritory (territory_id);
            PRINT '  ✓ Added: fk_silver_stateprovince_territory';
        END
        
        -- BusinessEntityAddress -> Person
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_silver_businessentityaddress_person')
        BEGIN
            ALTER TABLE silver.aw_person_businessentityaddress
            ADD CONSTRAINT fk_silver_businessentityaddress_person
                FOREIGN KEY (businessentity_id)
                REFERENCES silver.aw_person_person (businessentity_id);
            PRINT '  ✓ Added: fk_silver_businessentityaddress_person';
        END
        
        -- BusinessEntityAddress -> Address
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_silver_businessentityaddress_address')
        BEGIN
            ALTER TABLE silver.aw_person_businessentityaddress
            ADD CONSTRAINT fk_silver_businessentityaddress_address
                FOREIGN KEY (address_id)
                REFERENCES silver.aw_person_address (address_id);
            PRINT '  ✓ Added: fk_silver_businessentityaddress_address';
        END
        
        -- BusinessEntityAddress -> AddressType
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_silver_businessentityaddress_type')
        BEGIN
            ALTER TABLE silver.aw_person_businessentityaddress
            ADD CONSTRAINT fk_silver_businessentityaddress_type
                FOREIGN KEY (addresstype_id)
                REFERENCES silver.aw_person_addresstype (addresstype_id);
            PRINT '  ✓ Added: fk_silver_businessentityaddress_type';
        END
        
        -- EmailAddress -> Person
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_silver_emailaddress_person')
        BEGIN
            ALTER TABLE silver.aw_person_emailaddress
            ADD CONSTRAINT fk_silver_emailaddress_person
                FOREIGN KEY (businessentity_id)
                REFERENCES silver.aw_person_person (businessentity_id);
            PRINT '  ✓ Added: fk_silver_emailaddress_person';
        END
        
        -- SalesOrderHeaderSalesReason -> SalesOrderHeader
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_silver_orderreason_header')
        BEGIN
            ALTER TABLE silver.aw_sales_salesorderheadersalesreason
            ADD CONSTRAINT fk_silver_orderreason_header
                FOREIGN KEY (salesorder_id)
                REFERENCES silver.aw_sales_salesorderheader (salesorder_id);
            PRINT '  ✓ Added: fk_silver_orderreason_header';
        END
        
        -- SalesOrderHeaderSalesReason -> SalesReason
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_silver_orderreason_reason')
        BEGIN
            ALTER TABLE silver.aw_sales_salesorderheadersalesreason
            ADD CONSTRAINT fk_silver_orderreason_reason
                FOREIGN KEY (salesreason_id)
                REFERENCES silver.aw_sales_salesreason (salesreason_id);
            PRINT '  ✓ Added: fk_silver_orderreason_reason';
        END
        
        PRINT '';
        PRINT 'All FK constraints recreated and validated';
        PRINT '';
        
        -- ========================================================================
        -- FINAL SUMMARY
        -- ========================================================================
        
        DECLARE @EndTime DATETIME2 = SYSUTCDATETIME();
        DECLARE @Duration VARCHAR(20) = CONVERT(VARCHAR(20), DATEADD(ms, DATEDIFF(ms, @StartTime, @EndTime), 0), 114);
        
        PRINT '=================================================================================';
        PRINT 'Silver Layer ETL Process Complete';
        PRINT '=================================================================================';
        PRINT 'Total Rows Loaded: ' + CAST(@TotalRows AS VARCHAR(20));
        PRINT 'Duration: ' + @Duration;
        PRINT 'End Time: ' + CONVERT(VARCHAR(30), @EndTime, 121);
        PRINT '=================================================================================';
        PRINT '';
        PRINT 'Summary:';
        PRINT '  - 17 tables successfully loaded';
        PRINT '  - 19 foreign key constraints recreated';
        PRINT '  - Referential integrity validated';
        PRINT '=================================================================================';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
        
        PRINT '';
        PRINT '=================================================================================';
        PRINT 'ERROR OCCURRED DURING ETL PROCESS';
        PRINT '=================================================================================';
        PRINT 'Error Message: ' + @ErrorMessage;
        PRINT 'Error Severity: ' + CAST(@ErrorSeverity AS VARCHAR(10));
        PRINT 'Error State: ' + CAST(@ErrorState AS VARCHAR(10));
        PRINT '=================================================================================';
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

PRINT 'Stored procedure dbo.proc_load_silver_tables created successfully';
PRINT 'Use EXEC dbo.proc_load_silver_tables; to run the ETL process';
GO

EXEC dbo.proc_load_silver_tables;
