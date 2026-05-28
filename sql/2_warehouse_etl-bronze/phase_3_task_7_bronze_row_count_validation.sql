/*
===============================================================================
This script compares row counts between each source OLTP table and its corresponding
bronze table in the data warehouse. It helps validate that all rows were loaded successfully.
TARGET: SQL Server (AdventureWorks2025_CustomerDW) | AUTHOR: Amr Bayomei Basha | DATE: May 2026
VERSION: 1.0
===============================================================================
*/

-- Compare row counts for each table and flag mismatches
SELECT 
    src.TableName AS SourceTable,
    src.TotalRows AS SourceRows,
    dst.TotalRows AS BronzeRows,
    CASE WHEN src.TotalRows = dst.TotalRows THEN 'Match' ELSE 'Mismatch' END AS RowCountStatus
FROM (
    -- Aggregate row counts for each source table
    SELECT 'Person.Address' AS TableName, COUNT(*) AS TotalRows FROM AdventureWorks2025.Person.Address
    UNION ALL SELECT 'Person.AddressType', COUNT(*) FROM AdventureWorks2025.Person.AddressType
    UNION ALL SELECT 'Person.BusinessEntityAddress', COUNT(*) FROM AdventureWorks2025.Person.BusinessEntityAddress
    UNION ALL SELECT 'Person.EmailAddress', COUNT(*) FROM AdventureWorks2025.Person.EmailAddress
    UNION ALL SELECT 'Person.Person', COUNT(*) FROM AdventureWorks2025.Person.Person
    UNION ALL SELECT 'Person.StateProvince', COUNT(*) FROM AdventureWorks2025.Person.StateProvince
    UNION ALL SELECT 'Production.Product', COUNT(*) FROM AdventureWorks2025.Production.Product
    UNION ALL SELECT 'Production.ProductCategory', COUNT(*) FROM AdventureWorks2025.Production.ProductCategory
    UNION ALL SELECT 'Production.ProductSubcategory', COUNT(*) FROM AdventureWorks2025.Production.ProductSubcategory
    UNION ALL SELECT 'Sales.Customer', COUNT(*) FROM AdventureWorks2025.Sales.Customer
    UNION ALL SELECT 'Sales.SalesOrderDetail', COUNT(*) FROM AdventureWorks2025.Sales.SalesOrderDetail
    UNION ALL SELECT 'Sales.SalesOrderHeader', COUNT(*) FROM AdventureWorks2025.Sales.SalesOrderHeader
    UNION ALL SELECT 'Sales.SalesOrderHeaderSalesReason', COUNT(*) FROM AdventureWorks2025.Sales.SalesOrderHeaderSalesReason
    UNION ALL SELECT 'Sales.SalesReason', COUNT(*) FROM AdventureWorks2025.Sales.SalesReason
    UNION ALL SELECT 'Sales.SalesTerritory', COUNT(*) FROM AdventureWorks2025.Sales.SalesTerritory
    UNION ALL SELECT 'Sales.SpecialOffer', COUNT(*) FROM AdventureWorks2025.Sales.SpecialOffer
    UNION ALL SELECT 'Sales.SpecialOfferProduct', COUNT(*) FROM AdventureWorks2025.Sales.SpecialOfferProduct
) src
JOIN (
    -- Aggregate row counts for each bronze table
    SELECT 'Person.Address' AS TableName, COUNT(*) AS TotalRows FROM bronze.aw_person_address
    UNION ALL SELECT 'Person.AddressType', COUNT(*) FROM bronze.aw_person_addresstype
    UNION ALL SELECT 'Person.BusinessEntityAddress', COUNT(*) FROM bronze.aw_person_businessentityaddress
    UNION ALL SELECT 'Person.EmailAddress', COUNT(*) FROM bronze.aw_person_emailaddress
    UNION ALL SELECT 'Person.Person', COUNT(*) FROM bronze.aw_person_person
    UNION ALL SELECT 'Person.StateProvince', COUNT(*) FROM bronze.aw_person_stateprovince
    UNION ALL SELECT 'Production.Product', COUNT(*) FROM bronze.aw_production_product
    UNION ALL SELECT 'Production.ProductCategory', COUNT(*) FROM bronze.aw_production_productcategory
    UNION ALL SELECT 'Production.ProductSubcategory', COUNT(*) FROM bronze.aw_production_productsubcategory
    UNION ALL SELECT 'Sales.Customer', COUNT(*) FROM bronze.aw_sales_customer
    UNION ALL SELECT 'Sales.SalesOrderDetail', COUNT(*) FROM bronze.aw_sales_salesorderdetail
    UNION ALL SELECT 'Sales.SalesOrderHeader', COUNT(*) FROM bronze.aw_sales_salesorderheader
    UNION ALL SELECT 'Sales.SalesOrderHeaderSalesReason', COUNT(*) FROM bronze.aw_sales_salesorderheadersalesreason
    UNION ALL SELECT 'Sales.SalesReason', COUNT(*) FROM bronze.aw_sales_salesreason
    UNION ALL SELECT 'Sales.SalesTerritory', COUNT(*) FROM bronze.aw_sales_salesterritory
    UNION ALL SELECT 'Sales.SpecialOffer', COUNT(*) FROM bronze.aw_sales_specialoffer
    UNION ALL SELECT 'Sales.SpecialOfferProduct', COUNT(*) FROM bronze.aw_sales_specialofferproduct
) dst
ON src.TableName = dst.TableName
ORDER BY src.TableName;
