/* Exploratory data analysis for trnsforming data from bronze to silver layer in a data warehouse. 
This code will help to understand the structure of the data and identify any potential issues before 
loading it into the silver layer. 

TARGET: SQL Server (AdventureWorks2025_CustomerDW) | AUTHOR: Amr Bayomei Basha | DATE: May 2026
VERSION: 1.0
*/
-- ========================================================================
-- 1. bronze.aw_person_person table check
-- ========================================================================

/*
1.1 Check the structure of the bronze.aw_person_person table
Purpose: See sample data, column values, and spot obvious issues (e.g., nulls, odd values).
================================================================================================*/

SELECT TOP 100 *
FROM bronze.aw_person_person;

/* Review the output for: 
- Presence of null values in key columns (e.g., title, middlename).
- Consistency in data (e.g., emailpromotion values, persontype codes).
================================================================================================*/

/*
1.2 Check for null values in important columns
Purpose: Identify missing data in columns that are important for analytics.
================================================================================================*/

SELECT 
	COUNT(*) AS TotalRows,
	SUM (CASE WHEN businessentity_id IS NULL THEN 1 ELSE 0 END) AS NullBusinessEntityID,
	SUM (CASE WHEN persontype IS NULL THEN 1 ELSE 0 END) AS NullPersonType,
	SUM (CASE WHEN firstname IS NULL THEN 1 ELSE 0 END) AS NullFirstNames,
	SUM (CASE WHEN lastname IS NULL THEN 1 ELSE 0 END) AS NullLastNames
FROM bronze.aw_person_person;

/*
Findings:
- No nulls in business_entity_id (primary key).
- No nulls in firstname and lastname (important for analysis).
- No nulls in persontype (important for categorization).
- required transformation : None of the key columns have null values.
  so no imputation needed for these columns.
- Define PK constraint on business_entity_id in silver layer to ensure data integrity
  and prevent future nulls in this column.
- Define NOT NULL constraints on firstname, lastname and persontype in silver layer to ensure data quality 
  and prevent future nulls in these columns.
================================================================================================*/

/*
1.3 Check for distinct values in persontype
Purpose: Understand the different person types and their distribution.
================================================================================================*/

SELECT 
	persontype, 
	COUNT(*) AS Count
FROM bronze.aw_person_person
GROUP BY persontype
ORDER BY Count DESC;

/*
Findings:
- Most occurring persontype values ( IN : 18484 , SC: 753 ) out of  19972 rows representing 96.3 %
- GC ( General Contact) needs more investigation to see weither they are acual customers or not
- EM (Employee) , SP (Sales Person) and VC (Vendor Contact) are not relevant for customer analysis 
  and can be excluded from silver layer.
*/

-- Check if EM/VC/SP/GC have customer records and orders
SELECT 
    p.persontype,
    COUNT(DISTINCT p.businessentity_id) AS person_count,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(DISTINCT soh.salesorder_id) AS order_count,
    SUM(soh.totaldue) AS total_revenue
FROM bronze.aw_person_person p
LEFT JOIN bronze.aw_sales_customer c ON p.businessentity_id = c.person_id
LEFT JOIN bronze.aw_sales_salesorderheader soh ON c.customer_id = soh.customer_id
WHERE p.persontype IN ('IN', 'SC', 'EM', 'VC', 'SP', 'GC')
GROUP BY p.persontype
ORDER BY customer_count DESC;

/*
- No records for GC in bronze.aw_sales_salesorderheader so this to be excluded
- important persontypes for analysis are IN (Individual) and SC (Store Contact).
- Required transformation: Filter out GC records for silver layer as they do not represent actual customers.
============================================================================================*/

/* 
1.4 Check for duplicates 
Purpose: Spot potential duplicate records that could skew analytics.
================================================================================================*/

SELECT businessentity_id, count(*) AS cnt
FROM bronze.aw_person_person
group by businessentity_id
having count(*) > 1

/* Findings:
- records with count > 1 indicate duplicates based on businessentity_id.
- required transformation : no duplicates found in businessentity_id, 
  so no deduplication needed for this table.
================================================================================================*/

/* 1.5 Check for outliers in emailpromotion
Purpose: Identify any unusual values in the emailpromotion column.
================================================================================================*/

SELECT DISTINCT emailpromotion
FROM bronze.aw_person_person;

/* Findings:
- Expected values are typically 0, 1, 2, 3 (representing different promotion levels).
- Any values outside this range may indicate data quality issues. 'review the metadaat 
  dictionary to confirm the valid range of values for emailpromotion':
  0 = Contact does not wish to receive e-mail promotions, 
  1 = Contact does wish to receive e-mail promotions from AdventureWorks,
  2 = Contact does wish to receive e-mail promotions from AdventureWorks and selected partners. 
- required transformation : No outliers found in emailpromotion, so no correction needed.
- Define check constraint in silver layer to restrict emailpromotion values to 0, 1, 2
  to prevent future data quality issues.
================================================================================================*/

/* 1.6 Check for Leading/Trailing Spaces
Purpose: Identify any leading or trailing spaces in text columns that could affect analysis.
================================================================================================*/

SELECT 
	businessentity_id,
	firstname,
	lastname,
	LEN(firstname) AS FirstNameLength,
	LEN(lastname) AS LastNameLength
FROM bronze.aw_person_person
WHERE 
	LEN(firstname) <> LEN(LTRIM(RTRIM(firstname))) OR
	LEN(lastname) <> LEN(LTRIM(RTRIM(lastname)));

/* Findings:
- Records with leading/trailing spaces in firstname or lastname.
- No records found with leading/trailing spaces, so no trimming needed for these columns.
- Required transformation: None needed for leading/trailing spaces in firstname and lastname.
*/

-- ========================================================================
-- 2. bronze.aw_sales_salesorderheader Check
-- ========================================================================

/* 2.1 Sample data review
  purpose: Get a sense of the data structure, values, and potential issues in the salesorderheader table.
================================================================================================*/

SELECT TOP 100 *
FROM bronze.aw_sales_salesorderheader
ORDER BY orderdate DESC;
--================================================================================================

/* 2.2 Check nulls in critical columns
-- purpose: Identify missing data in key columns that are essential for analysis and transformations.
================================================================================================*/

SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN salesorder_id IS NULL THEN 1 ELSE 0 END) AS NullSalesOrderID,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS NullCustomerID,
    SUM(CASE WHEN orderdate IS NULL THEN 1 ELSE 0 END) AS NullOrderDate,
    SUM(CASE WHEN duedate IS NULL THEN 1 ELSE 0 END) AS NullDueDate,
    SUM(CASE WHEN shipdate IS NULL THEN 1 ELSE 0 END) AS NullShipDate,
    SUM(CASE WHEN status IS NULL THEN 1 ELSE 0 END) AS NullStatus,
    SUM(CASE WHEN subtotal IS NULL THEN 1 ELSE 0 END) AS NullSubtotal,
    SUM(CASE WHEN taxamt IS NULL THEN 1 ELSE 0 END) AS NullTaxAmt,
    SUM(CASE WHEN freight IS NULL THEN 1 ELSE 0 END) AS NullFreight,
    SUM(CASE WHEN totaldue IS NULL THEN 1 ELSE 0 END) AS NullTotalDue
FROM bronze.aw_sales_salesorderheader;

/*
Findings:
- No nulls in PK (salesorder_id)
- No nulls in required fields (customer_id, orderdate, status, monetary amounts)
- required transformation : Define NOT NULL constraints on salesorder_id, customer_id, orderdate,
  status, subtotal, taxamt, freight, totaldue in silver layer to ensure data integrity and quality.
================================================================================================*/

/* 2.3 Check nulls in optional/reference columns
    Purpose: Identify missing data in columns that may be optional or have valid nulls, 
    and determine if any transformations are needed.
================================================================================================*/
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN salesperson_id IS NULL THEN 1 ELSE 0 END) AS NullSalespersonID,
    SUM(CASE WHEN territory_id IS NULL THEN 1 ELSE 0 END) AS NullTerritoryID,
    SUM(CASE WHEN creditcard_id IS NULL THEN 1 ELSE 0 END) AS NullCreditCardID,
    SUM(CASE WHEN currencyrate_id IS NULL THEN 1 ELSE 0 END) AS NullCurrencyRateID,
    SUM(CASE WHEN purchaseordernumber IS NULL THEN 1 ELSE 0 END) AS NullPurchaseOrderNumber,
    SUM(CASE WHEN creditcardapprovalcode IS NULL THEN 1 ELSE 0 END) AS NullCreditCardApproval
FROM bronze.aw_sales_salesorderheader;

/*
Findings:
- No nulls in territory_id)
- Nulls in salesperson_id (expected for online orders), creditcard_id, currencyrate_id, 
  purchaseordernumber, creditcardapprovalcode (may be valid for certain order types)
- required transformation : Consider allowing nulls for salesperson_id, creditcard_id, currencyrate_id, 
  purchaseordernumber, creditcardapprovalcode in silver layer as they may be valid for 
  certain order types (e.g., online orders).
================================================================================================*/

/* 2.4 Order status distribution
   Purpose: Understand the distribution of order statuses and identify any anomalies or data quality issues.
================================================================================================*/

SELECT 
    status,
    COUNT(*) AS OrderCount,
    MIN(orderdate) AS EarliestOrder,
    MAX(orderdate) AS LatestOrder,
    SUM(totaldue) AS TotalRevenue
FROM bronze.aw_sales_salesorderheader
GROUP BY status
ORDER BY status;

/*
Findinds:
- Valid status codes (typically 1-6: In Process, Approved, Backordered, Rejected, Shipped, Cancelled)
- Only one status is persent in data which is 5 (Shipped)
- required transformation : Define check constraint on status in silver layer to restrict values
  to valid codes (1-6).
================================================================================================*/

/* 2.5 Online vs offline orders
   Purpose: Compare online and offline orders to identify differences in order 
   characteristics and potential data quality issues.
================================================================================================*/

SELECT 
    onlineorderflag,
    COUNT(*) AS OrderCount,
    SUM(totaldue) AS TotalRevenue,
    AVG(totaldue) AS AvgOrderValue,
    SUM(CASE WHEN salesperson_id IS NULL THEN 1 ELSE 0 END) AS NullSalesperson
FROM bronze.aw_sales_salesorderheader
GROUP BY onlineorderflag;

/*
Findinds:
- Online orders should have null salesperson_id which is true in data
- Revenue distribution between channels
- required transformation : no transformation needed for onlineorderflag or salesperson_id 
  as the data appears consistent with expected patterns.
================================================================================================*/

/* 2.6 Check for duplicate salesorder_id
   purpose: Ensure that salesorder_id is unique as it is the primary key,
   and identify any duplicates that could indicate data quality issues.
================================================================================================*/

SELECT 
    salesorder_id, 
    COUNT(*) AS DuplicateCount
FROM bronze.aw_sales_salesorderheader
GROUP BY salesorder_id
HAVING COUNT(*) > 1;

/*
Findings:
- No duplicates (salesorder_id is PK)
- required transformation : Define PK constraint on salesorder_id in silver layer to
  enforce uniqueness and prevent future duplicates.
================================================================================================*/

/* 2.7 Date logic validation (orderdate <= duedate)
   Purpose: Ensure that the order date is not after the due date, which would indicate a data quality issue.
================================================================================================*/

SELECT 
    COUNT(*) AS InvalidDateLogic
FROM bronze.aw_sales_salesorderheader
WHERE duedate < orderdate;

/*
Findings
- 0 rows (duedate must be >= orderdate)
- required transformation : Define check constraint in silver layer to enforce duedate >= orderdate
================================================================================================*/

/*  2.8 Date logic validation (shipdate)
   Purpose: Ensure that the ship date is not before the order date, which would indicate a data quality issue.
   ================================================================================================*/

SELECT 
    COUNT(*) AS ShippedBeforeOrdered
FROM bronze.aw_sales_salesorderheader
WHERE shipdate IS NOT NULL 
  AND shipdate < orderdate;

/*
Findings:
-0 rows (shipdate must be >= orderdate)
- required transformation : Define check constraint in silver layer to enforce
shipdate >= orderdate (if shipdate is not null)

================================================================================================*/

/* 2.9 Monetary value validation
   Purpose: Ensure that monetary values (subtotal, taxamt, freight, totaldue) are non-negative,
   and identify any records with negative values that could indicate data quality issues.
================================================================================================*/

SELECT 
    COUNT(*) AS NegativeSubtotal,
    SUM(CASE WHEN taxamt < 0 THEN 1 ELSE 0 END) AS NegativeTax,
    SUM(CASE WHEN freight < 0 THEN 1 ELSE 0 END) AS NegativeFreight,
    SUM(CASE WHEN totaldue < 0 THEN 1 ELSE 0 END) AS NegativeTotalDue
FROM bronze.aw_sales_salesorderheader
WHERE subtotal < 0;

/*
Findings:
- 0 rows (monetary values should be non-negative).
- required transformation : Define check constraints in silver layer to enforce 
  subtotal >= 0, taxamt >= 0, freight >= 0, totaldue >= 0
================================================================================================*/

/* 2.10 Totaldue calculation validation
   Purpose: Ensure that totaldue is correctly calculated as subtotal + taxamt + freight,
   and identify any records where this calculation does not hold, which would indicate a data quality issue.
================================================================================================*/

SELECT 
    COUNT(*) AS MismatchedTotals
FROM bronze.aw_sales_salesorderheader
WHERE ABS(totaldue - (subtotal + taxamt + freight)) > 0.01;  -- Allow for rounding

/*
Findings: 
- 0 rows (totaldue = subtotal + taxamt + freight)
- required transformation : Define check constraint in silver layer to enforce 
  totaldue = subtotal + taxamt + freight
================================================================================================*/

/* 2.11 Verify customer_id exists in person table (REFERENTIAL INTEGRITY)
   Purpose: Ensure that all customer_id values in salesorderheader have a corresponding 
   record in the customer table, and identify any orphaned customer records 
   that could indicate data quality issues.
================================================================================================*/

SELECT 
    COUNT(DISTINCT soh.customer_id) AS TotalCustomers,
    COUNT(DISTINCT CASE WHEN c.customer_id IS NULL THEN soh.customer_id END) AS OrphanedCustomers
FROM bronze.aw_sales_salesorderheader soh
LEFT JOIN bronze.aw_sales_customer c ON soh.customer_id = c.customer_id;

/*
Findings:
- No orphaned customers (all customer_id values in salesorderheader have a match in customer table).
- required transformation : Define FK constraint on customer_id in silver
  layer to enforce referential integrity, and prevent future orphaned records.
================================================================================================*/

/** 2.12 Order date range and distribution (TEMPORAL ANALYSIS)
   Purpose: Understand the date range of orders, identify any trends over time, and spot any gaps in the data.
================================================================================================*/

SELECT 
    YEAR(orderdate) AS OrderYear,
    COUNT(*) AS OrderCount,
    SUM(totaldue) AS YearlyRevenue,
    AVG(totaldue) AS AvgOrderValue
FROM bronze.aw_sales_salesorderheader
GROUP BY YEAR(orderdate)
ORDER BY OrderYear;

/*
Findings:  
- Date range of orders (2022 - 2025)
- Trends in order volume and revenue over time
- required transformation : Consider adding date-based partitions or indexes in silver layer to 
  optimize temporal queries.
================================================================================================*/

-- ========================================================================
-- 3. bronze.aw_sales_salesorderdetail Check
-- ========================================================================

/* 3.1 Sample data review
   Purpose: Quick look at structure and values.
================================================================================================*/
SELECT TOP 100 *
FROM bronze.aw_sales_salesorderdetail
ORDER BY salesorder_id DESC, salesorderdetail_id;

/* 3.2 Check nulls in critical columns
   Purpose: Validate data completeness for analytics (Q1-Q7 requirements).
   
================================================================================================*/
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN salesorder_id IS NULL THEN 1 ELSE 0 END) AS NullSalesOrderID,
    SUM(CASE WHEN salesorderdetail_id IS NULL THEN 1 ELSE 0 END) AS NullDetailID,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS NullProductID,
    SUM(CASE WHEN orderqty IS NULL THEN 1 ELSE 0 END) AS NullQty,
    SUM(CASE WHEN unitprice IS NULL THEN 1 ELSE 0 END) AS NullPrice,
    SUM(CASE WHEN unitpricediscount IS NULL THEN 1 ELSE 0 END) AS NullDiscount,
    SUM(CASE WHEN linetotal IS NULL THEN 1 ELSE 0 END) AS NullLineTotal
FROM bronze.aw_sales_salesorderdetail;

/*
Findings: 
- No Nulls in critical columns (salesorder_id, salesorderdetail_id,
product_id, orderqty, unitprice, unitpricediscount, linetotal).
- Required transformation: Define NOT NULL constraints on all critical columns
in silver layer to ensure data integrity and quality.
================================================================================================*/

/* 3.3 Check for duplicate composite keys
   Purpose: Ensure data integrity for aggregations (Q1, Q3, Q4).
================================================================================================*/
SELECT 
    salesorder_id,
    salesorderdetail_id,
    COUNT(*) AS DuplicateCount
FROM bronze.aw_sales_salesorderdetail
GROUP BY salesorder_id, salesorderdetail_id
HAVING COUNT(*) > 1;

/*
Findings:
- No duplicates found on composite key (salesorder_id + salesorderdetail_id).
- Required transformation: Define composite PK constraint on
(salesorder_id, salesorderdetail_id) in silver layer to enforce uniqueness and prevent future duplicates.
================================================================================================*/

/* 3.4 Quantity and pricing validation
   Purpose: Validate data for margin calculations (Q1, Q2) and basket analysis (Q3).
================================================================================================*/
SELECT 
    MIN(orderqty) AS MinQty,
    MAX(orderqty) AS MaxQty,
    AVG(CAST(orderqty AS FLOAT)) AS AvgQty,
    COUNT(CASE WHEN orderqty <= 0 THEN 1 END) AS InvalidQty,
    COUNT(CASE WHEN unitprice < 0 THEN 1 END) AS NegativePrice,
    COUNT(CASE WHEN unitpricediscount < 0 THEN 1 END) AS NegativeDiscount,
    COUNT(CASE WHEN unitpricediscount >= unitprice THEN 1 END) AS DiscountExceedsPrice
FROM bronze.aw_sales_salesorderdetail;

/*
Findings:
- MinQty: 1, MaxQty: 44, AvgQty: 2.267 (no zero or negative quantities).
- No negative prices or discounts, and no discounts that exceed the unit price.
- Required transformation: Define CHECK constraints in silver layer to enforce:
  orderqty > 0, unitprice >= 0, unitpricediscount >= 0, unitpricediscount < unitprice
================================================================================================*/

/* 3.5 Line total calculation validation
   Purpose: Ensure revenue calculations are accurate (Q1, Q7).
================================================================================================*/
SELECT 
    COUNT(*) AS MismatchedLineTotals
FROM bronze.aw_sales_salesorderdetail
WHERE ABS(linetotal - ((unitprice * (1 - unitpricediscount)) * orderqty)) > 0.01;

/*
Findings:
- 0 rows (line total calculation is accurate).
- Required transformation: None needed for line total calculation as it is correct in source data.
================================================================================================*/

/* 3.6 Verify referential integrity to salesorderheader
   Purpose: Ensure joinability for customer-level aggregations (Q1-Q7).
================================================================================================*/
SELECT 
    COUNT(DISTINCT sod.salesorder_id) AS TotalOrders,
    COUNT(DISTINCT CASE WHEN soh.salesorder_id IS NULL THEN sod.salesorder_id END) AS OrphanedOrders
FROM bronze.aw_sales_salesorderdetail sod
LEFT JOIN bronze.aw_sales_salesorderheader soh ON sod.salesorder_id = soh.salesorder_id;

/* 
Findings:
- No orphaned orders (all salesorder_id values in detail table have a match in header table).
- Required transformation: Define FK constraint on salesorder_id in silver layer 
    to enforce referential integrity and prevent future orphaned records.
================================================================================================*/

/* 3.7 Basket size distribution (for Q3: behavior analysis)
   Purpose: Analyze items per order for customer segmentation.
================================================================================================*/
SELECT 
    MIN(LineItemCount) AS MinItems,
    MAX(LineItemCount) AS MaxItems,
    AVG(CAST(LineItemCount AS FLOAT)) AS AvgItems,
    COUNT(CASE WHEN LineItemCount = 1 THEN 1 END) AS SingleItemOrders,
    COUNT(CASE WHEN LineItemCount > 10 THEN 1 END) AS LargeOrders
FROM (
    SELECT salesorder_id, COUNT(*) AS LineItemCount
    FROM bronze.aw_sales_salesorderdetail
    GROUP BY salesorder_id
) AS BasketSize;

/*
Findings:
- MinItems: 1, MaxItems: 28, AvgItems: 3.86 (average basket has ~4 items).
- 15.5% of orders are single-item, and 4.0% are large orders (>10 items).
- Required transformation: None needed for basket size distribution as the data is clean
  and ready for analysis.
================================================================================================*/
/*
========================================================================
SILVER LAYER REQUIREMENTS SUMMARY:
========================================================================

1. PRIMARY KEY:
   - Composite PK on (salesorder_id, salesorderdetail_id)

2. NOT NULL CONSTRAINTS:
   - salesorder_id, salesorderdetail_id, product_id, specialoffer_id
   - orderqty, unitprice, unitpricediscount, linetotal
   - modifieddate, rowguid

3. CHECK CONSTRAINTS:
   - orderqty > 0
   - unitprice >= 0
   - unitpricediscount >= 0
   - unitpricediscount < unitprice
   - linetotal >= 0

4. FOREIGN KEYS (add after all tables created):
   - salesorder_id -> salesorderheader(salesorder_id)
   - product_id -> product(product_id) [when available]

5. INDEXES:
   - salesorder_id (for customer aggregations - Q1, Q3, Q4)
   - product_id (for category analysis - Q3)
   - modifieddate (for incremental ETL)

6. DATA CLEANSING:
   - None needed (all data is clean)

7. GOLD LAYER READINESS:
   - Q1 (Value): Revenue, discount metrics ready
   - Q2 (Profitability): Discount amounts available for margin proxy
   - Q3 (Behavior): Basket size, product diversity metrics ready
   - Q4-Q7: Aggregable to customer/order level for cohort and CLV analysis
================================================================================================*/

-- ========================================================================
-- 4. bronze.aw_production_product Check
-- ========================================================================

/* 4.1 Sample data review
   Purpose: Quick look at structure and product attributes.
================================================================================================*/
SELECT TOP 100 *
FROM bronze.aw_production_product
ORDER BY product_id;

/*==============================================================================================*/

/* 4.2 Check nulls in critical columns
   Purpose: Validate data completeness for product analytics (Q1-Q3 requirements).
================================================================================================*/
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS NullProductID,
    SUM(CASE WHEN name IS NULL THEN 1 ELSE 0 END) AS NullName,
    SUM(CASE WHEN productnumber IS NULL THEN 1 ELSE 0 END) AS NullProductNumber,
    SUM(CASE WHEN standardcost IS NULL THEN 1 ELSE 0 END) AS NullStandardCost,
    SUM(CASE WHEN listprice IS NULL THEN 1 ELSE 0 END) AS NullListPrice,
    SUM(CASE WHEN sellstartdate IS NULL THEN 1 ELSE 0 END) AS NullSellStartDate
FROM bronze.aw_production_product;

/* 
Findinds: 
- No nulls in critical columns (product_id, name, productnumber, standardcost, listprice, sellstartdate).
- Required Transformations: Define NOT NULL constraints on all critical columns in silver
  layer to ensure data integrity and quality.
================================*/

/* 4.3 Check nulls in optional/categorization columns
   Purpose: Understand product categorization for Q3 analysis.
================================================================================================*/
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN productsubcategory_id IS NULL THEN 1 ELSE 0 END) AS NullSubcategoryID,
    SUM(CASE WHEN productmodel_id IS NULL THEN 1 ELSE 0 END) AS NullModelID,
    SUM(CASE WHEN productline IS NULL THEN 1 ELSE 0 END) AS NullProductLine,
    SUM(CASE WHEN class IS NULL THEN 1 ELSE 0 END) AS NullClass,
    SUM(CASE WHEN style IS NULL THEN 1 ELSE 0 END) AS NullStyle,
    SUM(CASE WHEN color IS NULL THEN 1 ELSE 0 END) AS NullColor
FROM bronze.aw_production_product;

/*
Findinds: 
- Significant nulls in productsubcategory_id (40%), productmodel_id (40%), and color (50%).
- Required Transformations: Consider imputation strategies for missing subcategory and model IDs, 
  or create an "Unknown" category for analysis. Color may be less critical for 
  analysis and can be left as null or replace with unknown as well.
================================================================================================*/

/* 4.4 Check for duplicate product_id
   Purpose: Ensure data integrity for product lookups (Q1, Q3).
================================================================================================*/
SELECT 
    product_id,
    COUNT(*) AS DuplicateCount
FROM bronze.aw_production_product
GROUP BY product_id
HAVING COUNT(*) > 1;

/*
Findings:
- No duplicates found on product_id (primary key).
- Required Transformations: Define PK constraint on product_id in silver layer to 
  enforce uniqueness and prevent future duplicates.
================================================================================================*/

/* 4.5 Pricing validation
   Purpose: Validate pricing data for margin analysis (Q1, Q2).
================================================================================================*/
SELECT 
    MIN(standardcost) AS MinCost,
    MAX(standardcost) AS MaxCost,
    AVG(standardcost) AS AvgCost,
    MIN(listprice) AS MinListPrice,
    MAX(listprice) AS MaxListPrice,
    AVG(listprice) AS AvgListPrice,
    COUNT(CASE WHEN standardcost < 0 THEN 1 END) AS NegativeCost,
    COUNT(CASE WHEN listprice < 0 THEN 1 END) AS NegativePrice,
    COUNT(CASE WHEN listprice < standardcost THEN 1 END) AS PricesBelowCost
FROM bronze.aw_production_product;

/*
Findings: 
- MinCost: 0, MaxCost: 2171, AvgCost: 258 (no negative costs).
- MinListPrice: 0, MaxListPrice: 2578, AvgListPrice: 438 (no negative prices).
- 0 products with list price below cost, which is good for margin analysis.
- 200 products with list price = 0, which may indicate missing pricing data and should be reviewed.
- required transformations: Define CHECK constraints in silver layer to enforce standardcost >= 0 
  and listprice >= 0.
================================================================================================*/

/* 4.6 Margin analysis
   Purpose: Calculate gross margin percentage for profitability analysis (Q2).
================================================================================================*/
SELECT 
    COUNT(*) AS TotalProducts,
    AVG((listprice - standardcost) / NULLIF(listprice, 0)) AS AvgMarginPct,
    MIN((listprice - standardcost) / NULLIF(listprice, 0)) AS MinMarginPct,
    MAX((listprice - standardcost) / NULLIF(listprice, 0)) AS MaxMarginPct,
    COUNT(CASE WHEN (listprice - standardcost) / NULLIF(listprice, 0) < 0 THEN 1 END) AS NegativeMarginProducts
FROM bronze.aw_production_product
WHERE listprice > 0;

/*
Findings:
- Average margin percentage across products (46.1%).
- Products with negative margins (sold at loss): 0.
- Margin distribution for Q2 profitability analysis: healthy margins overall.
- required transformations: None needed for margin calculation as the data is clean and ready for analysis.
================================================================================================*/

/* 4.7 Product categorization distribution
   Purpose: Understand product diversity for Q3 (customer heterogeneity).
================================================================================================*/
SELECT 
    productline,
    COUNT(*) AS ProductCount,
    AVG(listprice) AS AvgPrice,
    SUM(CASE WHEN productsubcategory_id IS NOT NULL THEN 1 ELSE 0 END) AS WithSubcategory
FROM bronze.aw_production_product
GROUP BY productline
ORDER BY ProductCount DESC;

/*
Findings:
- Distribution of products across product lines (e.g., R=Road, M=Mountain, T=Touring, S=Standard).
- Average price by product line and presence of subcategories for diversity analysis.
- required transformations: None needed for product line analysis as the data is clean and ready for analysis.
================================================================================================*/

/* 4.8 Product class and style distribution
   Purpose: Analyze product attributes for Q3 basket diversity.
================================================================================================*/
SELECT 
    class,
    style,
    COUNT(*) AS ProductCount
FROM bronze.aw_production_product
GROUP BY class, style
ORDER BY ProductCount DESC;

/*
Findings:
- Distribution of products across class (H=High, M=Medium, L=Low) 
  and style (U=Urban, M=Mountain, W=Women) for diversity analysis.
  - required transformations: None needed for class and style analysis as 
    the data is clean and ready for analysis.
================================================================================================*/

/* 4.9 Finished goods vs components
   Purpose: Filter to finished goods for customer-facing analytics (Q1, Q3).
================================================================================================*/
SELECT 
    finishedgoodsflag,
    COUNT(*) AS ProductCount,
    AVG(listprice) AS AvgPrice,
    SUM(CASE WHEN productsubcategory_id IS NOT NULL THEN 1 ELSE 0 END) AS WithSubcategory
FROM bronze.aw_production_product
GROUP BY finishedgoodsflag;

/*
Findings:
- Distribution of finished goods (finishedgoodsflag=1) vs components (finishedgoodsflag=0).
- Finished goods are likely the focus for customer analytics, while components may be less relevant.
- required transformations: Consider filtering to finishedgoodsflag = 1 in silver layer 
  for customer-facing analytics,while keeping components for internal analysis if needed.
================================================================================================*/

/* 4.10 Date logic validation
   Purpose: Ensure sell dates are logical for product lifecycle.
================================================================================================*/
SELECT 
    COUNT(CASE WHEN sellenddate IS NOT NULL AND sellenddate < sellstartdate THEN 1 END) AS InvalidDateLogic,
    COUNT(CASE WHEN sellenddate IS NULL THEN 1 END) AS ActiveProducts,
    COUNT(CASE WHEN sellenddate IS NOT NULL THEN 1 END) AS DiscontinuedProducts
FROM bronze.aw_production_product;

/*
Findings:
- No products with invalid date logic (sellenddate < sellstartdate).
- Active products (sellenddate is null) vs discontinued products (sellenddate is not null)
  for lifecycle analysis.
- required transformations: Define check constraint in silver layer to enforce 
  sellenddate IS NULL OR sellenddate >= sellstartdate, and consider adding 
  an is_active computed column for analysis.
================================================================================================*/

/* 4.11 Verify product usage in orders
   Purpose: Identify products with sales history for Q1-Q3 analytics.
================================================================================================*/
SELECT 
    COUNT(DISTINCT p.product_id) AS TotalProducts,
    COUNT(DISTINCT sod.product_id) AS ProductsWithSales,
    COUNT(DISTINCT p.product_id) - COUNT(DISTINCT sod.product_id) AS ProductsWithoutSales
FROM bronze.aw_production_product p
LEFT JOIN bronze.aw_sales_salesorderdetail sod ON p.product_id = sod.product_id;

/*
Findings:
- Products with sales history vs products without sales (potentially new or inactive products).
- required transformations: Consider filtering to products with sales history for customer-facing analytics, 
  while keeping all products for internal analysis if needed.
================================================================================================*/

/* 4.12 Product subcategory referential integrity
   Purpose: Verify category relationships for Q3 product diversity analysis.
================================================================================================*/
SELECT 
    COUNT(DISTINCT p.productsubcategory_id) AS TotalSubcategories,
    COUNT(DISTINCT CASE WHEN psc.productsubcategory_id IS NULL THEN p.productsubcategory_id END) AS OrphanedSubcategories
FROM bronze.aw_production_product p
LEFT JOIN bronze.aw_production_productsubcategory psc ON p.productsubcategory_id = psc.productsubcategory_id
WHERE p.productsubcategory_id IS NOT NULL;

/*
Findings:
- No orphaned subcategories (all productsubcategory_id values have a match in productsubcategory table).
- required transformations: Define FK constraint on productsubcategory_id in silver
  layer to enforce referential integrity,and prevent future orphaned records.
================================================================================================*/

/*
========================================================================
SILVER LAYER REQUIREMENTS SUMMARY:
========================================================================

Based on EDA findings from bronze.aw_production_product:

1. PRIMARY KEY:
   - PK on product_id

2. NOT NULL CONSTRAINTS:
   - product_id, name, productnumber
   - makeflag, finishedgoodsflag
   - standardcost, listprice
   - sellstartdate
   - modifieddate, rowguid

3. CHECK CONSTRAINTS:
   - standardcost >= 0
   - listprice >= 0
   - sellenddate IS NULL OR sellenddate >= sellstartdate

4. NULL HANDLING:
   - Allow nulls: productsubcategory_id (40%), productmodel_id (40%), 
     color (50%), productline, class, style
   - Allow nulls: sellenddate, discontinueddate (lifecycle management)
   - Allow nulls: size, weight, sizeunitmeasurecode, weightunitmeasurecode

5. COMPUTED COLUMNS:
   - margin_pct: Calculate gross margin percentage for Q2 analysis
   - is_active: Flag for active products (sellenddate IS NULL)

6. FILTERING STRATEGY:
   - Keep all products (both finished goods and components)
   - Use finishedgoodsflag and is_active for filtering in gold layer

7. FOREIGN KEYS (add after all tables created):
   - productsubcategory_id -> productsubcategory(productsubcategory_id)
   - productmodel_id -> productmodel(productmodel_id)

8. INDEXES:
   - productsubcategory_id (category rollup - Q3)
   - finishedgoodsflag (filtering)
   - listprice (pricing analysis - Q1)
   - is_active computed column (active product filtering)
   - modifieddate (incremental ETL)

9. DATA QUALITY NOTES:
   - 200 products with listprice = 0 (likely components) - kept for completeness
   - No negative margins detected (healthy margin profile)
   - Average margin: 46.1%
   - All referential integrity validated

10. GOLD LAYER READINESS:
    - Q1 (Value): Product revenue by category, price bands, margin analysis
    - Q2 (Profitability): Product margin analysis via margin_pct
    - Q3 (Behavior): Product diversity, category mix in baskets
================================================================================================*/

-- Created by Azab Basha - March 2026
/*
Comprehensive Exploratory Data Analysis for remaining bronze tables.
This script identifies data quality issues and informs silver layer design for customer analytics (Q1-Q7).
Run each query and document findings in the comments below each query.
*/

-- ========================================================================
-- 5. bronze.aw_sales_customer Check
-- ========================================================================

/* 5.1 Sample data review
   Purpose: Understand customer structure and customer-person-store relationships.
================================================================================================*/
SELECT TOP 100 * FROM bronze.aw_sales_customer ORDER BY customer_id;

/* 5.2 Check nulls in critical columns
   Purpose: Identify missing data in customer identification fields.
================================================================================================*/
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS NullCustomerID,
    SUM(CASE WHEN person_id IS NULL THEN 1 ELSE 0 END) AS NullPersonID,
    SUM(CASE WHEN store_id IS NULL THEN 1 ELSE 0 END) AS NullStoreID,
    SUM(CASE WHEN territory_id IS NULL THEN 1 ELSE 0 END) AS NullTerritoryID
FROM bronze.aw_sales_customer;

/*
Findings:
- TotalRows: [19820]
- NullCustomerID: [0]
- NullPersonID: [701] (individual customers have person_id, store customers have store_id)
- NullStoreID: [18484] (most customers are individuals, not stores)
- NullTerritoryID: [0]
- Required transformation: Define NOT NULL on customer_id, territory_id. Allow nulls on person_id and store_id (mutually exclusive).
================================================================================================*/

/* 5.3 Check for duplicate customer_id
   Purpose: Ensure customer_id uniqueness.
================================================================================================*/
SELECT customer_id, COUNT(*) AS DuplicateCount
FROM bronze.aw_sales_customer
GROUP BY customer_id
HAVING COUNT(*) > 1;

/*
Findings:
- Duplicates: [0]
- Required transformation: Define PK constraint on customer_id.
================================================================================================*/

/* 5.4 Verify person_id and store_id mutual exclusivity
   Purpose: Ensure a customer is either a person OR a store, not both.
================================================================================================*/
SELECT 
    COUNT(*) AS TotalCustomers,
    SUM(CASE WHEN person_id IS NOT NULL AND store_id IS NOT NULL THEN 1 ELSE 0 END) AS BothPersonAndStore,
    SUM(CASE WHEN person_id IS NULL AND store_id IS NULL THEN 1 ELSE 0 END) AS NeitherPersonNorStore,
    SUM(CASE WHEN person_id IS NOT NULL THEN 1 ELSE 0 END) AS PersonCustomers,
    SUM(CASE WHEN store_id IS NOT NULL THEN 1 ELSE 0 END) AS StoreCustomers
FROM bronze.aw_sales_customer;

/*
Findings:
- BothPersonAndStore: [635]
- NeitherPersonNorStore: [0] 
- PersonCustomers: [19119]
- StoreCustomers: [1336]
- Required transformation: Define CHECK constraint to ensure (person_id IS NOT NULL AND store_id IS NULL) OR (person_id IS NULL AND store_id IS NOT NULL).
================================================================================================*/

/* 5.5 Verify referential integrity to person table
   Purpose: Ensure all person_id values exist in person table.
================================================================================================*/
SELECT 
    COUNT(DISTINCT c.customer_id) AS TotalPersonCustomers,
    COUNT(DISTINCT CASE WHEN p.businessentity_id IS NULL THEN c.customer_id END) AS OrphanedCustomers
FROM bronze.aw_sales_customer c
LEFT JOIN bronze.aw_person_person p ON c.person_id = p.businessentity_id
WHERE c.person_id IS NOT NULL;

/*
Findings:
- TotalPersonCustomers: [19119]
- OrphanedCustomers: [0]
- Required transformation: Define FK constraint person_id -> person(businessentity_id).
================================================================================================*/

/*
========================================================================
SILVER LAYER REQUIREMENTS SUMMARY:
========================================================================

1. PRIMARY KEY:
   - PK on customer_id

2. NOT NULL CONSTRAINTS:
   - customer_id, territory_id, modifieddate, rowguid

3. CHECK CONSTRAINTS:
   - (person_id IS NOT NULL AND store_id IS NULL) OR (person_id IS NULL AND store_id IS NOT NULL)

4. FOREIGN KEYS (add after all tables created):
   - person_id -> person(businessentity_id)
   - territory_id -> territory(territory_id)

5. INDEXES:
   - person_id (for customer-person joins)
   - territory_id (for territory analysis)
   - modifieddate (for incremental ETL)

6. GOLD LAYER READINESS:
   - Q1-Q7: Bridge table between person and orders, critical for all customer analytics
================================================================================================*/

-- ========================================================================
-- 6. bronze.aw_production_productsubcategory Check
-- ========================================================================

/* 6.1 Sample data review */
SELECT TOP 100 * FROM bronze.aw_production_productsubcategory ORDER BY productsubcategory_id;

/* 6.2 Check nulls in critical columns */
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN productsubcategory_id IS NULL THEN 1 ELSE 0 END) AS NullSubcategoryID,
    SUM(CASE WHEN productcategory_id IS NULL THEN 1 ELSE 0 END) AS NullCategoryID,
    SUM(CASE WHEN name IS NULL THEN 1 ELSE 0 END) AS NullName
FROM bronze.aw_production_productsubcategory;

/*
Findings:
- TotalRows: [37]
- No nulls in critical columns
- Required transformation: Define NOT NULL on productsubcategory_id, productcategory_id, name.
================================================================================================*/

/* 6.3 Check for duplicates */
SELECT productsubcategory_id, COUNT(*) AS DuplicateCount
FROM bronze.aw_production_productsubcategory
GROUP BY productsubcategory_id
HAVING COUNT(*) > 1;

/*
Findings:
- Duplicates: [0] (expect 0)
- Required transformation: Define PK constraint on productsubcategory_id.
================================================================================================*/

/* 6.4 Verify referential integrity to category */
SELECT 
    COUNT(DISTINCT psc.productsubcategory_id) AS TotalSubcategories,
    COUNT(DISTINCT CASE WHEN pc.productcategory_id IS NULL THEN psc.productsubcategory_id END) AS OrphanedSubcategories
FROM bronze.aw_production_productsubcategory psc
LEFT JOIN bronze.aw_production_productcategory pc ON psc.productcategory_id = pc.productcategory_id;

/*
Findings:
- TotalSubcategories: [0]
- OrphanedSubcategories: [0] 
- Required transformation: Define FK constraint productcategory_id -> productcategory(productcategory_id).
================================================================================================*/

/*
========================================================================
SILVER LAYER REQUIREMENTS SUMMARY:
========================================================================

1. PRIMARY KEY:
   - PK on productsubcategory_id

2. NOT NULL CONSTRAINTS:
   - productsubcategory_id, productcategory_id, name, modifieddate, rowguid

3. FOREIGN KEYS (add after all tables created):
   - productcategory_id -> productcategory(productcategory_id)

4. INDEXES:
   - productcategory_id (for category rollup)
   - name (for product hierarchy navigation)

5. GOLD LAYER READINESS:
   - Q3: Essential for product diversity and category mix analysis
================================================================================================*/

-- ========================================================================
-- 7. bronze.aw_production_productcategory Check
-- ========================================================================

/* 7.1 Sample data review */
SELECT TOP 100 * FROM bronze.aw_production_productcategory ORDER BY productcategory_id;

/* 7.2 Check nulls in critical columns */
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN productcategory_id IS NULL THEN 1 ELSE 0 END) AS NullCategoryID,
    SUM(CASE WHEN name IS NULL THEN 1 ELSE 0 END) AS NullName
FROM bronze.aw_production_productcategory;

/*
Findings:
- TotalRows: [4] (Bikes, Components, Clothing, Accessories)
- No nulls expected
- Required transformation: Define NOT NULL on productcategory_id, name.
================================================================================================*/

/* 7.3 Check for duplicates */
SELECT productcategory_id, COUNT(*) AS DuplicateCount
FROM bronze.aw_production_productcategory
GROUP BY productcategory_id
HAVING COUNT(*) > 1;

/*
Findings:
- Duplicates: [0]
- Required transformation: Define PK constraint on productcategory_id.
================================================================================================*/

/* 7.4 Category distribution */
SELECT name, COUNT(*) AS CategoryCount
FROM bronze.aw_production_productcategory
GROUP BY name
ORDER BY name;

/*
Findings:
- List of categories: [4]
- Required transformation: None, small static reference table.
================================================================================================*/

/*
========================================================================
SILVER LAYER REQUIREMENTS SUMMARY:
========================================================================

1. PRIMARY KEY:
   - PK on productcategory_id

2. NOT NULL CONSTRAINTS:
   - productcategory_id, name, modifieddate, rowguid

3. INDEXES:
   - name (for category lookups)

4. GOLD LAYER READINESS:
   - Q3: Top-level product categorization for diversity analysis
================================================================================================*/

-- ========================================================================
-- 8. bronze.aw_person_address Check
-- ========================================================================

/* 8.1 Sample data review */
SELECT TOP 100 * FROM bronze.aw_person_address ORDER BY address_id;

/* 8.2 Check nulls in critical columns */
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN address_id IS NULL THEN 1 ELSE 0 END) AS NullAddressID,
    SUM(CASE WHEN addressline1 IS NULL THEN 1 ELSE 0 END) AS NullAddressLine1,
    SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END) AS NullCity,
    SUM(CASE WHEN stateprovince_id IS NULL THEN 1 ELSE 0 END) AS NullStateProvinceID,
    SUM(CASE WHEN postalcode IS NULL THEN 1 ELSE 0 END) AS NullPostalCode
FROM bronze.aw_person_address;

/*
Findings:
- TotalRows: [19614]
- Required transformation: Define NOT NULL on address_id, addressline1, city, stateprovince_id, postalcode.
================================================================================================*/

/* 8.3 Check for duplicates */
SELECT address_id, COUNT(*) AS DuplicateCount
FROM bronze.aw_person_address
GROUP BY address_id
HAVING COUNT(*) > 1;

/*
Findings:
- Duplicates: [0]
- Required transformation: Define PK constraint on address_id.
================================================================================================*/

/* 8.4 Verify referential integrity to stateprovince */
SELECT 
    COUNT(DISTINCT a.address_id) AS TotalAddresses,
    COUNT(DISTINCT CASE WHEN sp.stateprovince_id IS NULL THEN a.address_id END) AS OrphanedAddresses
FROM bronze.aw_person_address a
LEFT JOIN bronze.aw_person_stateprovince sp ON a.stateprovince_id = sp.stateprovince_id;

/*
Findings:
- TotalAddresses: [19614]
- OrphanedAddresses: [0] 
- Required transformation: Define FK constraint stateprovince_id -> stateprovince(stateprovince_id).
================================================================================================*/

/*
========================================================================
SILVER LAYER REQUIREMENTS SUMMARY:
========================================================================

1. PRIMARY KEY:
   - PK on address_id

2. NOT NULL CONSTRAINTS:
   - address_id, addressline1, city, stateprovince_id, postalcode, modifieddate, rowguid

3. FOREIGN KEYS (add after all tables created):
   - stateprovince_id -> stateprovince(stateprovince_id)

4. INDEXES:
   - stateprovince_id (for geographic analysis)
   - city (for city-level aggregation)
   - postalcode (for ZIP code analysis)

5. GOLD LAYER READINESS:
   - Q3, Q4: Geographic segmentation for customer heterogeneity and cohort analysis
================================================================================================*/

-- ========================================================================
-- 9. bronze.aw_person_stateprovince Check
-- ========================================================================

/* 9.1 Sample data review */
SELECT TOP 100 * FROM bronze.aw_person_stateprovince ORDER BY stateprovince_id;

/* 9.2 Check nulls in critical columns */
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN stateprovince_id IS NULL THEN 1 ELSE 0 END) AS NullStateProvinceID,
    SUM(CASE WHEN stateprovincecode IS NULL THEN 1 ELSE 0 END) AS NullStateProvinceCode,
    SUM(CASE WHEN countryregioncode IS NULL THEN 1 ELSE 0 END) AS NullCountryRegionCode,
    SUM(CASE WHEN name IS NULL THEN 1 ELSE 0 END) AS NullName
FROM bronze.aw_person_stateprovince;

/*
Findings:
- TotalRows: [181]
- Required transformation: Define NOT NULL on all critical columns.
================================================================================================*/

/* 9.3 Check for duplicates */
SELECT stateprovince_id, COUNT(*) AS DuplicateCount
FROM bronze.aw_person_stateprovince
GROUP BY stateprovince_id
HAVING COUNT(*) > 1;

/*
Findings:
- Duplicates: [0] 
- Required transformation: Define PK constraint on stateprovince_id.
================================================================================================*/

/*
========================================================================
SILVER LAYER REQUIREMENTS SUMMARY:
========================================================================

1. PRIMARY KEY:
   - PK on stateprovince_id

2. NOT NULL CONSTRAINTS:
   - stateprovince_id, stateprovincecode, countryregioncode, name, modifieddate, rowguid

3. INDEXES:
   - countryregioncode (for country-level rollup)
   - name (for state name lookups)

4. GOLD LAYER READINESS:
   - Q3, Q4: Geographic dimension for customer segmentation
================================================================================================*/

-- ========================================================================
-- 10. bronze.aw_person_businessentityaddress Check
-- ========================================================================

/* 10.1 Sample data review */
SELECT TOP 100 * FROM bronze.aw_person_businessentityaddress ORDER BY business_entity_id;

/* 10.2 Check nulls in critical columns */
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN business_entity_id IS NULL THEN 1 ELSE 0 END) AS NullBusinessEntityID,
    SUM(CASE WHEN address_id IS NULL THEN 1 ELSE 0 END) AS NullAddressID,
    SUM(CASE WHEN addresstype_id IS NULL THEN 1 ELSE 0 END) AS NullAddressTypeID
FROM bronze.aw_person_businessentityaddress;

/*
Findings:
- TotalRows: [19614]
- Required transformation: Define NOT NULL on all columns (bridge table).
================================================================================================*/

/* 10.3 Check for duplicate composite keys */
SELECT business_entity_id, address_id, addresstype_id, COUNT(*) AS DuplicateCount
FROM bronze.aw_person_businessentityaddress
GROUP BY business_entity_id, address_id, addresstype_id
HAVING COUNT(*) > 1;

/*
Findings:
- Duplicates: [0]
- Required transformation: Define composite PK on (business_entity_id, address_id, addresstype_id).
================================================================================================*/

/* 10.4 Verify referential integrity */
SELECT 
    COUNT(*) AS TotalRecords,
    SUM(CASE WHEN p.businessentity_id IS NULL THEN 1 ELSE 0 END) AS OrphanedPerson,
    SUM(CASE WHEN a.address_id IS NULL THEN 1 ELSE 0 END) AS OrphanedAddress
FROM bronze.aw_person_businessentityaddress bea
LEFT JOIN bronze.aw_person_person p ON bea.business_entity_id = p.businessentity_id
LEFT JOIN bronze.aw_person_address a ON bea.address_id = a.address_id;

/*
Findings:
- OrphanedPerson: [0] 
- OrphanedAddress: [0]
- Required transformation: Define FK constraints.
================================================================================================*/

/*
========================================================================
SILVER LAYER REQUIREMENTS SUMMARY:
========================================================================

1. PRIMARY KEY:
   - Composite PK on (business_entity_id, address_id, addresstype_id)

2. NOT NULL CONSTRAINTS:
   - All columns

3. FOREIGN KEYS (add after all tables created):
   - business_entity_id -> person(business_entity_id)
   - address_id -> address(address_id)
   - addresstype_id -> addresstype(addresstype_id)

4. INDEXES:
   - address_id (for address lookups)
   - addresstype_id (for type filtering)

5. GOLD LAYER READINESS:
   - Q3: Links customers to geographic locations for segmentation
================================================================================================*/

-- ========================================================================
-- 11. bronze.aw_person_emailaddress Check
-- ========================================================================

/* 11.1 Sample data review */
SELECT TOP 100 * FROM bronze.aw_person_emailaddress ORDER BY business_entity_id;

/* 11.2 Check nulls in critical columns */
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN business_entity_id IS NULL THEN 1 ELSE 0 END) AS NullBusinessEntityID,
    SUM(CASE WHEN emailaddress_id IS NULL THEN 1 ELSE 0 END) AS NullEmailAddressID,
    SUM(CASE WHEN emailaddress IS NULL THEN 1 ELSE 0 END) AS NullEmailAddress
FROM bronze.aw_person_emailaddress;

/*
Findings:
- TotalRows: [19972]
- Required transformation: Define NOT NULL on all critical columns.
================================================================================================*/

/* 11.3 Check for duplicate composite keys */
SELECT business_entity_id, emailaddress_id, COUNT(*) AS DuplicateCount
FROM bronze.aw_person_emailaddress
GROUP BY business_entity_id, emailaddress_id
HAVING COUNT(*) > 1;

/*
Findings:
- Duplicates: [0]
- Required transformation: Define composite PK on (business_entity_id, emailaddress_id).
================================================================================================*/

/* 11.4 Email format validation */
SELECT 
    COUNT(*) AS TotalEmails,
    SUM(CASE WHEN emailaddress NOT LIKE '%@%' THEN 1 ELSE 0 END) AS InvalidEmailFormat,
    SUM(CASE WHEN emailaddress NOT LIKE '%@%.%' THEN 1 ELSE 0 END) AS SuspiciousEmailFormat
FROM bronze.aw_person_emailaddress;

/*
Findings:
- InvalidEmailFormat: [0]
- SuspiciousEmailFormat: [0]
- Required transformation: Consider CHECK constraint for basic email format.
================================================================================================*/

/*
========================================================================
SILVER LAYER REQUIREMENTS SUMMARY:
========================================================================

1. PRIMARY KEY:
   - Composite PK on (business_entity_id, emailaddress_id)

2. NOT NULL CONSTRAINTS:
   - business_entity_id, emailaddress_id, emailaddress, modifieddate, rowguid

3. CHECK CONSTRAINTS:
   - emailaddress LIKE '%@%' (basic email validation)

4. FOREIGN KEYS (add after all tables created):
   - business_entity_id -> person(business_entity_id)

5. INDEXES:
   - business_entity_id (for person lookup)

6. GOLD LAYER READINESS:
   - Q6: Contact information for customer action recommendations
================================================================================================*/

-- ========================================================================
-- 12. bronze.aw_sales_salesterritory Check
-- ========================================================================

/* 12.1 Sample data review */
SELECT TOP 100 * FROM bronze.aw_sales_salesterritory ORDER BY territory_id;

/* 12.2 Check nulls in critical columns */
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN territory_id IS NULL THEN 1 ELSE 0 END) AS NullTerritoryID,
    SUM(CASE WHEN name IS NULL THEN 1 ELSE 0 END) AS NullName,
    SUM(CASE WHEN countryregioncode IS NULL THEN 1 ELSE 0 END) AS NullCountryRegionCode
FROM bronze.aw_sales_salesterritory;

/*
Findings:
- TotalRows: [10]
- Required transformation: Define NOT NULL on all critical columns.
================================================================================================*/

/* 12.3 Check for duplicates */
SELECT territory_id, COUNT(*) AS DuplicateCount
FROM bronze.aw_sales_salesterritory
GROUP BY territory_id
HAVING COUNT(*) > 1;

/*
Findings:
- Duplicates: [0]
- Required transformation: Define PK constraint on territory_id.
================================================================================================*/

/*
========================================================================
SILVER LAYER REQUIREMENTS SUMMARY:
========================================================================

1. PRIMARY KEY:
   - PK on territory_id

2. NOT NULL CONSTRAINTS:
   - territory_id, name, countryregioncode, territory_group, modifieddate, rowguid

3. INDEXES:
   - countryregioncode (for country-level aggregation)
   - territory_group (for regional analysis)

4. GOLD LAYER READINESS:
   - Q3, Q4: Territory dimension for customer segmentation and cohort analysis
================================================================================================*/

-- ========================================================================
-- 13. bronze.aw_sales_specialoffer Check
-- ========================================================================

/* 13.1 Sample data review */
SELECT TOP 100 * FROM bronze.aw_sales_specialoffer ORDER BY specialoffer_id;

/* 13.2 Check nulls in critical columns */
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN specialoffer_id IS NULL THEN 1 ELSE 0 END) AS NullOfferID,
    SUM(CASE WHEN description IS NULL THEN 1 ELSE 0 END) AS NullDescription,
    SUM(CASE WHEN discountpct IS NULL THEN 1 ELSE 0 END) AS NullDiscountPct,
    SUM(CASE WHEN type IS NULL THEN 1 ELSE 0 END) AS NullType,
    SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END) AS NullCategory,
    SUM(CASE WHEN startdate IS NULL THEN 1 ELSE 0 END) AS NullStartDate,
    SUM(CASE WHEN enddate IS NULL THEN 1 ELSE 0 END) AS NullEndDate
FROM bronze.aw_sales_specialoffer;

/*
Findings:
- TotalRows: [16]
- Required transformation: Define NOT NULL on all critical columns.
================================================================================================*/

/* 13.3 Check for duplicates */
SELECT specialoffer_id, COUNT(*) AS DuplicateCount
FROM bronze.aw_sales_specialoffer
GROUP BY specialoffer_id
HAVING COUNT(*) > 1;

/*
Findings:
- Duplicates: [0]
- Required transformation: Define PK constraint on specialoffer_id.
================================================================================================*/

/* 13.4 Discount percentage validation */
SELECT 
    MIN(discountpct) AS MinDiscount,
    MAX(discountpct) AS MaxDiscount,
    AVG(discountpct) AS AvgDiscount,
    COUNT(CASE WHEN discountpct < 0 THEN 1 END) AS NegativeDiscount,
    COUNT(CASE WHEN discountpct > 1 THEN 1 END) AS DiscountOver100Pct
FROM bronze.aw_sales_specialoffer;

/*
Findings:
- MinDiscount: [0]
- MaxDiscount: [50%]
- Required transformation: Define CHECK constraint discountpct BETWEEN 0 AND 1.
================================================================================================*/

/* 13.5 Date logic validation */
SELECT 
    COUNT(CASE WHEN enddate < startdate THEN 1 END) AS InvalidDateLogic
FROM bronze.aw_sales_specialoffer;

/*
Findings:
- InvalidDateLogic: [0]
- Required transformation: Define CHECK constraint enddate >= startdate.
================================================================================================*/

/*
========================================================================
SILVER LAYER REQUIREMENTS SUMMARY:
========================================================================

1. PRIMARY KEY:
   - PK on specialoffer_id

2. NOT NULL CONSTRAINTS:
   - specialoffer_id, description, discountpct, type, category, startdate, enddate, modifieddate, rowguid

3. CHECK CONSTRAINTS:
   - discountpct BETWEEN 0 AND 1
   - enddate >= startdate

4. COMPUTED COLUMNS:
   - is_active AS (CASE WHEN GETDATE() BETWEEN startdate AND enddate THEN 1 ELSE 0 END)

5. INDEXES:
   - startdate, enddate (for active offer queries)
   - category (for offer segmentation)

6. GOLD LAYER READINESS:
   - Q2: Discount impact analysis on profitability
   - Q6: Promotional effectiveness for customer actions
================================================================================================*/

-- ========================================================================
-- 14. bronze.aw_sales_specialofferproduct Check
-- ========================================================================

/* 14.1 Sample data review */
SELECT TOP 100 * FROM bronze.aw_sales_specialofferproduct ORDER BY specialoffer_id, product_id;

/* 14.2 Check nulls in critical columns */
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN specialoffer_id IS NULL THEN 1 ELSE 0 END) AS NullOfferID,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS NullProductID
FROM bronze.aw_sales_specialofferproduct;

/*
Findings:
- TotalRows: [538]
- Required transformation: Define NOT NULL on all columns (bridge table).
================================================================================================*/

/* 14.3 Check for duplicate composite keys */
SELECT specialoffer_id, product_id, COUNT(*) AS DuplicateCount
FROM bronze.aw_sales_specialofferproduct
GROUP BY specialoffer_id, product_id
HAVING COUNT(*) > 1;

/*
Findings:
- Duplicates: [0] 
- Required transformation: Define composite PK on (specialoffer_id, product_id).
================================================================================================*/

/* 14.4 Verify referential integrity */
SELECT 
    COUNT(*) AS TotalRecords,
    SUM(CASE WHEN so.specialoffer_id IS NULL THEN 1 ELSE 0 END) AS OrphanedOffer,
    SUM(CASE WHEN p.product_id IS NULL THEN 1 ELSE 0 END) AS OrphanedProduct
FROM bronze.aw_sales_specialofferproduct sop
LEFT JOIN bronze.aw_sales_specialoffer so ON sop.specialoffer_id = so.specialoffer_id
LEFT JOIN bronze.aw_production_product p ON sop.product_id = p.product_id;

/*
Findings:
- OrphanedOffer: [0]
- OrphanedProduct: [0]
- Required transformation: Define FK constraints.
================================================================================================*/

/*
========================================================================
SILVER LAYER REQUIREMENTS SUMMARY:
========================================================================

1. PRIMARY KEY:
   - Composite PK on (specialoffer_id, product_id)

2. NOT NULL CONSTRAINTS:
   - All columns

3. FOREIGN KEYS (add after all tables created):
   - specialoffer_id -> specialoffer(specialoffer_id)
   - product_id -> product(product_id)

4. INDEXES:
   - product_id (for product-to-offer lookups)

5. GOLD LAYER READINESS:
   - Q2: Links promotions to products for margin analysis
================================================================================================*/

-- ========================================================================
-- 15. bronze.aw_sales_salesreason Check
-- ========================================================================

/* 15.1 Sample data review */
SELECT TOP 100 * FROM bronze.aw_sales_salesreason ORDER BY salesreason_id;

/* 15.2 Check nulls in critical columns */
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN salesreason_id IS NULL THEN 1 ELSE 0 END) AS NullSalesReasonID,
    SUM(CASE WHEN name IS NULL THEN 1 ELSE 0 END) AS NullName,
    SUM(CASE WHEN reasontype IS NULL THEN 1 ELSE 0 END) AS NullReasonType
FROM bronze.aw_sales_salesreason;

/*
Findings:
- TotalRows: [10]
- Required transformation: Define NOT NULL on all critical columns.
================================================================================================*/

/* 15.3 Check for duplicates */
SELECT salesreason_id, COUNT(*) AS DuplicateCount
FROM bronze.aw_sales_salesreason
GROUP BY salesreason_id
HAVING COUNT(*) > 1;

/*
Findings:
- Duplicates: [0]
- Required transformation: Define PK constraint on salesreason_id.
================================================================================================*/

/* 15.4 Reason type distribution */
SELECT reasontype, COUNT(*) AS ReasonCount
FROM bronze.aw_sales_salesreason
GROUP BY reasontype
ORDER BY reasontype;

/*
Findings:
- Types:( Marketing, Promotion, Other)
- Required transformation: None, small reference table.
================================================================================================*/

/*
========================================================================
SILVER LAYER REQUIREMENTS SUMMARY:
========================================================================

1. PRIMARY KEY:
   - PK on salesreason_id

2. NOT NULL CONSTRAINTS:
   - salesreason_id, name, reasontype, modifieddate

3. INDEXES:
   - reasontype (for reason type analysis)

4. GOLD LAYER READINESS:
   - Q3: Customer purchase motivation for heterogeneity analysis
   - Q6: Inform customer action recommendations
================================================================================================*/

-- ========================================================================
-- 16. bronze.aw_sales_salesorderheadersalesreason Check
-- ========================================================================

/* 16.1 Sample data review */
SELECT TOP 100 * FROM bronze.aw_sales_salesorderheadersalesreason ORDER BY salesorder_id;

/* 16.2 Check nulls in critical columns */
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN salesorder_id IS NULL THEN 1 ELSE 0 END) AS NullSalesOrderID,
    SUM(CASE WHEN salesreason_id IS NULL THEN 1 ELSE 0 END) AS NullSalesReasonID
FROM bronze.aw_sales_salesorderheadersalesreason;

/*
Findings:
- TotalRows: [27647]
- Required transformation: Define NOT NULL on all columns (bridge table).
================================================================================================*/

/* 16.3 Check for duplicate composite keys */
SELECT salesorder_id, salesreason_id, COUNT(*) AS DuplicateCount
FROM bronze.aw_sales_salesorderheadersalesreason
GROUP BY salesorder_id, salesreason_id
HAVING COUNT(*) > 1;

/*
Findings:
- Duplicates: [0]
- Required transformation: Define composite PK on (salesorder_id, salesreason_id).
================================================================================================*/

/* 16.4 Verify referential integrity */
SELECT 
    COUNT(*) AS TotalRecords,
    SUM(CASE WHEN soh.salesorder_id IS NULL THEN 1 ELSE 0 END) AS OrphanedOrder,
    SUM(CASE WHEN sr.salesreason_id IS NULL THEN 1 ELSE 0 END) AS OrphanedReason
FROM bronze.aw_sales_salesorderheadersalesreason sosr
LEFT JOIN bronze.aw_sales_salesorderheader soh ON sosr.salesorder_id = soh.salesorder_id
LEFT JOIN bronze.aw_sales_salesreason sr ON sosr.salesreason_id = sr.salesreason_id;

/*
Findings:
- OrphanedOrder: [0] 
- OrphanedReason: [0]
- Required transformation: Define FK constraints.
================================================================================================*/

/*
========================================================================
SILVER LAYER REQUIREMENTS SUMMARY:
========================================================================

1. PRIMARY KEY:
   - Composite PK on (salesorder_id, salesreason_id)

2. NOT NULL CONSTRAINTS:
   - All columns

3. FOREIGN KEYS (add after all tables created):
   - salesorder_id -> salesorderheader(salesorder_id)
   - salesreason_id -> salesreason(salesreason_id)

4. INDEXES:
   - salesreason_id (for reason-based analysis)

5. GOLD LAYER READINESS:
   - Q3: Links purchase motivation to customer behavior
================================================================================================*/

-- ========================================================================
-- 17. bronze.aw_person_addresstype Check
-- ========================================================================

/* 17.1 Sample data review */
SELECT TOP 100 * FROM bronze.aw_person_addresstype ORDER BY addresstype_id;

/* 17.2 Check nulls in critical columns */
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN addresstype_id IS NULL THEN 1 ELSE 0 END) AS NullAddressTypeID,
    SUM(CASE WHEN name IS NULL THEN 1 ELSE 0 END) AS NullName
FROM bronze.aw_person_addresstype;

/*
Findings:
- TotalRows: [6] (Home, Shipping, Billing, etc.)
- Required transformation: Define NOT NULL on all columns.
================================================================================================*/

/* 17.3 Check for duplicates */
SELECT addresstype_id, COUNT(*) AS DuplicateCount
FROM bronze.aw_person_addresstype
GROUP BY addresstype_id
HAVING COUNT(*) > 1;

/*
Findings:
- Duplicates: [0]
- Required transformation: Define PK constraint on addresstype_id.
================================================================================================*/

/* 17.4 Address type distribution */
SELECT name, COUNT(*) AS TypeCount
FROM bronze.aw_person_addresstype
GROUP BY name
ORDER BY name;

/*
Findings:
- Types: [Archive, Billing, Home, Main Office, Primary, Shipping]
- Required transformation: None, small static reference table.
================================================================================================*/

/*
========================================================================
SILVER LAYER REQUIREMENTS SUMMARY:
========================================================================

1. PRIMARY KEY:
   - PK on addresstype_id

2. NOT NULL CONSTRAINTS:
   - addresstype_id, name, modifieddate, rowguid

3. INDEXES:
   - name (for type lookups)

4. GOLD LAYER READINESS:
   - Supporting table for address relationships
================================================================================================*/
