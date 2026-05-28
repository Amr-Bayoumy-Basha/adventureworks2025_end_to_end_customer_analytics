/*
===============================================================================
Purpose: Create an SSIS/ETL configuration (mapping) table that lists OLTP source
schema/table pairs and their corresponding data-warehouse "bronze" schema/table pairs.
Orchestration (SSIS/ADF) can read this table to drive iterative table-by-table loads,
control per-table enablement, and set an optional load order.
TARGET: SQL Server (AdventureWorks2025_CustomerDW) | AUTHOR: Amr Bayomei Basha | DATE: May 2026
VERSION: 1.0
===============================================================================
*/

-- Create mapping table if it does not already exist
IF OBJECT_ID('dbo.etl_bronze_table_mapping','U') IS NULL
BEGIN
    CREATE TABLE dbo.etl_bronze_table_mapping (
        mapping_id INT IDENTITY(1,1) PRIMARY KEY, -- identity seed=1, increment=1
        source_schema SYSNAME NOT NULL,
        source_table  SYSNAME NOT NULL,
        dest_schema   SYSNAME NOT NULL,
        dest_table    SYSNAME NOT NULL,
        load_order    INT NULL, -- optional: controls load order when required
        is_active     BIT NOT NULL CONSTRAINT DF_etl_bronze_table_mapping_is_active DEFAULT(1), -- 1 = enabled, 0 = disabled
        notes         NVARCHAR(400) NULL,
        created_at    DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END;

-- Insert mapping rows (source OLTP -> target DW bronze); skip duplicates
INSERT INTO dbo.etl_bronze_table_mapping (source_schema, source_table, dest_schema, dest_table)
SELECT v.source_schema, v.source_table, v.dest_schema, v.dest_table
FROM (VALUES
('Sales','Customer','bronze','aw_sales_customer'),
('Person','Person','bronze','aw_person_person'),
('Person','EmailAddress','bronze','aw_person_emailaddress'),
('Person','Address','bronze','aw_person_address'),
('Person','StateProvince','bronze','aw_person_stateprovince'),
('Sales','SalesTerritory','bronze','aw_sales_salesterritory'),
('Person','BusinessEntityAddress','bronze','aw_person_businessentityaddress'),
('Person','AddressType','bronze','aw_person_addresstype'),
('Production','Product','bronze','aw_production_product'),
('Production','ProductSubcategory','bronze','aw_production_productsubcategory'),
('Production','ProductCategory','bronze','aw_production_productcategory'),
('Sales','SalesOrderHeader','bronze','aw_sales_salesorderheader'),
('Sales','SalesOrderDetail','bronze','aw_sales_salesorderdetail'),
('Sales','SpecialOffer','bronze','aw_sales_specialoffer'),
('Sales','SpecialOfferProduct','bronze','aw_sales_specialofferproduct'),
('Sales','SalesOrderHeaderSalesReason','bronze','aw_sales_salesorderheadersalesreason'),
('Sales','SalesReason','bronze','aw_sales_salesreason')
) AS v(source_schema, source_table, dest_schema, dest_table)
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.etl_bronze_table_mapping m
    WHERE m.source_schema = v.source_schema
      AND m.source_table  = v.source_table
      AND m.dest_schema   = v.dest_schema
      AND m.dest_table    = v.dest_table
);


-- ===================================================================================================
/*
 This script manages the configuration table that maps source OLTP tables to their corresponding
 bronze tables in the data warehouse. It is used to drive automated ETL loads.
*/
-- ===================================================================================================
-- Select all active table mappings for bronze loads, ordered by load_order and mapping_id
SELECT source_schema, source_table, dest_schema, dest_table
FROM dbo.etl_bronze_table_mapping
WHERE is_active = 1
ORDER BY ISNULL(load_order, 999), mapping_id; -- 999 is a fallback for missing load_order
