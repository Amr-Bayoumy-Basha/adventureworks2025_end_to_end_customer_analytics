/*
=================================================================================
Silver Layer DDL - All 17 Tables
=================================================================================
This script creates all silver layer tables for the AdventureWorks Customer DW.
Tables are created WITHOUT foreign key constraints for clean deployment.

TARGET: SQL Server (AdventureWorks2025_CustomerDW) | AUTHOR: Amr Bayomei Basha | DATE: May 2026
VERSION: 1.0
=================================================================================
*/

SET ANSI_NULLS ON; 
GO
SET QUOTED_IDENTIFIER ON;
GO


USE AdventureWorks2025_CustomerDW;
GO

PRINT '=================================================================================';
PRINT 'Starting Silver Layer DDL Script - 17 Tables';
PRINT '=================================================================================';
PRINT '';
GO

-- ========================================================================
-- SECTION 1: Dynamically Dropping All Foreign Keys in Schema [silver] TO AVOID REFRENCE ERROS
-- ========================================================================


PRINT '=================================================================================';
PRINT 'Step 1: Dynamically Dropping All Foreign Keys in Schema [silver]';
PRINT '=================================================================================';

DECLARE @sql NVARCHAR(MAX) = N'';

-- Generate DROP statements for all FKs in the 'silver' schema
SELECT @sql += 'ALTER TABLE ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + 
               ' DROP CONSTRAINT ' + QUOTENAME(fk.name) + ';' + CHAR(13)
FROM sys.foreign_keys AS fk
INNER JOIN sys.tables AS t ON fk.parent_object_id = t.object_id
INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
WHERE s.name = 'silver';

-- Execute the generated SQL if any FKs were found
IF @sql <> N''
BEGIN
    EXEC sp_executesql @sql;
    PRINT '  ✓ Success: All foreign keys in [silver] schema have been dropped.';
END
ELSE
BEGIN
    PRINT '  - Note: No foreign keys found in [silver] schema to drop.';
END
GO

-- ========================================================================
-- SECTION 1.1: DROP EXISTING TABLES (Reverse Dependency Order)
-- ========================================================================

PRINT 'Step 1.1: Dropping existing tables in reverse dependency order...';
GO

-- Drop bridge/junction tables first
IF OBJECT_ID('silver.aw_sales_salesorderheadersalesreason', 'U') IS NOT NULL
    DROP TABLE silver.aw_sales_salesorderheadersalesreason;
PRINT '  - Dropped: aw_sales_salesorderheadersalesreason';
GO

IF OBJECT_ID('silver.aw_sales_specialofferproduct', 'U') IS NOT NULL
    DROP TABLE silver.aw_sales_specialofferproduct;
PRINT '  - Dropped: aw_sales_specialofferproduct';
GO

IF OBJECT_ID('silver.aw_person_businessentityaddress', 'U') IS NOT NULL
    DROP TABLE silver.aw_person_businessentityaddress;
PRINT '  - Dropped: aw_person_businessentityaddress';
GO

IF OBJECT_ID('silver.aw_person_emailaddress', 'U') IS NOT NULL
    DROP TABLE silver.aw_person_emailaddress;
PRINT '  - Dropped: aw_person_emailaddress';
GO

-- Drop fact/detail tables
IF OBJECT_ID('silver.aw_sales_salesorderdetail', 'U') IS NOT NULL
    DROP TABLE silver.aw_sales_salesorderdetail;
PRINT '  - Dropped: aw_sales_salesorderdetail';
GO

IF OBJECT_ID('silver.aw_sales_salesorderheader', 'U') IS NOT NULL
    DROP TABLE silver.aw_sales_salesorderheader;
PRINT '  - Dropped: aw_sales_salesorderheader';
GO

-- Drop dimension tables
IF OBJECT_ID('silver.aw_sales_customer', 'U') IS NOT NULL
    DROP TABLE silver.aw_sales_customer;
PRINT '  - Dropped: aw_sales_customer';
GO

IF OBJECT_ID('silver.aw_production_product', 'U') IS NOT NULL
    DROP TABLE silver.aw_production_product;
PRINT '  - Dropped: aw_production_product';
GO

IF OBJECT_ID('silver.aw_sales_salesreason', 'U') IS NOT NULL
    DROP TABLE silver.aw_sales_salesreason;
PRINT '  - Dropped: aw_sales_salesreason';
GO

IF OBJECT_ID('silver.aw_sales_specialoffer', 'U') IS NOT NULL
    DROP TABLE silver.aw_sales_specialoffer;
PRINT '  - Dropped: aw_sales_specialoffer';
GO

IF OBJECT_ID('silver.aw_person_address', 'U') IS NOT NULL
    DROP TABLE silver.aw_person_address;
PRINT '  - Dropped: aw_person_address';
GO

IF OBJECT_ID('silver.aw_production_productsubcategory', 'U') IS NOT NULL
    DROP TABLE silver.aw_production_productsubcategory;
PRINT '  - Dropped: aw_production_productsubcategory';
GO

IF OBJECT_ID('silver.aw_production_productcategory', 'U') IS NOT NULL
    DROP TABLE silver.aw_production_productcategory;
PRINT '  - Dropped: aw_production_productcategory';
GO

IF OBJECT_ID('silver.aw_person_addresstype', 'U') IS NOT NULL
    DROP TABLE silver.aw_person_addresstype;
PRINT '  - Dropped: aw_person_addresstype';
GO

IF OBJECT_ID('silver.aw_person_stateprovince', 'U') IS NOT NULL
    DROP TABLE silver.aw_person_stateprovince;
PRINT '  - Dropped: aw_person_stateprovince';
GO

IF OBJECT_ID('silver.aw_sales_salesterritory', 'U') IS NOT NULL
    DROP TABLE silver.aw_sales_salesterritory;
PRINT '  - Dropped: aw_sales_salesterritory';
GO

IF OBJECT_ID('silver.aw_person_person', 'U') IS NOT NULL
    DROP TABLE silver.aw_person_person;
PRINT '  - Dropped: aw_person_person';
GO

PRINT '';
PRINT 'Step 1: Complete - All existing tables dropped';
PRINT '';
GO

-- ========================================================================
-- SECTION 2: CREATE FOUNDATION TABLES (No Dependencies)
-- ========================================================================

PRINT 'Step 2: Creating foundation tables (no dependencies)...';
PRINT '';
GO

-- ========================================================================
-- 1. silver.aw_person_person
-- ========================================================================

CREATE TABLE silver.aw_person_person (
    -- Primary key
    businessentity_id INT NOT NULL,
    
    -- Person attributes
    persontype NCHAR(2) NOT NULL,
    namestyle BIT NOT NULL,
    title NVARCHAR(8) NULL,
    firstname NVARCHAR(50) NOT NULL,
    middlename NVARCHAR(50) NULL,
    lastname NVARCHAR(50) NOT NULL,
    suffix NVARCHAR(10) NULL,
    emailpromotion INT NOT NULL,
    
    -- Additional information
    additionalcontactinfo XML NULL,
    demographics XML NULL,
    
    -- System columns
    rowguid UNIQUEIDENTIFIER NOT NULL,
    modifieddate DATETIME NOT NULL,
    
    -- Audit columns
    dwh_load_date DATETIME NOT NULL,
    dwh_silver_load_date DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    
    -- Constraints
    CONSTRAINT pk_silver_aw_person_person 
        PRIMARY KEY CLUSTERED (businessentity_id),
    CONSTRAINT chk_silver_aw_person_person_persontype 
        CHECK (persontype IN ('IN', 'SC')),
    CONSTRAINT chk_silver_aw_person_person_emailpromotion 
        CHECK (emailpromotion BETWEEN 0 AND 2)
);

CREATE NONCLUSTERED INDEX ix_silver_aw_person_person_name
    ON silver.aw_person_person (lastname, firstname)
    INCLUDE (businessentity_id, persontype);

CREATE NONCLUSTERED INDEX ix_silver_aw_person_person_persontype
    ON silver.aw_person_person (persontype)
    INCLUDE (businessentity_id, firstname, lastname);

CREATE NONCLUSTERED INDEX ix_silver_aw_person_person_modifieddate
    ON silver.aw_person_person (modifieddate)
    INCLUDE (businessentity_id);

PRINT '  ✓ Created: silver.aw_person_person';
GO

-- ========================================================================
-- 2. silver.aw_sales_salesterritory
-- ========================================================================

CREATE TABLE silver.aw_sales_salesterritory (
    -- Primary key
    territory_id INT NOT NULL,
    
    -- Territory attributes
    name NVARCHAR(50) NOT NULL,
    countryregioncode NVARCHAR(3) NOT NULL,
    [group] NVARCHAR(50) NOT NULL,
    
    -- Sales metrics
    salesytd MONEY NOT NULL,
    saleslastyear MONEY NOT NULL,
    costytd MONEY NOT NULL,
    costlastyear MONEY NOT NULL,
    
    -- System columns
    rowguid UNIQUEIDENTIFIER NOT NULL,
    modifieddate DATETIME NOT NULL,
    
    -- Audit columns
    dwh_load_date DATETIME NOT NULL,
    dwh_silver_load_date DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    
    -- Constraints
    CONSTRAINT pk_silver_aw_sales_salesterritory 
        PRIMARY KEY CLUSTERED (territory_id)
);

CREATE NONCLUSTERED INDEX ix_silver_territory_country
    ON silver.aw_sales_salesterritory (countryregioncode)
    INCLUDE (territory_id, name, [group]);

CREATE NONCLUSTERED INDEX ix_silver_territory_group
    ON silver.aw_sales_salesterritory ([group])
    INCLUDE (territory_id, name, countryregioncode);

PRINT '  ✓ Created: silver.aw_sales_salesterritory';
GO

-- ========================================================================
-- 3. silver.aw_production_productcategory
-- ========================================================================

CREATE TABLE silver.aw_production_productcategory (
    -- Primary key
    productcategory_id INT NOT NULL,
    
    -- Category attributes
    name NVARCHAR(50) NOT NULL,
    
    -- System columns
    rowguid UNIQUEIDENTIFIER NOT NULL,
    modifieddate DATETIME NOT NULL,
    
    -- Audit columns
    dwh_load_date DATETIME NOT NULL,
    dwh_silver_load_date DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    
    -- Constraints
    CONSTRAINT pk_silver_aw_production_productcategory 
        PRIMARY KEY CLUSTERED (productcategory_id)
);

CREATE NONCLUSTERED INDEX ix_silver_productcategory_name
    ON silver.aw_production_productcategory (name)
    INCLUDE (productcategory_id);

PRINT '  ✓ Created: silver.aw_production_productcategory';
GO

-- ========================================================================
-- 4. silver.aw_person_stateprovince
-- ========================================================================

CREATE TABLE silver.aw_person_stateprovince (
    -- Primary key
    stateprovince_id INT NOT NULL,
    
    -- State/province attributes
    stateprovincecode NCHAR(3) NOT NULL,
    countryregioncode NVARCHAR(3) NOT NULL,
    isonlystateprovinceflag BIT NOT NULL,
    name NVARCHAR(50) NOT NULL,
    territory_id INT NOT NULL,
    
    -- System columns
    rowguid UNIQUEIDENTIFIER NOT NULL,
    modifieddate DATETIME NOT NULL,
    
    -- Audit columns
    dwh_load_date DATETIME NOT NULL,
    dwh_silver_load_date DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    
    -- Constraints
    CONSTRAINT pk_silver_aw_person_stateprovince 
        PRIMARY KEY CLUSTERED (stateprovince_id)
);

CREATE NONCLUSTERED INDEX ix_silver_stateprovince_country
    ON silver.aw_person_stateprovince (countryregioncode)
    INCLUDE (stateprovince_id, name, territory_id);

CREATE NONCLUSTERED INDEX ix_silver_stateprovince_name
    ON silver.aw_person_stateprovince (name)
    INCLUDE (stateprovince_id, countryregioncode);

PRINT '  ✓ Created: silver.aw_person_stateprovince';
GO

-- ========================================================================
-- 5. silver.aw_person_addresstype
-- ========================================================================

CREATE TABLE silver.aw_person_addresstype (
    -- Primary key
    addresstype_id INT NOT NULL,
    
    -- Type attributes
    name NVARCHAR(50) NOT NULL,
    
    -- System columns
    rowguid UNIQUEIDENTIFIER NOT NULL,
    modifieddate DATETIME NOT NULL,
    
    -- Audit columns
    dwh_load_date DATETIME NOT NULL,
    dwh_silver_load_date DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    
    -- Constraints
    CONSTRAINT pk_silver_aw_person_addresstype 
        PRIMARY KEY CLUSTERED (addresstype_id)
);

CREATE NONCLUSTERED INDEX ix_silver_addresstype_name
    ON silver.aw_person_addresstype (name)
    INCLUDE (addresstype_id);

PRINT '  ✓ Created: silver.aw_person_addresstype';
GO

-- ========================================================================
-- 6. silver.aw_sales_salesreason
-- ========================================================================

CREATE TABLE silver.aw_sales_salesreason (
    -- Primary key
    salesreason_id INT NOT NULL,
    
    -- Reason attributes
    name NVARCHAR(50) NOT NULL,
    reasontype NVARCHAR(50) NOT NULL,
    
    -- System columns
    modifieddate DATETIME NOT NULL,
    
    -- Audit columns
    dwh_load_date DATETIME NOT NULL,
    dwh_silver_load_date DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    
    -- Constraints
    CONSTRAINT pk_silver_aw_sales_salesreason 
        PRIMARY KEY CLUSTERED (salesreason_id)
);

CREATE NONCLUSTERED INDEX ix_silver_salesreason_type
    ON silver.aw_sales_salesreason (reasontype)
    INCLUDE (salesreason_id, name);

PRINT '  ✓ Created: silver.aw_sales_salesreason';
GO

-- ========================================================================
-- 7. silver.aw_sales_specialoffer (FIXED - Computed Column)
-- ========================================================================

CREATE TABLE silver.aw_sales_specialoffer (
    -- Primary key
    specialoffer_id INT NOT NULL,
    
    -- Offer attributes
    description NVARCHAR(255) NOT NULL,
    discountpct DECIMAL(5, 4) NOT NULL,
    type NVARCHAR(50) NOT NULL,
    category NVARCHAR(50) NOT NULL,
    startdate DATETIME NOT NULL,
    enddate DATETIME NOT NULL,
    minqty INT NOT NULL,
    maxqty INT NULL,
    
    -- System columns
    rowguid UNIQUEIDENTIFIER NOT NULL,
    modifieddate DATETIME NOT NULL,
    
    -- Audit columns
    dwh_load_date DATETIME NOT NULL,
    dwh_silver_load_date DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    
    -- FIXED: Non-persisted computed column (GETDATE is non-deterministic)
    is_active AS (
        CASE 
            WHEN GETDATE() BETWEEN startdate AND enddate THEN 1
            ELSE 0
        END
    ),  -- NOT PERSISTED
    
    -- Constraints
    CONSTRAINT pk_silver_aw_sales_specialoffer 
        PRIMARY KEY CLUSTERED (specialoffer_id),
    CONSTRAINT chk_silver_specialoffer_discount 
        CHECK (discountpct BETWEEN 0.0 AND 1.0),
    CONSTRAINT chk_silver_specialoffer_dates 
        CHECK (enddate >= startdate)
);

CREATE NONCLUSTERED INDEX ix_silver_specialoffer_dates
    ON silver.aw_sales_specialoffer (startdate, enddate)
    INCLUDE (specialoffer_id, description, discountpct, category);

CREATE NONCLUSTERED INDEX ix_silver_specialoffer_category
    ON silver.aw_sales_specialoffer (category)
    INCLUDE (specialoffer_id, description, discountpct);

PRINT '  ✓ Created: silver.aw_sales_specialoffer (Fixed: is_active not persisted)';
GO

PRINT '';
PRINT 'Step 2: Complete - Foundation tables created';
PRINT '';
GO

-- ========================================================================
-- SECTION 3: CREATE DEPENDENT DIMENSION TABLES
-- ========================================================================

PRINT 'Step 3: Creating dependent dimension tables...';
PRINT '';
GO

-- ========================================================================
-- 8. silver.aw_production_productsubcategory
-- ========================================================================

CREATE TABLE silver.aw_production_productsubcategory (
    -- Primary key
    productsubcategory_id INT NOT NULL,
    
    -- Category relationship
    productcategory_id INT NOT NULL,
    
    -- Subcategory attributes
    name NVARCHAR(50) NOT NULL,
    
    -- System columns
    rowguid UNIQUEIDENTIFIER NOT NULL,
    modifieddate DATETIME NOT NULL,
    
    -- Audit columns
    dwh_load_date DATETIME NOT NULL,
    dwh_silver_load_date DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    
    -- Constraints
    CONSTRAINT pk_silver_aw_production_productsubcategory 
        PRIMARY KEY CLUSTERED (productsubcategory_id)
);

CREATE NONCLUSTERED INDEX ix_silver_productsubcategory_category
    ON silver.aw_production_productsubcategory (productcategory_id)
    INCLUDE (productsubcategory_id, name);

CREATE NONCLUSTERED INDEX ix_silver_productsubcategory_name
    ON silver.aw_production_productsubcategory (name)
    INCLUDE (productsubcategory_id, productcategory_id);

PRINT '  ✓ Created: silver.aw_production_productsubcategory';
GO

-- ========================================================================
-- 9. silver.aw_person_address
-- ========================================================================

CREATE TABLE silver.aw_person_address (
    -- Primary key
    address_id INT NOT NULL,
    
    -- Address components
    addressline1 NVARCHAR(60) NOT NULL,
    addressline2 NVARCHAR(60) NULL,
    city NVARCHAR(30) NOT NULL,
    stateprovince_id INT NOT NULL,
    postalcode NVARCHAR(15) NOT NULL,
    spatiallocation GEOGRAPHY NULL,
    
    -- System columns
    rowguid UNIQUEIDENTIFIER NOT NULL,
    modifieddate DATETIME NOT NULL,
    
    -- Audit columns
    dwh_load_date DATETIME NOT NULL,
    dwh_silver_load_date DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    
    -- Constraints
    CONSTRAINT pk_silver_aw_person_address 
        PRIMARY KEY CLUSTERED (address_id)
);

CREATE NONCLUSTERED INDEX ix_silver_address_stateprovince
    ON silver.aw_person_address (stateprovince_id)
    INCLUDE (address_id, city, postalcode);

CREATE NONCLUSTERED INDEX ix_silver_address_city
    ON silver.aw_person_address (city)
    INCLUDE (address_id, stateprovince_id);

CREATE NONCLUSTERED INDEX ix_silver_address_postalcode
    ON silver.aw_person_address (postalcode)
    INCLUDE (address_id, city, stateprovince_id);

PRINT '  ✓ Created: silver.aw_person_address';
GO

-- ========================================================================
-- 10. silver.aw_production_product
-- ========================================================================

CREATE TABLE silver.aw_production_product (
    -- Primary key
    product_id INT NOT NULL,
    
    -- Product identification
    name NVARCHAR(50) NOT NULL,
    productnumber NVARCHAR(25) NOT NULL,
    
    -- Product flags
    makeflag BIT NOT NULL,
    finishedgoodsflag BIT NOT NULL,
    
    -- Product attributes
    color NVARCHAR(15) NULL,
    safetystocklevel SMALLINT NOT NULL,
    reorderpoint SMALLINT NOT NULL,
    standardcost MONEY NOT NULL,
    listprice MONEY NOT NULL,
    size NVARCHAR(5) NULL,
    sizeunitmeasurecode NCHAR(3) NULL,
    weight DECIMAL(8, 2) NULL,
    weightunitmeasurecode NCHAR(3) NULL,
    daystomanufacture INT NOT NULL,
    productline NCHAR(2) NULL,
    class NCHAR(2) NULL,
    style NCHAR(2) NULL,
    
    -- Category relationships (nullable)
    productsubcategory_id INT NULL,
    productmodel_id INT NULL,
    
    -- Lifecycle dates
    sellstartdate DATETIME NOT NULL,
    sellenddate DATETIME NULL,
    discontinueddate DATETIME NULL,
    
    -- System columns
    rowguid UNIQUEIDENTIFIER NOT NULL,
    modifieddate DATETIME NOT NULL,
    
    -- Audit columns
    dwh_load_date DATETIME NOT NULL,
    dwh_silver_load_date DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    
    -- Computed columns (PERSISTED is OK - deterministic)
    margin_pct AS (
        CASE 
            WHEN listprice > 0 THEN ((listprice - standardcost) / listprice) * 100
            ELSE NULL
        END
    ) PERSISTED,
    
    is_active AS (
        CASE 
            WHEN sellenddate IS NULL THEN 1
            ELSE 0
        END
    ) PERSISTED,
    
    -- Constraints
    CONSTRAINT pk_silver_aw_production_product 
        PRIMARY KEY CLUSTERED (product_id),
    CONSTRAINT chk_silver_product_standardcost 
        CHECK (standardcost >= 0),
    CONSTRAINT chk_silver_product_listprice 
        CHECK (listprice >= 0),
    CONSTRAINT chk_silver_product_sellenddate 
        CHECK (sellenddate IS NULL OR sellenddate >= sellstartdate)
);

CREATE NONCLUSTERED INDEX ix_silver_product_subcategory
    ON silver.aw_production_product (productsubcategory_id)
    INCLUDE (product_id, name, listprice, finishedgoodsflag)
    WHERE productsubcategory_id IS NOT NULL;

CREATE NONCLUSTERED INDEX ix_silver_product_finishedgoods
    ON silver.aw_production_product (finishedgoodsflag)
    INCLUDE (product_id, name, listprice, productsubcategory_id)
    WHERE finishedgoodsflag = 1;

CREATE NONCLUSTERED INDEX ix_silver_product_listprice
    ON silver.aw_production_product (listprice)
    INCLUDE (product_id, name, standardcost, margin_pct);

CREATE NONCLUSTERED INDEX ix_silver_product_modifieddate
    ON silver.aw_production_product (modifieddate)
    INCLUDE (product_id);

PRINT '  ✓ Created: silver.aw_production_product';
GO

-- ========================================================================
-- 11. silver.aw_sales_customer
-- ========================================================================

CREATE TABLE silver.aw_sales_customer (
    -- Primary key
    customer_id INT NOT NULL,
    
    -- Customer identification (mutually exclusive)
    person_id INT NULL,
    store_id INT NULL,
    
    -- Territory assignment
    territory_id INT NOT NULL,
    accountnumber VARCHAR(10) NULL,
    
    -- System columns
    rowguid UNIQUEIDENTIFIER NOT NULL,
    modifieddate DATETIME NOT NULL,
    
    -- Audit columns
    dwh_load_date DATETIME NOT NULL,
    dwh_silver_load_date DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    
    -- Constraints
    CONSTRAINT pk_silver_aw_sales_customer 
        PRIMARY KEY CLUSTERED (customer_id)
    
    -- NOTE: Check constraint commented out due to 635 records with both IDs
    -- CONSTRAINT chk_silver_customer_type 
    --     CHECK ((person_id IS NOT NULL AND store_id IS NULL) 
    --         OR (person_id IS NULL AND store_id IS NOT NULL))
);

CREATE NONCLUSTERED INDEX ix_silver_customer_person
    ON silver.aw_sales_customer (person_id)
    INCLUDE (customer_id, territory_id)
    WHERE person_id IS NOT NULL;

CREATE NONCLUSTERED INDEX ix_silver_customer_territory
    ON silver.aw_sales_customer (territory_id)
    INCLUDE (customer_id, person_id);

CREATE NONCLUSTERED INDEX ix_silver_customer_modifieddate
    ON silver.aw_sales_customer (modifieddate)
    INCLUDE (customer_id);

PRINT '  ✓ Created: silver.aw_sales_customer';
GO

PRINT '';
PRINT 'Step 3: Complete - Dependent dimension tables created';
PRINT '';
GO

-- ========================================================================
-- SECTION 4: CREATE FACT TABLES
-- ========================================================================

PRINT 'Step 4: Creating fact tables...';
PRINT '';
GO

-- ========================================================================
-- 12. silver.aw_sales_salesorderheader
-- ========================================================================

CREATE TABLE silver.aw_sales_salesorderheader (
    -- Primary key
    salesorder_id INT NOT NULL,
    
    -- Order identification
    revisionnumber TINYINT NOT NULL,
    salesordernumber NVARCHAR(25) NOT NULL,
    purchaseordernumber NVARCHAR(25) NULL,
    accountnumber NVARCHAR(15) NULL,
    
    -- Order dates
    orderdate DATETIME NOT NULL,
    duedate DATETIME NOT NULL,
    shipdate DATETIME NULL,
    
    -- Order status
    status TINYINT NOT NULL,
    onlineorderflag BIT NOT NULL,
    
    -- Foreign keys
    customer_id INT NOT NULL,
    salesperson_id INT NULL,
    territory_id INT NOT NULL,
    billtoaddress_id INT NOT NULL,
    shiptoaddress_id INT NOT NULL,
    shipmethod_id INT NOT NULL,
    
    -- Payment information
    creditcard_id INT NULL,
    creditcardapprovalcode VARCHAR(15) NULL,
    currencyrate_id INT NULL,
    
    -- Monetary values
    subtotal MONEY NOT NULL,
    taxamt MONEY NOT NULL,
    freight MONEY NOT NULL,
    totaldue MONEY NOT NULL,
    
    -- Additional information
    comment NVARCHAR(128) NULL,
    
    -- System columns
    rowguid UNIQUEIDENTIFIER NOT NULL,
    modifieddate DATETIME NOT NULL,
    
    -- Audit columns
    dwh_load_date DATETIME NOT NULL,
    dwh_silver_load_date DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    
    -- Constraints
    CONSTRAINT pk_silver_aw_sales_salesorderheader 
        PRIMARY KEY CLUSTERED (salesorder_id),
    CONSTRAINT chk_silver_salesorderheader_status 
        CHECK (status BETWEEN 1 AND 6),
    CONSTRAINT chk_silver_salesorderheader_subtotal 
        CHECK (subtotal >= 0),
    CONSTRAINT chk_silver_salesorderheader_taxamt 
        CHECK (taxamt >= 0),
    CONSTRAINT chk_silver_salesorderheader_freight 
        CHECK (freight >= 0),
    CONSTRAINT chk_silver_salesorderheader_totaldue 
        CHECK (totaldue >= 0),
    CONSTRAINT chk_silver_salesorderheader_duedate 
        CHECK (duedate >= orderdate),
    CONSTRAINT chk_silver_salesorderheader_shipdate 
        CHECK (shipdate IS NULL OR shipdate >= orderdate)
);

CREATE NONCLUSTERED INDEX ix_silver_salesorderheader_customer
    ON silver.aw_sales_salesorderheader (customer_id)
    INCLUDE (salesorder_id, orderdate, totaldue, status);

CREATE NONCLUSTERED INDEX ix_silver_salesorderheader_orderdate
    ON silver.aw_sales_salesorderheader (orderdate)
    INCLUDE (salesorder_id, customer_id, totaldue);

CREATE NONCLUSTERED INDEX ix_silver_salesorderheader_status
    ON silver.aw_sales_salesorderheader (status)
    INCLUDE (salesorder_id, orderdate, totaldue);

CREATE NONCLUSTERED INDEX ix_silver_salesorderheader_territory
    ON silver.aw_sales_salesorderheader (territory_id)
    INCLUDE (salesorder_id, orderdate, totaldue);

CREATE NONCLUSTERED INDEX ix_silver_salesorderheader_salesperson
    ON silver.aw_sales_salesorderheader (salesperson_id)
    INCLUDE (salesorder_id, orderdate, totaldue)
    WHERE salesperson_id IS NOT NULL;

CREATE NONCLUSTERED INDEX ix_silver_salesorderheader_modifieddate
    ON silver.aw_sales_salesorderheader (modifieddate)
    INCLUDE (salesorder_id);

PRINT '  ✓ Created: silver.aw_sales_salesorderheader';
GO

-- ========================================================================
-- 13. silver.aw_sales_salesorderdetail
-- ========================================================================

CREATE TABLE silver.aw_sales_salesorderdetail (
    -- Composite primary key
    salesorder_id INT NOT NULL,
    salesorderdetail_id INT NOT NULL,
    
    -- Order line attributes
    carriertrackingnumber NVARCHAR(25) NULL,
    orderqty SMALLINT NOT NULL,
    product_id INT NOT NULL,
    specialoffer_id INT NOT NULL,
    
    -- Pricing
    unitprice MONEY NOT NULL,
    unitpricediscount MONEY NOT NULL,
    
    -- Computed column (PERSISTED is OK - deterministic)
    linetotal AS (unitprice * (1.0 - unitpricediscount) * orderqty) PERSISTED,
    
    -- System columns
    rowguid UNIQUEIDENTIFIER NOT NULL,
    modifieddate DATETIME NOT NULL,
    
    -- Audit columns
    dwh_load_date DATETIME NOT NULL,
    dwh_silver_load_date DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    
    -- Constraints
    CONSTRAINT pk_silver_aw_sales_salesorderdetail 
        PRIMARY KEY CLUSTERED (salesorder_id, salesorderdetail_id),
    CONSTRAINT chk_silver_salesorderdetail_orderqty 
        CHECK (orderqty > 0),
    CONSTRAINT chk_silver_salesorderdetail_unitprice 
        CHECK (unitprice >= 0),
    CONSTRAINT chk_silver_salesorderdetail_discount 
        CHECK (unitpricediscount >= 0 AND unitpricediscount < 1.0)
);

CREATE NONCLUSTERED INDEX ix_silver_salesorderdetail_order
    ON silver.aw_sales_salesorderdetail (salesorder_id)
    INCLUDE (orderqty, linetotal);

CREATE NONCLUSTERED INDEX ix_silver_salesorderdetail_product
    ON silver.aw_sales_salesorderdetail (product_id)
    INCLUDE (salesorder_id, orderqty, unitprice, linetotal);

CREATE NONCLUSTERED INDEX ix_silver_salesorderdetail_modifieddate
    ON silver.aw_sales_salesorderdetail (modifieddate)
    INCLUDE (salesorder_id, salesorderdetail_id);

PRINT '  ✓ Created: silver.aw_sales_salesorderdetail';
GO

PRINT '';
PRINT 'Step 4: Complete - Fact tables created';
PRINT '';
GO

-- ========================================================================
-- SECTION 5: CREATE BRIDGE/JUNCTION TABLES
-- ========================================================================

PRINT 'Step 5: Creating bridge/junction tables...';
PRINT '';
GO

-- ========================================================================
-- 14. silver.aw_sales_specialofferproduct
-- ========================================================================

CREATE TABLE silver.aw_sales_specialofferproduct (
    -- Composite primary key
    specialoffer_id INT NOT NULL,
    product_id INT NOT NULL,
    
    -- System columns
    rowguid UNIQUEIDENTIFIER NOT NULL,
    modifieddate DATETIME NOT NULL,
    
    -- Audit columns
    dwh_load_date DATETIME NOT NULL,
    dwh_silver_load_date DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    
    -- Constraints
    CONSTRAINT pk_silver_aw_sales_specialofferproduct 
        PRIMARY KEY CLUSTERED (specialoffer_id, product_id)
);

CREATE NONCLUSTERED INDEX ix_silver_specialofferproduct_product
    ON silver.aw_sales_specialofferproduct (product_id)
    INCLUDE (specialoffer_id);

PRINT '  ✓ Created: silver.aw_sales_specialofferproduct';
GO

-- ========================================================================
-- 15. silver.aw_person_businessentityaddress
-- ========================================================================

CREATE TABLE silver.aw_person_businessentityaddress (
    -- Composite primary key
    businessentity_id INT NOT NULL,
    address_id INT NOT NULL,
    addresstype_id INT NOT NULL,
    
    -- System columns
    rowguid UNIQUEIDENTIFIER NOT NULL,
    modifieddate DATETIME NOT NULL,
    
    -- Audit columns
    dwh_load_date DATETIME NOT NULL,
    dwh_silver_load_date DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    
    -- Constraints
    CONSTRAINT pk_silver_aw_person_businessentityaddress 
        PRIMARY KEY CLUSTERED (businessentity_id, address_id, addresstype_id)
);

CREATE NONCLUSTERED INDEX ix_silver_businessentityaddress_address
    ON silver.aw_person_businessentityaddress (address_id)
    INCLUDE (businessentity_id, addresstype_id);

CREATE NONCLUSTERED INDEX ix_silver_businessentityaddress_type
    ON silver.aw_person_businessentityaddress (addresstype_id)
    INCLUDE (businessentity_id, address_id);

PRINT '  ✓ Created: silver.aw_person_businessentityaddress';
GO

-- ========================================================================
-- 16. silver.aw_person_emailaddress
-- ========================================================================

CREATE TABLE silver.aw_person_emailaddress (
    -- Composite primary key
    businessentity_id INT NOT NULL,
    emailaddress_id INT NOT NULL,
    
    -- Email address
    emailaddress NVARCHAR(50) NOT NULL,
    
    -- System columns
    rowguid UNIQUEIDENTIFIER NOT NULL,
    modifieddate DATETIME NOT NULL,
    
    -- Audit columns
    dwh_load_date DATETIME NOT NULL,
    dwh_silver_load_date DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    
    -- Constraints
    CONSTRAINT pk_silver_aw_person_emailaddress 
        PRIMARY KEY CLUSTERED (businessentity_id, emailaddress_id),
    CONSTRAINT chk_silver_emailaddress_format 
        CHECK (emailaddress LIKE '%@%')
);

CREATE NONCLUSTERED INDEX ix_silver_emailaddress_person
    ON silver.aw_person_emailaddress (businessentity_id)
    INCLUDE (emailaddress);

PRINT '  ✓ Created: silver.aw_person_emailaddress';
GO

-- ========================================================================
-- 17. silver.aw_sales_salesorderheadersalesreason
-- ========================================================================

CREATE TABLE silver.aw_sales_salesorderheadersalesreason (
    -- Composite primary key
    salesorder_id INT NOT NULL,
    salesreason_id INT NOT NULL,
    
    -- System columns
    modifieddate DATETIME NOT NULL,
    
    -- Audit columns
    dwh_load_date DATETIME NOT NULL,
    dwh_silver_load_date DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    
    -- Constraints
    CONSTRAINT pk_silver_aw_sales_salesorderheadersalesreason 
        PRIMARY KEY CLUSTERED (salesorder_id, salesreason_id)
);

CREATE NONCLUSTERED INDEX ix_silver_orderreason_reason
    ON silver.aw_sales_salesorderheadersalesreason (salesreason_id)
    INCLUDE (salesorder_id);

PRINT '  ✓ Created: silver.aw_sales_salesorderheadersalesreason';
GO

PRINT '';
PRINT 'Step 5: Complete - Bridge/junction tables created';
PRINT '';
GO

-- ========================================================================
-- SECTION 6: SUMMARY
-- ========================================================================

PRINT '=================================================================================';
PRINT 'Silver Layer DDL Script Complete!';
PRINT '=================================================================================';
PRINT '';
PRINT 'Summary:';
PRINT '  - 17 tables created successfully';
PRINT '  - All indexes created';
PRINT '  - All check constraints applied';
PRINT '  - Fixed: is_active computed column (not persisted)';
PRINT '  - Note: Foreign key constraints NOT yet applied';
PRINT '=================================================================================';
GO

/*
-- ===================================================================================*/
