/*
===============================================================================
Validation Script: Bronze Layer vs Silver Layer
Description: Validates data migration by accounting for DDL check constraints
             and referential integrity filters.

TARGET: SQL Server (AdventureWorks2025_CustomerDW) | AUTHOR: Amr Bayomei Basha | DATE: May 2026
VERSION: 1.0
===============================================================================
*/

USE AdventureWorks2025_CustomerDW;
GO

SELECT 
    val.TableName,
    val.BronzeRows,
    val.ExpectedSilverRows,
    val.ActualSilverRows,
    CASE 
        WHEN val.ExpectedSilverRows = val.ActualSilverRows THEN 'Match' 
        ELSE 'Mismatch' 
    END AS Status,
    (val.BronzeRows - val.ActualSilverRows) AS TotalDroppedRows
FROM (
    SELECT 
        src.TableName,
        src.BronzeRows,
        -- Applying DDL logic to calculate EXPECTED counts
        CASE 
            -- 1. Person: persontype IN ('IN', 'SC')
            WHEN src.TableName = 'silver.aw_person_person' 
                THEN (SELECT COUNT(*) FROM bronze.aw_person_person WHERE persontype IN ('IN', 'SC'))
            
            -- 2. Email: Valid @ format AND associated with a valid Silver Person
            WHEN src.TableName = 'silver.aw_person_emailaddress'
                THEN (SELECT COUNT(*) FROM bronze.aw_person_emailaddress e 
                      WHERE e.emailaddress LIKE '%@%'
                      AND EXISTS (SELECT 1 FROM bronze.aw_person_person p 
                                    WHERE p.businessentity_id = e.business_entity_id 
                                    AND p.persontype IN ('IN', 'SC')))
            
            -- 3. Business Address: Must have a valid parent in Silver Person
            WHEN src.TableName = 'silver.aw_person_businessentityaddress'
                THEN (SELECT COUNT(*) FROM bronze.aw_person_businessentityaddress b 
                      WHERE EXISTS (SELECT 1 FROM bronze.aw_person_person p 
                                    WHERE p.businessentity_id = b.business_entity_id 
                                    AND p.persontype IN ('IN', 'SC')))
            
            -- 4. Special Offer: Discount and Date checks
            WHEN src.TableName = 'silver.aw_sales_specialoffer'
                THEN (SELECT COUNT(*) FROM bronze.aw_sales_specialoffer 
                      WHERE (discountpct BETWEEN 0.0 AND 1.0) AND (enddate >= startdate))

            -- 5. Sales Order Header: Status check
            WHEN src.TableName = 'silver.aw_sales_salesorderheader'
                THEN (SELECT COUNT(*) FROM bronze.aw_sales_salesorderheader WHERE status BETWEEN 1 AND 6)

            -- 6. Sales Order Detail: Qty and Discount checks
            WHEN src.TableName = 'silver.aw_sales_salesorderdetail'
                THEN (SELECT COUNT(*) FROM bronze.aw_sales_salesorderdetail 
                      WHERE orderqty > 0 AND unitpricediscount < 1.0)

            -- Default: 1:1 Match for tables without specific DDL filters
            ELSE src.BronzeRows 
        END AS ExpectedSilverRows,
        dst.ActualSilverRows
    FROM (
        -- Aggregate Bronze Row Counts
        SELECT 'silver.aw_person_person' AS TableName, COUNT(*) AS BronzeRows FROM bronze.aw_person_person
        UNION ALL SELECT 'silver.aw_person_address', COUNT(*) FROM bronze.aw_person_address
        UNION ALL SELECT 'silver.aw_person_addresstype', COUNT(*) FROM bronze.aw_person_addresstype
        UNION ALL SELECT 'silver.aw_person_businessentityaddress', COUNT(*) FROM bronze.aw_person_businessentityaddress
        UNION ALL SELECT 'silver.aw_person_emailaddress', COUNT(*) FROM bronze.aw_person_emailaddress
        UNION ALL SELECT 'silver.aw_person_stateprovince', COUNT(*) FROM bronze.aw_person_stateprovince
        UNION ALL SELECT 'silver.aw_production_product', COUNT(*) FROM bronze.aw_production_product
        UNION ALL SELECT 'silver.aw_production_productcategory', COUNT(*) FROM bronze.aw_production_productcategory
        UNION ALL SELECT 'silver.aw_production_productsubcategory', COUNT(*) FROM bronze.aw_production_productsubcategory
        UNION ALL SELECT 'silver.aw_sales_customer', COUNT(*) FROM bronze.aw_sales_customer
        UNION ALL SELECT 'silver.aw_sales_salesorderdetail', COUNT(*) FROM bronze.aw_sales_salesorderdetail
        UNION ALL SELECT 'silver.aw_sales_salesorderheader', COUNT(*) FROM bronze.aw_sales_salesorderheader
        UNION ALL SELECT 'silver.aw_sales_salesorderheadersalesreason', COUNT(*) FROM bronze.aw_sales_salesorderheadersalesreason
        UNION ALL SELECT 'silver.aw_sales_salesreason', COUNT(*) FROM bronze.aw_sales_salesreason
        UNION ALL SELECT 'silver.aw_sales_salesterritory', COUNT(*) FROM bronze.aw_sales_salesterritory
        UNION ALL SELECT 'silver.aw_sales_specialoffer', COUNT(*) FROM bronze.aw_sales_specialoffer
        UNION ALL SELECT 'silver.aw_sales_specialofferproduct', COUNT(*) FROM bronze.aw_sales_specialofferproduct
    ) src
    LEFT JOIN (
        -- Aggregate Actual Silver Row Counts
        SELECT 'silver.aw_person_person' AS TableName, COUNT(*) AS ActualSilverRows FROM silver.aw_person_person
        UNION ALL SELECT 'silver.aw_person_address', COUNT(*) FROM silver.aw_person_address
        UNION ALL SELECT 'silver.aw_person_addresstype', COUNT(*) FROM silver.aw_person_addresstype
        UNION ALL SELECT 'silver.aw_person_businessentityaddress', COUNT(*) FROM silver.aw_person_businessentityaddress
        UNION ALL SELECT 'silver.aw_person_emailaddress', COUNT(*) FROM silver.aw_person_emailaddress
        UNION ALL SELECT 'silver.aw_person_stateprovince', COUNT(*) FROM silver.aw_person_stateprovince
        UNION ALL SELECT 'silver.aw_production_product', COUNT(*) FROM silver.aw_production_product
        UNION ALL SELECT 'silver.aw_production_productcategory', COUNT(*) FROM silver.aw_production_productcategory
        UNION ALL SELECT 'silver.aw_production_productsubcategory', COUNT(*) FROM silver.aw_production_productsubcategory
        UNION ALL SELECT 'silver.aw_sales_customer', COUNT(*) FROM silver.aw_sales_customer
        UNION ALL SELECT 'silver.aw_sales_salesorderdetail', COUNT(*) FROM silver.aw_sales_salesorderdetail
        UNION ALL SELECT 'silver.aw_sales_salesorderheader', COUNT(*) FROM silver.aw_sales_salesorderheader
        UNION ALL SELECT 'silver.aw_sales_salesorderheadersalesreason', COUNT(*) FROM silver.aw_sales_salesorderheadersalesreason
        UNION ALL SELECT 'silver.aw_sales_salesreason', COUNT(*) FROM silver.aw_sales_salesreason
        UNION ALL SELECT 'silver.aw_sales_salesterritory', COUNT(*) FROM silver.aw_sales_salesterritory
        UNION ALL SELECT 'silver.aw_sales_specialoffer', COUNT(*) FROM silver.aw_sales_specialoffer
        UNION ALL SELECT 'silver.aw_sales_specialofferproduct', COUNT(*) FROM silver.aw_sales_specialofferproduct
    ) dst ON src.TableName = dst.TableName
) val
ORDER BY val.TableName;
