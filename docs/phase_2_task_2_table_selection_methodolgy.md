This document provides a **complete step-by-step guide** for anyone new to the AdventureWorks database or customer analytics projects. It shows you exactly how tables were identified, selected, and organized into the final Entity-Relationship Diagram (ERD) used to answer 7 key customer analytics questions.

---

📅 Document Created: May 2026 
👤 Author: Azab Basha
🏢 Project: AdventureWorks End-to-End Customer Analytics
📂 Phase: Phase 2 – Table Selection Methodology

---

## 📋 Overview

**Goal**: Build a focused ERD for customer analytics that answers 7 strategic questions about customer value, behavior, and lifetime value (CLV).

**Data Source**: AdventureWorks 2025 (SQL Server)

**Methodology**: 4-phase discovery process using `sql/phase_2_task_1_metadata_explorqtion.sql`

**Final Output**: Enhanced ERD (`sql/phase_2_task_4_customer_analytics_erd.dbml`) with 17 carefully selected tables

---

## 🎯 The 7 Strategic Questions

Before diving into table selection, we defined **7 core questions** that drive all analytics requirements:

### Q1: Who are our most valuable customers?
- **Metrics**: Total revenue, order count, average order value, gross margin, CLV proxy, Pareto concentration
- **Data Grain**: Customer × Order
- **Time Windows**: Full history, Last 12 months, Last 24 months
- **Key Entities**: Customer, SalesOrderHeader, SalesOrderDetail

### Q2: Which customers are unprofitable or risky?
- **Metrics**: Revenue per customer, cost proxies (returns, discounts), recency, frequency
- **Data Grain**: Customer × Time (monthly)
- **Time Windows**: Rolling windows (3, 6, 12 months)
- **Key Entities**: Customer, Orders, Returns (if available)

### Q3: How do customers differ in behavior (heterogeneity)?
- **Metrics**: RFM (Recency, Frequency, Monetary), basket size, category diversity
- **Data Grain**: Customer level
- **Time Windows**: Calibration window, Observation window
- **Key Entities**: Customer, Orders, Products

### Q4: Are newer customer cohorts better or worse?
- **Metrics**: Cohort size, retention rate, revenue per cohort, orders per cohort
- **Data Grain**: Cohort × Period
- **Time Windows**: Cohort month, Months since acquisition
- **Key Entities**: Customer, First purchase date, Orders

### Q5: Who is likely still active vs "dead"?
- **Metrics**: Last purchase date, purchase count, inter-purchase time, BTYD inputs
- **Data Grain**: Customer level
- **Time Windows**: Calibration vs holdout
- **Key Entities**: Customer, Orders

### Q6: What actions should we take (prescriptive)?
- **Metrics**: Predicted CLV, discount cost, incremental lift assumptions
- **Data Grain**: Customer × Action scenario
- **Time Windows**: Forward-looking (12–36 months)
- **Key Entities**: Customer, Orders, Promotions

### Q7: What is the value of our overall customer base? (CBCV)
- **Metrics**: Aggregated CLV projections, retention metrics, cohort performance
- **Data Grain**: Customer-level aggregated to portfolio
- **Time Windows**: Future projections (1–5 years)
- **Key Entities**: Customers, Transactions, Cohorts, Spend metrics

---

## 🚀 4-Phase Discovery Process

### **PHASE 1: High-Level Discovery (10 minutes)**
**Objective**: Understand the database structure and identify candidate tables for customer analytics.

#### Step 1: Run Query #1 - Schema Overview
**Purpose**: See how tables are organized across schemas.

```
-- Query #1: Schema Overview (phase_2_task_1_metadata_explorqtion.sql)
```

**Actual Results**:

| SchemaName | TableCount |
|------------|------------|
| Production | 25 |
| Sales | 19 |
| Person | 13 |
| HumanResources | 6 |
| Purchasing | 5 |
| dbo | 4 |

**Interpretation**: Focus on **Sales**, **Person**, and **Production** schemas for customer analytics.

---

#### Step 2: Run Query #3 - Customer Analytics-Focused Table Finder
**Purpose**: Auto-identify tables relevant to customer analytics using pattern matching.

```
-- Query #3: Customer Analytics-Focused Table Finder (phase_2_task_1_metadata_explorqtion.sql)
```

**Actual Results**:

| SchemaName | TableName | TotalRows | TotalSizeMB | AnalyticsCategory | CategoryPriority |
|------------|-----------|-----------|-------------|-------------------|------------------|
| Sales | Customer | 19,820 | 1.07 | Customer | 1 |
| Sales | SalesOrderDetail | 121,317 | 10.10 | Transaction | 2 |
| Production | WorkOrder | 72,591 | 4.35 | Transaction | 2 |
| Production | WorkOrderRouting | 67,131 | 5.79 | Transaction | 2 |
| Sales | SalesOrderHeader | 31,465 | 5.73 | Transaction | 2 |
| Sales | SalesOrderHeaderSalesReason | 27,647 | 0.76 | Transaction | 2 |
| Purchasing | PurchaseOrderDetail | 8,845 | 0.57 | Transaction | 2 |
| Purchasing | PurchaseOrderHeader | 4,012 | 0.45 | Transaction | 2 |
| Sales | SalesPersonQuotaHistory | 163 | 0.20 | Person | 2 |
| Sales | SalesTaxRate | 29 | 0.07 | Transaction | 2 |
| Sales | SalesPerson | 17 | 0.07 | Person | 2 |
| Sales | SalesTerritoryHistory | 17 | 0.07 | Transaction | 2 |
| Sales | SalesTerritory | 10 | 0.07 | Transaction | 2 |
| Sales | SalesReason | 10 | 0.07 | Transaction | 2 |
| Person | Person | 59,916 | 30.55 | Person | 3 |
| Person | PersonPhone | 19,972 | 1.26 | Person | 3 |
| Sales | PersonCreditCard | 19,118 | 0.57 | Person | 3 |
| Production | ProductInventory | 1,069 | 0.20 | Product | 4 |
| Production | ProductDescription | 762 | 0.26 | Product | 4 |
| Production | ProductModelProductDescriptionCulture | 762 | 0.20 | Product | 4 |
| Sales | SpecialOfferProduct | 538 | 0.20 | Product | 4 |
| Production | ProductProductPhoto | 504 | 0.07 | Product | 4 |
| Production | Product | 504 | 0.26 | Product | 4 |
| Purchasing | ProductVendor | 460 | 0.20 | Product | 4 |
| Production | ProductCostHistory | 395 | 0.20 | Product | 4 |
| Production | ProductListPriceHistory | 395 | 0.20 | Product | 4 |
| Production | ProductModel | 384 | 0.33 | Product | 4 |
| Production | ProductPhoto | 303 | 2.52 | Product | 4 |
| Production | ProductSubcategory | 37 | 0.07 | Product | 4 |
| Production | ProductDocument | 32 | 0.07 | Product | 4 |
| Production | ProductModelIllustration | 7 | 0.07 | Product | 4 |
| Production | ProductCategory | 4 | 0.07 | Product | 4 |
| Production | ProductReview | 4 | 0.20 | Product | 4 |
| Person | Address | 58,842 | 2.99 | Location | 5 |
| Person | EmailAddress | 19,972 | 2.07 | Location | 5 |
| Person | BusinessEntityAddress | 19,614 | 0.95 | Location | 5 |
| Person | AddressType | 6 | 0.07 | Location | 5 |

**Key Takeaway**: These are your **candidate tables**. Next, you'll validate their relationships and roles.

---

#### Step 3: Run Query #7 - One Query to Rule Them All
**Purpose**: Get a comprehensive dashboard view combining size, relationships, date columns, and table roles.

```
-- Query #7: Comprehensive Table Discovery (phase_2_task_1_metadata_explorqtion.sql)
-- This query uses CTEs to combine:
-- - Table sizes
-- - Foreign key relationships (incoming/outgoing)
-- - Date/time columns
-- - Table descriptions
```

**Actual Results** (showing first 20 rows as sample - full results contain 72 tables):

| SchemaName | TableName | TotalRows | TotalSizeMB | OutgoingFKs | IncomingFKs | TableRole | DateColumnCount | DateColumnList | AnalyticsCategory | TableDescription |
|------------|-----------|-----------|-------------|-------------|-------------|-----------|-----------------|----------------|-------------------|------------------|
| Sales | Customer | 19,820 | 1.07 | 3 | 1 | Spoke (Fact) | 1 | ModifiedDate | Customer | Current customer information. Also see the Person and Store tables. |
| Sales | SalesOrderDetail | 121,317 | 10.10 | 2 | 0 | Spoke (Fact) | 1 | ModifiedDate | Transaction | Individual products associated with a specific sales order. See SalesOrderHeader. |
| Production | WorkOrder | 72,591 | 4.35 | 2 | 1 | Spoke (Fact) | 4 | StartDate, EndDate, DueDate, ModifiedDate | Transaction | NULL |
| Production | WorkOrderRouting | 67,131 | 5.79 | 2 | 0 | Spoke (Fact) | 5 | ScheduledStartDate, ScheduledEndDate, ActualStartDate, ActualEndDate, ModifiedDate | Transaction | NULL |
| Sales | SalesOrderHeader | 31,465 | 5.73 | 8 | 2 | Spoke (Fact) | 4 | OrderDate, DueDate, ShipDate, ModifiedDate | Transaction | General sales order information. |
| Sales | SalesOrderHeaderSalesReason | 27,647 | 0.76 | 2 | 0 | Spoke (Fact) | 1 | ModifiedDate | Transaction | Cross-reference table mapping sales orders to sales reason codes. |
| Purchasing | PurchaseOrderDetail | 8,845 | 0.57 | 2 | 0 | Spoke (Fact) | 2 | DueDate, ModifiedDate | Transaction | Individual products associated with a specific purchase order. See PurchaseOrderHeader. |
| Purchasing | PurchaseOrderHeader | 4,012 | 0.45 | 3 | 1 | Spoke (Fact) | 3 | OrderDate, ShipDate, ModifiedDate | Transaction | General purchase order information. See PurchaseOrderDetail. |
| Sales | SalesPersonQuotaHistory | 163 | 0.20 | 1 | 0 | Bridge/Lookup | 2 | QuotaDate, ModifiedDate | Person | Sales performance tracking. |
| Sales | SalesTaxRate | 29 | 0.07 | 1 | 0 | Bridge/Lookup | 1 | ModifiedDate | Transaction | Tax rate lookup table. |
| Sales | SalesTerritoryHistory | 17 | 0.07 | 2 | 0 | Spoke (Fact) | 3 | StartDate, EndDate, ModifiedDate | Transaction | Sales representative transfers to other sales territories. |
| Sales | SalesPerson | 17 | 0.07 | 2 | 4 | Hub (Dimension) | 1 | ModifiedDate | Person | Sales representative current information. |
| Sales | SalesTerritory | 10 | 0.07 | 1 | 5 | Hub (Dimension) | 1 | ModifiedDate | Transaction | Sales territory lookup table. |
| Sales | SalesReason | 10 | 0.07 | 0 | 1 | Bridge/Lookup | 1 | ModifiedDate | Transaction | Lookup table of customer purchase reasons. |
| Person | Person | 59,916 | 30.55 | 1 | 7 | Hub (Dimension) | 1 | ModifiedDate | Person | Human beings involved with AdventureWorks: employees, customer contacts, and vendor contacts. |
| Person | PersonPhone | 19,972 | 1.26 | 2 | 0 | Spoke (Fact) | 1 | ModifiedDate | Person | Telephone number and type of a person. |
| Sales | PersonCreditCard | 19,118 | 0.57 | 2 | 0 | Spoke (Fact) | 1 | ModifiedDate | Person | Cross-reference table mapping people to their credit card information in the CreditCard table. |
| Production | ProductInventory | 1,069 | 0.20 | 2 | 0 | Spoke (Fact) | 1 | ModifiedDate | Product | Product inventory information. |
| Production | ProductDescription | 762 | 0.26 | 0 | 1 | Bridge/Lookup | 1 | ModifiedDate | Product | Product descriptions in several languages. |
| Production | ProductModelProductDescriptionCulture | 762 | 0.20 | 3 | 0 | Spoke (Fact) | 1 | ModifiedDate | Product | Cross-reference table mapping product descriptions and the language the description is written in. |

*(Full result set includes 72 tables - truncated for brevity)*

**Interpretation**:
- **Hub (Dimension)**: Tables with many **incoming** FKs → referenced by other tables (e.g., Customer, Person)
- **Spoke (Fact)**: Tables with many **outgoing** FKs → reference dimension tables (e.g., SalesOrderHeader, SalesOrderDetail)
- **Bridge/Lookup**: Connector tables or small reference tables

---

### **PHASE 2: Relationship Discovery (10 minutes)**
**Objective**: Understand how tables connect and identify dimension vs fact tables.

#### Step 4: Run Query #4 - Hub and Spoke Analysis
**Purpose**: Classify tables by their role in the data model.

```
-- Query #4: Table Relationship Summary with Hub and Spoke Analysis (phase_2_task_1_metadata_explorqtion.sql)
```

**Actual Results** (showing top 20 by total relationships):

| SchemaName | TableName | OutgoingFKs | IncomingFKs | TableRole | TotalRelationships |
|------------|-----------|-------------|-------------|-----------|-------------------|
| Production | Product | 4 | 14 | Hub (Dimension) | 18 |
| Sales | SalesOrderHeader | 8 | 2 | Spoke (Fact) | 10 |
| Person | Person | 1 | 7 | Hub (Dimension) | 8 |
| HumanResources | Employee | 1 | 6 | Hub (Dimension) | 7 |
| Sales | SalesTerritory | 1 | 5 | Hub (Dimension) | 6 |
| Sales | SalesPerson | 2 | 4 | Hub (Dimension) | 6 |
| Person | BusinessEntity | 0 | 5 | Hub (Dimension) | 5 |
| Production | UnitMeasure | 0 | 4 | Hub (Dimension) | 4 |
| Person | Address | 1 | 3 | Hub (Dimension) | 4 |
| Person | StateProvince | 2 | 2 | Bridge/Lookup | 4 |
| Purchasing | PurchaseOrderHeader | 3 | 1 | Spoke (Fact) | 4 |
| Sales | Customer | 3 | 1 | Spoke (Fact) | 4 |
| Sales | Currency | 0 | 3 | Hub (Dimension) | 3 |
| Person | CountryRegion | 0 | 3 | Hub (Dimension) | 3 |
| Production | ProductModel | 0 | 3 | Hub (Dimension) | 3 |
| Purchasing | Vendor | 1 | 2 | Hub (Dimension) | 3 |
| Production | WorkOrder | 2 | 1 | Spoke (Fact) | 3 |
| Sales | Store | 2 | 1 | Spoke (Fact) | 3 |
| Sales | SpecialOfferProduct | 2 | 1 | Spoke (Fact) | 3 |
| Sales | CurrencyRate | 2 | 1 | Spoke (Fact) | 3 |

*(Full result set includes 60 tables with relationships - truncated for brevity)*

**Key Insight**: Start your ERD with **Hub tables** (dimensions like Customer, Person) and connect them to **Spoke tables** (facts like SalesOrderHeader).

---

#### Step 5: Run Query #5 - Foreign Key Relationship Map
**Purpose**: See parent → child relationships to understand data flow.

```
-- Query #5: Simplified Foreign Key Relationship Map (phase_2_task_1_metadata_explorqtion.sql)
```

**Actual Results** (showing top 20 by FK density):

| ReferencedSchema | ReferencedTable | ParentSchema | ParentTable | ForeignKeyName | FKDensityAsReferenced | FKDensityAsParent |
|------------------|-----------------|--------------|-------------|----------------|---------------------|------------------|
| Production | Product | Production | BillOfMaterials | FK_BillOfMaterials_Product_ProductAssemblyID | 14 | 3 |
| Production | Product | Production | BillOfMaterials | FK_BillOfMaterials_Product_ComponentID | 14 | 3 |
| Production | Product | Production | ProductCostHistory | FK_ProductCostHistory_Product_ProductID | 14 | 1 |
| Production | Product | Production | ProductDocument | FK_ProductDocument_Product_ProductID | 14 | 2 |
| Production | Product | Production | ProductInventory | FK_ProductInventory_Product_ProductID | 14 | 2 |
| Production | Product | Production | ProductListPriceHistory | FK_ProductListPriceHistory_Product_ProductID | 14 | 1 |
| Production | Product | Production | ProductProductPhoto | FK_ProductProductPhoto_Product_ProductID | 14 | 2 |
| Production | Product | Production | ProductReview | FK_ProductReview_Product_ProductID | 14 | 1 |
| Production | Product | Purchasing | ProductVendor | FK_ProductVendor_Product_ProductID | 14 | 3 |
| Production | Product | Purchasing | PurchaseOrderDetail | FK_PurchaseOrderDetail_Product_ProductID | 14 | 2 |
| Production | Product | Sales | ShoppingCartItem | FK_ShoppingCartItem_Product_ProductID | 14 | 1 |
| Production | Product | Sales | SpecialOfferProduct | FK_SpecialOfferProduct_Product_ProductID | 14 | 2 |
| Production | Product | Production | TransactionHistory | FK_TransactionHistory_Product_ProductID | 14 | 1 |
| Production | Product | Production | WorkOrder | FK_WorkOrder_Product_ProductID | 14 | 2 |
| Person | Person | Person | BusinessEntityContact | FK_BusinessEntityContact_Person_PersonID | 7 | 3 |
| Person | Person | Sales | Customer | FK_Customer_Person_PersonID | 7 | 3 |
| Person | Person | Person | EmailAddress | FK_EmailAddress_Person_BusinessEntityID | 7 | 1 |
| Person | Person | HumanResources | Employee | FK_Employee_Person_BusinessEntityID | 7 | 1 |
| Person | Person | Person | Password | FK_Password_Person_BusinessEntityID | 7 | 1 |
| Person | Person | Sales | PersonCreditCard | FK_PersonCreditCard_Person_BusinessEntityID | 7 | 2 |

*(Full result set includes 94 foreign key relationships - truncated for brevity)*

**Key Insight**: This tells you:
- `SalesOrderHeader` references `Customer` → Many orders per customer
- `Customer` references `Person` → One-to-one or optional relationship
- `SalesOrderDetail` references `Product` → Many line items per product

---

#### Step 6: Run Query #6 - Date/Time Columns Finder
**Purpose**: Identify temporal columns for RFM, cohorts, and retention analysis.

```
-- Query #6: Date/Time Columns Finder (phase_2_task_1_metadata_explorqtion.sql)
```

**Actual Results** (showing top 30 by row count):

| SchemaName | TableName | ColumnName | DataType | TableRowCount | DateCategory |
|------------|-----------|------------|----------|---------------|--------------|
| Sales | SalesOrderDetail | ModifiedDate | datetime | 121,317 | Modified Date |
| Production | TransactionHistory | ModifiedDate | datetime | 113,443 | Modified Date |
| Production | TransactionHistory | TransactionDate | datetime | 113,443 | Other Date |
| Production | TransactionHistoryArchive | ModifiedDate | datetime | 89,253 | Modified Date |
| Production | TransactionHistoryArchive | TransactionDate | datetime | 89,253 | Other Date |
| Production | WorkOrder | DueDate | datetime | 72,591 | End/Due Date |
| Production | WorkOrder | EndDate | datetime | 72,591 | End/Due Date |
| Production | WorkOrder | ModifiedDate | datetime | 72,591 | Modified Date |
| Production | WorkOrder | StartDate | datetime | 72,591 | Created Date |
| Production | WorkOrderRouting | ActualEndDate | datetime | 67,131 | End/Due Date |
| Production | WorkOrderRouting | ActualStartDate | datetime | 67,131 | Created Date |
| Production | WorkOrderRouting | ModifiedDate | datetime | 67,131 | Modified Date |
| Production | WorkOrderRouting | ScheduledEndDate | datetime | 67,131 | End/Due Date |
| Production | WorkOrderRouting | ScheduledStartDate | datetime | 67,131 | Created Date |
| Sales | SalesOrderHeader | DueDate | datetime | 31,465 | End/Due Date |
| Sales | SalesOrderHeader | ModifiedDate | datetime | 31,465 | Modified Date |
| Sales | SalesOrderHeader | OrderDate | datetime | 31,465 | Transaction Date |
| Sales | SalesOrderHeader | ShipDate | datetime | 31,465 | Ship Date |
| Sales | SalesOrderHeaderSalesReason | ModifiedDate | datetime | 27,647 | Modified Date |
| Person | BusinessEntity | ModifiedDate | datetime | 20,777 | Modified Date |
| Person | EmailAddress | ModifiedDate | datetime | 19,972 | Modified Date |
| Person | Password | ModifiedDate | datetime | 19,972 | Modified Date |
| Person | Person | ModifiedDate | datetime | 19,972 | Modified Date |
| Person | PersonPhone | ModifiedDate | datetime | 19,972 | Modified Date |
| Sales | Customer | ModifiedDate | datetime | 19,820 | Modified Date |
| Person | Address | ModifiedDate | datetime | 19,614 | Modified Date |
| Person | BusinessEntityAddress | ModifiedDate | datetime | 19,614 | Modified Date |
| Sales | CreditCard | ModifiedDate | datetime | 19,118 | Modified Date |
| Sales | PersonCreditCard | ModifiedDate | datetime | 19,118 | Modified Date |
| Sales | CurrencyRate | CurrencyRateDate | datetime | 13,532 | Other Date |

*(Full result set includes 128 date/time columns - truncated for brevity)*

**Critical Finding**: `SalesOrderHeader.OrderDate` is the **primary temporal anchor** for:
- **Recency** (time since last order)
- **Cohorts** (first order month)
- **Trends** (order patterns over time)

---

### **PHASE 3: Table Shortlisting (5 minutes)**
**Objective**: Narrow down to 10-15 most relevant tables based on discovery results.

#### Step 7: Review Query #3 and Query #7 Results Side by Side
Create a **shortlist scorecard** using these criteria:

| Criterion | Weight | How to Evaluate |
|-----------|--------|-----------------|
| **Analytics Category Match** | High | Must be Customer, Transaction, or Product category |
| **Table Role** | High | Prefer Hubs (dimensions) and Spokes (facts) |
| **Row Count** | Medium | Larger tables = more analytical value |
| **Date Column Presence** | High | Required for temporal analysis (RFM, cohorts) |
| **Relationship Density** | Medium | Tables with 2+ relationships are well-connected |

#### Step 8: Apply Scorecard to Candidate Tables

**Example Evaluation**:

| Table | Category | Role | Rows | Date Cols | Relationships | Include? |
|-------|----------|------|------|-----------|---------------|----------|
| Sales.Customer | Customer | Hub | 19,820 | 1 | 3 | ✅ YES |
| Sales.SalesOrderHeader | Transaction | Spoke | 31,465 | 4 | 8 | ✅ YES |
| Sales.SalesOrderDetail | Transaction | Spoke | 121,317 | 1 | 3 | ✅ YES |
| Person.Person | Person | Hub | 19,972 | 1 | 3 | ✅ YES |
| Production.Product | Product | Bridge | 504 | 4 | 4 | ✅ YES |
| Person.Address | Location | Hub | 19,614 | 1 | 2 | ✅ YES |
| Sales.SpecialOffer | Other | Standalone | 16 | 2 | 1 | ⚠️ MAYBE |
| HumanResources.Employee | Other | Hub | 290 | 2 | 4 | ❌ NO (out of scope) |

**Final Shortlist** (17 tables selected):

**Dimensions / Hub Tables** (9):
1. Sales.Customer
2. Person.Person
3. Person.EmailAddress
4. Person.Address
5. Person.StateProvince
6. Sales.SalesTerritory
7. Production.Product
8. Production.ProductSubcategory
9. Production.ProductCategory

**Facts / Transaction Tables** (2):
10. Sales.SalesOrderHeader
11. Sales.SalesOrderDetail

**Bridge / Lookup Tables** (6):
12. Person.BusinessEntityAddress
13. Person.AddressType
14. Sales.SpecialOffer
15. Sales.SpecialOfferProduct
16. Sales.SalesOrderHeaderSalesReason
17. Sales.SalesReason

---

### **PHASE 4: Detailed Analysis (As Needed)**
**Objective**: Deep dive into shortlisted tables to define the ERD schema.

#### Step 9: Run Phase 4 Queries with Filters
For each shortlisted table, run:

**Query #8 - Primary Keys** (phase_2_task_1_metadata_explorqtion.sql):
```sql
-- Find primary keys for ERD unique identifiers
WHERE SCHEMA_NAME(t.schema_id) = 'Sales' AND t.name = 'Customer';
```

**Query #9 - Foreign Key Relationships** (phase_2_task_1_metadata_explorqtion.sql):
```sql
-- Get FK details for ERD relationship lines
WHERE SCHEMA_NAME(p.schema_id) = 'Sales' OR p.name LIKE '%Customer%';
```

**Query #10 - Column Details** (phase_2_task_1_metadata_explorqtion.sql):
```sql
-- List all columns for ERD table definitions
WHERE SCHEMA_NAME(t.schema_id) = 'Sales' AND t.name = 'SalesOrderHeader';
```

#### Step 10: Document Findings in ERD Format
Use the DBML format to define each table:

```dbml
Table Sales_Customer {
  CustomerID int [pk, not null]
  PersonID int
  TerritoryID int
  AccountNumber varchar(10) [not null]
  ModifiedDate datetime [not null]

  Note: 'Customer master. One row per customer. Links to Person and SalesTerritory; drives customer-level RFM/CLV.'
}
```

---

## 📊 Final ERD Structure

The final ERD (`phase_2_task_4_customer_analytics_erd.dbml`) contains **17 tables** organized as:

### **Dimensions / Hub Tables** (Customer Identity & Context)
- **Sales.Customer**: Customer master table (CustomerID, PersonID, TerritoryID)
- **Person.Person**: Demographics (FirstName, LastName, EmailPromotion, Demographics XML)
- **Person.EmailAddress**: Contact information for campaigns
- **Person.Address**: Geographic data (City, PostalCode, StateProvinceID)
- **Person.StateProvince**: State/province/region lookup
- **Sales.SalesTerritory**: Territory/region dimension (for regional CLV)
- **Production.Product**: Product catalog (ProductID, Name, ListPrice, StandardCost)
- **Production.ProductSubcategory**: Product subcategory hierarchy
- **Production.ProductCategory**: Top-level product categories

### **Fact / Transaction Tables** (Behavioral Data)
- **Sales.SalesOrderHeader**: Order-level facts (OrderDate, CustomerID, TotalDue, SubTotal)
- **Sales.SalesOrderDetail**: Line-item facts (ProductID, OrderQty, UnitPrice, LineTotal)

### **Bridge / Lookup Tables** (Relationships & Context)
- **Person.BusinessEntityAddress**: Links Person/Store to Address (many-to-many)
- **Person.AddressType**: Address type lookup (Billing, Shipping, Home)
- **Sales.SpecialOffer**: Promotion/discount metadata
- **Sales.SpecialOfferProduct**: Links offers to products (required bridge)
- **Sales.SalesOrderHeaderSalesReason**: Links orders to purchase reasons
- **Sales.SalesReason**: Purchase motivation lookup

---

## 🔗 How the ERD Answers the 7 Questions

### **Q1: Most Valuable Customers**
**Tables Used**:
- `Sales.Customer` (CustomerID)
- `Sales.SalesOrderHeader` (OrderDate, TotalDue, CustomerID)
- `Sales.SalesOrderDetail` (LineTotal, OrderQty)

**Query Pattern**:
```sql
SELECT 
    c.CustomerID,
    COUNT(DISTINCT soh.SalesOrderID) AS OrderCount,
    SUM(soh.TotalDue) AS TotalRevenue,
    AVG(soh.TotalDue) AS AvgOrderValue
FROM Sales.Customer c
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
WHERE soh.OrderDate >= DATEADD(MONTH, -12, GETDATE())
GROUP BY c.CustomerID
ORDER BY TotalRevenue DESC;
```

---

### **Q2: Unprofitable or Risky Customers**
**Tables Used**:
- `Sales.Customer`
- `Sales.SalesOrderHeader` (OrderDate for recency)
- `Sales.SalesOrderDetail` (UnitPriceDiscount for discount proxy)

**Key Metrics**:
- **Recency**: `DATEDIFF(DAY, MAX(OrderDate), GETDATE())`
- **Frequency**: `COUNT(DISTINCT SalesOrderID)`
- **Discount Rate**: `SUM(UnitPriceDiscount) / SUM(UnitPrice)`

---

### **Q3: Customer Behavior Heterogeneity (RFM)**
**Tables Used**:
- `Sales.Customer`
- `Sales.SalesOrderHeader` (OrderDate, TotalDue)
- `Production.Product` (for category diversity via SalesOrderDetail)

**RFM Calculation**:
- **Recency**: Days since last order
- **Frequency**: Total order count
- **Monetary**: Total spend (SUM of TotalDue)

---

### **Q4: Cohort Analysis**
**Tables Used**:
- `Sales.Customer`
- `Sales.SalesOrderHeader` (OrderDate for cohort assignment)

**Query Pattern**:
```sql
WITH FirstPurchase AS (
    SELECT CustomerID, MIN(OrderDate) AS FirstOrderDate
    FROM Sales.SalesOrderHeader
    GROUP BY CustomerID
)
SELECT 
    YEAR(FirstOrderDate) AS CohortYear,
    MONTH(FirstOrderDate) AS CohortMonth,
    COUNT(DISTINCT CustomerID) AS CohortSize
FROM FirstPurchase
GROUP BY YEAR(FirstOrderDate), MONTH(FirstOrderDate);
```

---

### **Q5: Active vs "Dead" Customers**
**Tables Used**:
- `Sales.Customer`
- `Sales.SalesOrderHeader` (OrderDate)

**Key Metrics**:
- Last purchase date
- Inter-purchase time (average days between orders)
- Expected next purchase (BTYD model inputs)

---

### **Q6: Prescriptive Actions**
**Tables Used**:
- `Sales.Customer`
- `Sales.SalesOrderHeader`
- `Sales.SpecialOffer` (promotion history)
- `Sales.SpecialOfferProduct` (bridge to link offers to products)

**Use Case**: Simulate discount campaigns for high-CLV customers based on historical promotion response.

---

### **Q7: Customer Base Current Value (CBCV)**
**Tables Used**:
- All tables from Q1-Q5 (aggregated)

**Approach**: Aggregate individual CLV predictions to portfolio level, segment by cohort, and project future retention curves.

---

## 🛠️ Tools & Resources

**SQL Script**: [`phase_2_task_1_metadata_explorqtion.sql`](../sql/phase_2_task_1_metadata_explorqtion.sql)
- 11 queries organized into 4 phases
- Fully commented with usage instructions
- Execution guide at the bottom 

**ERD File**: [`phase_2_task_4_customer_analytics_erd.dbml`](../sql/phase_2_task_4_customer_analytics_erd.dbml)
- DBML format (visualize at [dbdiagram.io](https://dbdiagram.io))
- 17 tables with full column definitions
- Relationship cardinalities documented

**Database**: AdventureWorks 2025 (SQL Server)

---

## 📝 Summary: Methodology at a Glance

| Phase | Time | Queries | Output |
|-------|------|---------|--------|
| **1. High-Level Discovery** | 10 min | #1, #3, #7 | Candidate tables + analytics categories |
| **2. Relationship Discovery** | 10 min | #4, #5, #6 | Table roles (Hub/Spoke) + FK map + temporal columns |
| **3. Table Shortlisting** | 5 min | Manual review | 17 final tables |
| **4. Detailed Analysis** | As needed | #8, #9, #10 | Column details + PK/FK definitions for ERD | #11 | Tables Dictionary |

**Total Time to Shortlist**: ~25 minutes

**Final Deliverable**: Enhanced ERD with 17 tables optimized for customer analytics (Q1-Q7)
