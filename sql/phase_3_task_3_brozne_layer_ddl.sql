/*
===============================================================================
DDL Script: Create Bronze Tables for AdventureWorks2025_CustomerDW
Naming Convention: bronze.aw_<schema>_<table>
Bronze raw load: Fully nullable, no PK, no constraint

TARGET: SQL Server (AdventureWorks2025_CustomerDW) | 
AUTHOR: Amr Bayomei Basha | DATE: May 2026

===============================================================================
*/

-- 1. Sales.Customer
IF OBJECT_ID('bronze.aw_sales_customer', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.aw_sales_customer (
        customer_id int,
        person_id int,
        store_id int,
        territory_id int,
        accountnumber varchar(10),
        rowguid uniqueidentifier,
        modifieddate datetime2,
        dwh_load_date datetime2
    );
    PRINT 'Created table bronze.aw_sales_customer.';
END
ELSE
    PRINT 'Table bronze.aw_sales_customer already exists. Skipping creation.';
GO

-- 2. Person.Person
IF OBJECT_ID('bronze.aw_person_person', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.aw_person_person (
        businessentity_id int,
        persontype nchar(2),
        namestyle bit,
        title nvarchar(8),
        firstname nvarchar(50),
        middlename nvarchar(50),
        lastname nvarchar(50),
        suffix nvarchar(10),
        emailpromotion int,
        additionalcontactinfo xml,
        demographics xml,
        rowguid uniqueidentifier,
        modifieddate datetime2,
        dwh_load_date datetime2
    );
    PRINT 'Created table bronze.aw_person_person.';
END
ELSE
    PRINT 'Table bronze.aw_person_person already exists. Skipping creation.';
GO

-- 3. Person.EmailAddress
IF OBJECT_ID('bronze.aw_person_emailaddress', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.aw_person_emailaddress (
        business_entity_id int,
        emailaddress_id int,
        emailaddress nvarchar(50),
        rowguid uniqueidentifier,
        modifieddate datetime2,
        dwh_load_date datetime2
    );
    PRINT 'Created table bronze.aw_person_emailaddress.';
END
ELSE
    PRINT 'Table bronze.aw_person_emailaddress already exists. Skipping creation.';
GO

-- 4. Person.Address
IF OBJECT_ID('bronze.aw_person_address', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.aw_person_address (
        address_id int,
        addressline1 nvarchar(60),
        addressline2 nvarchar(60),
        city nvarchar(30),
        stateprovince_id int,
        postalcode nvarchar(15),
        spatiallocation geography,  
        rowguid uniqueidentifier,
        modifieddate datetime2,
        dwh_load_date datetime2
    );
    PRINT 'Created table bronze.aw_person_address.';
END
ELSE
    PRINT 'Table bronze.aw_person_address already exists. Skipping creation.';
GO

-- 5. Person.StateProvince
IF OBJECT_ID('bronze.aw_person_stateprovince', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.aw_person_stateprovince (
        stateprovince_id int,
        stateprovincecode nchar(3),
        countryregioncode nvarchar(3),
        isonlystateprovinceflag bit,
        name nvarchar(50),
        territory_id int,
        rowguid uniqueidentifier,
        modifieddate datetime2,
        dwh_load_date datetime2
    );
    PRINT 'Created table bronze.aw_person_stateprovince.';
END
ELSE
    PRINT 'Table bronze.aw_person_stateprovince already exists. Skipping creation.';
GO

-- 6. Sales.SalesTerritory
IF OBJECT_ID('bronze.aw_sales_salesterritory', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.aw_sales_salesterritory (
        territory_id int,
        name nvarchar(50),
        countryregioncode nvarchar(3),
        group_name nvarchar(50),
        salesytd money,
        saleslastyear money,
        costytd money,
        costlastyear money,
        rowguid uniqueidentifier,
        modifieddate datetime2,
        dwh_load_date datetime2
    );
    PRINT 'Created table bronze.aw_sales_salesterritory.';
END
ELSE
    PRINT 'Table bronze.aw_sales_salesterritory already exists. Skipping creation.';
GO

-- 7. Person.BusinessEntityAddress
IF OBJECT_ID('bronze.aw_person_businessentityaddress', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.aw_person_businessentityaddress (
        business_entity_id int,
        address_id int,
        addresstype_id int,
        rowguid uniqueidentifier,
        modifieddate datetime2,
        dwh_load_date datetime2
    );
    PRINT 'Created table bronze.aw_person_businessentityaddress.';
END
ELSE
    PRINT 'Table bronze.aw_person_businessentityaddress already exists. Skipping creation.';
GO

-- 8. Person.AddressType
IF OBJECT_ID('bronze.aw_person_addresstype', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.aw_person_addresstype (
        addresstype_id int,
        name nvarchar(50),
        rowguid uniqueidentifier,
        modifieddate datetime2,
        dwh_load_date datetime2
    );
    PRINT 'Created table bronze.aw_person_addresstype.';
END
ELSE
    PRINT 'Table bronze.aw_person_addresstype already exists. Skipping creation.';
GO

-- 9. Production.Product
IF OBJECT_ID('bronze.aw_production_product', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.aw_production_product (
        product_id int,
        name nvarchar(50),
        productnumber nvarchar(25),
        makeflag bit,
        finishedgoodsflag bit,
        color nvarchar(15),
        safetystocklevel smallint,
        reorderpoint smallint,
        standardcost money,
        listprice money,
        size nvarchar(5),
        sizeunitmeasurecode nchar(3),
        weightunitmeasurecode nchar(3),
        weight decimal(8,2),
        daystomanufacture int,
        productline nchar(2),
        class nchar(2),
        style nchar(2),
        productsubcategory_id int,
        productmodel_id int,
        sellstartdate datetime2,
        sellenddate datetime2,
        discontinueddate datetime2,
        rowguid uniqueidentifier,
        modifieddate datetime2,
        dwh_load_date datetime2
    );
    PRINT 'Created table bronze.aw_production_product.';
END
ELSE
    PRINT 'Table bronze.aw_production_product already exists. Skipping creation.';
GO

-- 10. Production.ProductSubcategory
IF OBJECT_ID('bronze.aw_production_productsubcategory', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.aw_production_productsubcategory (
        productsubcategory_id int,
        productcategory_id int,
        name nvarchar(50),
        rowguid uniqueidentifier,
        modifieddate datetime2,
        dwh_load_date datetime2
    );
    PRINT 'Created table bronze.aw_production_productsubcategory.';
END
ELSE
    PRINT 'Table bronze.aw_production_productsubcategory already exists. Skipping creation.';
GO

-- 11. Production.ProductCategory
IF OBJECT_ID('bronze.aw_production_productcategory', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.aw_production_productcategory (
        productcategory_id int,
        name nvarchar(50),
        rowguid uniqueidentifier,
        modifieddate datetime2,
        dwh_load_date datetime2
    );
    PRINT 'Created table bronze.aw_production_productcategory.';
END
ELSE
    PRINT 'Table bronze.aw_production_productcategory already exists. Skipping creation.';
GO

-- 12. Sales.SalesOrderHeader
IF OBJECT_ID('bronze.aw_sales_salesorderheader', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.aw_sales_salesorderheader (
        salesorder_id int,
        revisionnumber tinyint,
        orderdate datetime2,
        duedate datetime2,
        shipdate datetime2,
        status tinyint,
        onlineorderflag bit,
        salesordernumber nvarchar(25),
        purchaseordernumber nvarchar(25),
        accountnumber nvarchar(15),
        customer_id int,
        salesperson_id int,
        territory_id int,
        billtoaddress_id int,
        shiptoaddress_id int,
        shipmethod_id int,
        creditcard_id int,
        creditcardapprovalcode varchar(15),
        currencyrate_id int,
        subtotal money,
        taxamt money,
        freight money,
        totaldue money,
        comment nvarchar(128),
        rowguid uniqueidentifier,
        modifieddate datetime2,
        dwh_load_date datetime2
    );
    PRINT 'Created table bronze.aw_sales_salesorderheader.';
END
ELSE
    PRINT 'Table bronze.aw_sales_salesorderheader already exists. Skipping creation.';
GO

-- 13. Sales.SalesOrderDetail
IF OBJECT_ID('bronze.aw_sales_salesorderdetail', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.aw_sales_salesorderdetail (
        salesorder_id int,
        salesorderdetail_id int,
        carriertrackingnumber nvarchar(25),
        orderqty smallint,
        product_id int,
        specialoffer_id int,
        unitprice money,
        unitpricediscount money,
        linetotal numeric(38,6),
        rowguid uniqueidentifier,
        modifieddate datetime2,
        dwh_load_date datetime2
    );
    PRINT 'Created table bronze.aw_sales_salesorderdetail.';
END
ELSE
    PRINT 'Table bronze.aw_sales_salesorderdetail already exists. Skipping creation.';
GO

-- 14. Sales.SpecialOffer
IF OBJECT_ID('bronze.aw_sales_specialoffer', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.aw_sales_specialoffer (
        specialoffer_id int,
        description nvarchar(255),
        discountpct smallmoney,
        type nvarchar(50),
        category nvarchar(50),
        startdate datetime2,
        enddate datetime2,
        minqty int,
        maxqty int,
        rowguid uniqueidentifier,
        modifieddate datetime2,
        dwh_load_date datetime2
    );
    PRINT 'Created table bronze.aw_sales_specialoffer.';
END
ELSE
    PRINT 'Table bronze.aw_sales_specialoffer already exists. Skipping creation.';
GO

-- 15. Sales.SpecialOfferProduct
IF OBJECT_ID('bronze.aw_sales_specialofferproduct', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.aw_sales_specialofferproduct (
        specialoffer_id int,
        product_id int,
        rowguid uniqueidentifier,
        modifieddate datetime2,
        dwh_load_date datetime2
    );
    PRINT 'Created table bronze.aw_sales_specialofferproduct.';
END
ELSE
    PRINT 'Table bronze.aw_sales_specialofferproduct already exists. Skipping creation.';
GO

-- 16. Sales.SalesOrderHeaderSalesReason
IF OBJECT_ID('bronze.aw_sales_salesorderheadersalesreason', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.aw_sales_salesorderheadersalesreason (
        salesorder_id int,
        salesreason_id int,
        modifieddate datetime2,
        dwh_load_date datetime2
    );
    PRINT 'Created table bronze.aw_sales_salesorderheadersalesreason.';
END
ELSE
    PRINT 'Table bronze.aw_sales_salesorderheadersalesreason already exists. Skipping creation.';
GO

-- 17. Sales.SalesReason
IF OBJECT_ID('bronze.aw_sales_salesreason', 'U') IS NULL
BEGIN
    CREATE TABLE bronze.aw_sales_salesreason (
        salesreason_id int,
        name nvarchar(50),
        reasontype nvarchar(50),
        modifieddate datetime2,
        dwh_load_date datetime2
    );
    PRINT 'Created table bronze.aw_sales_salesreason.';
END
ELSE
    PRINT 'Table bronze.aw_sales_salesreason already exists. Skipping creation.';
GO
