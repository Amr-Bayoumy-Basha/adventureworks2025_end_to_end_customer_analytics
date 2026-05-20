/*
================================================================================
METADATA EXPLORATION FRAMEWORK - Customer Analytics Intelligence Layer
================================================================================

PURPOSE:
Systematic metadata discovery framework for analytical model design.
Transforms raw system catalogs into business-ready analytical documentation.

KEY INSIGHT:
Define business questions BEFORE selecting tables. This is analytical modeling,
not database exploration.

WORKFLOW - 4 PHASES:
1. Discovery (Q1-Q3): Landscape mapping & entity classification
2. Topology (Q4-Q6): Relationship patterns & temporal anchors  
3. Integration (Q7): Unified metadata dashboard
4. Documentation (Q8-Q11): Structural finalization & dictionary generation

TARGET: SQL Server (AdventureWorks 2025) | AUTHOR: Azab Basha | DATE: May 2026
*/

--------------------------------------------------------------------------------
-- PHASE 1: DISCOVERY - "What exists and what matters?"
-- Strategic Goal: Classify entities by analytical value, not just size
--------------------------------------------------------------------------------

/*
Q1: Schema Overview
Technical: Catalog-level query using sys.schemas join
Strategic: Identify schema-level business domains (Sales vs Person vs Production)
Use Case: Focus ERD efforts on high-density schemas
*/
SELECT
    s.name AS SchemaName,
    COUNT(t.object_id) AS TableCount
FROM sys.schemas AS s
LEFT JOIN sys.tables AS t ON t.schema_id = s.schema_id
GROUP BY s.name
HAVING COUNT(t.object_id) > 0
ORDER BY TableCount DESC;

/*
Q2: Complete Table Inventory with Storage Metrics
Technical: sys.partitions + sys.allocation_units for storage calculation
Strategic: Prioritize tables by volume (fact candidates) vs low-volume (dimension candidates)
Key Insight: Large tables often represent transactional grains (OrderDetail, not Order)
*/
SELECT
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    t.name AS TableName,
    SUM(p.rows) AS TotalRows,
    CAST(ROUND(SUM(a.total_pages) * 8.0 / 1024, 2) AS DECIMAL(18,2)) AS TotalSizeMB
FROM sys.tables AS t
JOIN sys.partitions AS p ON t.object_id = p.object_id
JOIN sys.allocation_units AS a ON p.partition_id = a.container_id
WHERE p.index_id IN (0,1)  -- Heap (0) or Clustered Index (1) only
GROUP BY t.schema_id, t.name
ORDER BY TotalRows DESC, TotalSizeMB DESC;

/*
Q3: Customer Analytics Table Classifier
Technical: Heuristic semantic tagging using LIKE patterns
Strategic: Auto-identify Customer/Transaction/Product tables for RFM/CLV/Cohort analysis
Why This Matters: Replaces manual table browsing with pattern-based discovery
Future: Basis for metadata cataloging systems (Collibra/Alation concept)
*/
SELECT
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    t.name AS TableName,
    SUM(p.rows) AS TotalRows,
    CASE 
        WHEN t.name LIKE '%Customer%' THEN 'Customer'
        WHEN t.name LIKE '%Person%' THEN 'Person'
        WHEN t.name LIKE '%Order%' OR t.name LIKE '%Sales%' THEN 'Transaction'
        WHEN t.name LIKE '%Product%' THEN 'Product'
        WHEN t.name LIKE '%Address%' THEN 'Location'
        ELSE 'Other'
    END AS AnalyticsCategory,
    CASE 
        WHEN t.name LIKE '%Customer%' THEN 1
        WHEN t.name LIKE '%Order%' OR t.name LIKE '%Sales%' THEN 2
        ELSE 99
    END AS Priority
FROM sys.tables AS t
JOIN sys.partitions AS p ON t.object_id = p.object_id
JOIN sys.allocation_units AS a ON p.partition_id = a.container_id
WHERE p.index_id IN (0,1)
    AND (t.name LIKE '%Customer%' OR t.name LIKE '%Person%' OR t.name LIKE '%Order%'
         OR t.name LIKE '%Sales%' OR t.name LIKE '%Product%' OR t.name LIKE '%Address%')
GROUP BY t.schema_id, t.name
ORDER BY Priority, TotalRows DESC;

--------------------------------------------------------------------------------
-- PHASE 2: TOPOLOGY - "How do entities connect?"
-- Strategic Goal: Detect dimensional model patterns (hub/spoke/bridge)
--------------------------------------------------------------------------------

/*
Q4: Hub & Spoke Analysis (Dimensional Model Detection)
Technical: CTE with bidirectional FK counting
Strategic: Distinguish dimensions (many incoming FKs) from facts (many outgoing FKs)
Key Insight:
  - Hub (Dimension): High incoming FKs → Customer, Product, Territory
  - Spoke (Fact): High outgoing FKs → SalesOrderHeader, SalesOrderDetail
  - Bridge: Equal FKs → Many-to-many resolvers (SpecialOfferProduct)
Why Critical: Informs star schema design before building warehouse
*/
WITH TableRelationships AS (
    SELECT
        SCHEMA_NAME(t.schema_id) AS SchemaName,
        t.name AS TableName,
        COUNT(DISTINCT fk_out.object_id) AS OutgoingFKs,
        COUNT(DISTINCT fk_in.object_id) AS IncomingFKs
    FROM sys.tables AS t
    LEFT JOIN sys.foreign_keys AS fk_out ON t.object_id = fk_out.parent_object_id
    LEFT JOIN sys.foreign_keys AS fk_in ON t.object_id = fk_in.referenced_object_id
    GROUP BY t.schema_id, t.name
)
SELECT
    SchemaName, TableName, OutgoingFKs, IncomingFKs,
    CASE 
        WHEN IncomingFKs > OutgoingFKs AND IncomingFKs >= 2 THEN 'Hub (Dimension)'
        WHEN OutgoingFKs > IncomingFKs AND OutgoingFKs >= 2 THEN 'Spoke (Fact)'
        WHEN IncomingFKs = 0 AND OutgoingFKs = 0 THEN 'Standalone'
        ELSE 'Bridge/Lookup'
    END AS TableRole,
    (IncomingFKs + OutgoingFKs) AS TotalRelationships
FROM TableRelationships
WHERE (IncomingFKs + OutgoingFKs) > 0
ORDER BY TotalRelationships DESC, IncomingFKs DESC;

/*
Q5: Foreign Key Relationship Map with Density Metrics
Technical: Window functions for FK density calculation
Strategic: Identify heavily connected tables for ERD focus
Use Case: Build mental model of database topology before detailed analysis
*/
SELECT
    SCHEMA_NAME(r.schema_id) AS ReferencedSchema, r.name AS ReferencedTable,
    SCHEMA_NAME(p.schema_id) AS ParentSchema, p.name AS ParentTable,
    fk.name AS ForeignKeyName,
    COUNT(*) OVER (PARTITION BY r.object_id) AS FKDensityAsReferenced,
    COUNT(*) OVER (PARTITION BY p.object_id) AS FKDensityAsParent
FROM sys.foreign_keys AS fk
INNER JOIN sys.tables AS p ON p.object_id = fk.parent_object_id
INNER JOIN sys.tables AS r ON r.object_id = fk.referenced_object_id
ORDER BY FKDensityAsReferenced DESC, ReferencedTable;

/*
Q6: Temporal Column Discovery (Critical for Time-Based Analytics)
Technical: Filter sys.types for datetime family types
Strategic: Identify temporal anchors for RFM (Recency), cohort, retention analysis
Key Insight: OrderDate = primary temporal grain for customer behavior analysis
Why Important: Without date columns, no time-series analytics possible
*/
SELECT
    SCHEMA_NAME(t.schema_id) AS SchemaName, t.name AS TableName,
    c.name AS ColumnName, ty.name AS DataType, SUM(p.rows) AS TableRowCount,
    CASE 
        WHEN c.name LIKE '%Order%Date%' OR c.name LIKE '%Purchase%' THEN 'Transaction Date'
        WHEN c.name LIKE '%Birth%' THEN 'Birth Date'
        WHEN c.name LIKE '%Modified%' THEN 'Audit Date'
        WHEN c.name LIKE '%Ship%' THEN 'Fulfillment Date'
        ELSE 'Other Date'
    END AS DateCategory
FROM sys.tables AS t
JOIN sys.columns AS c ON t.object_id = c.object_id
JOIN sys.types AS ty ON c.user_type_id = ty.user_type_id
JOIN sys.partitions AS p ON t.object_id = p.object_id
WHERE ty.name IN ('date', 'datetime', 'datetime2', 'smalldatetime') AND p.index_id IN (0,1)
GROUP BY t.schema_id, t.name, c.name, ty.name
ORDER BY TableRowCount DESC, SchemaName, TableName;

--------------------------------------------------------------------------------
-- PHASE 3: INTEGRATION - "Complete metadata dashboard"
-- Strategic Goal: Single query for comprehensive table evaluation
--------------------------------------------------------------------------------

/*
Q7: Unified Metadata Dashboard (The "One Query to Rule Them All")
Technical: Multi-CTE architecture merging 4 metadata layers
Strategic: Replace 6 separate queries with one integrated view
Architecture:
  - TableSizes CTE: Storage metrics
  - TableRelationships CTE: FK topology
  - DateColumns CTE: Temporal capabilities
  - DescriptionInfo CTE: Business semantics
Why Powerful: Creates lightweight metadata mart for analytical decision-making
Use Case: Evaluate any table's analytical fitness in one result set
Portfolio Impact: Shows metadata engineering skills, not just querying
*/
WITH TableSizes AS (
    SELECT t.schema_id, t.object_id,
        SCHEMA_NAME(t.schema_id) AS SchemaName, t.name AS TableName,
        SUM(p.rows) AS TotalRows,
        CAST(ROUND(SUM(a.total_pages) * 8.0 / 1024, 2) AS DECIMAL(18,2)) AS TotalSizeMB
    FROM sys.tables AS t
    JOIN sys.partitions AS p ON t.object_id = p.object_id
    JOIN sys.allocation_units AS a ON p.partition_id = a.container_id
    WHERE p.index_id IN (0,1)
    GROUP BY t.schema_id, t.object_id, t.name
),
TableRelationships AS (
    SELECT t.object_id AS TableObjectId,
        COUNT(DISTINCT fk_out.object_id) AS OutgoingFKs,
        COUNT(DISTINCT fk_in.object_id) AS IncomingFKs
    FROM sys.tables AS t
    LEFT JOIN sys.foreign_keys AS fk_out ON t.object_id = fk_out.parent_object_id
    LEFT JOIN sys.foreign_keys AS fk_in ON t.object_id = fk_in.referenced_object_id
    GROUP BY t.object_id
),
DateColumns AS (
    SELECT t.object_id AS TableObjectId,
        COUNT(*) AS DateColumnCount,
        STRING_AGG(c.name, ', ') AS DateColumnList
    FROM sys.tables AS t
    JOIN sys.columns AS c ON t.object_id = c.object_id
    JOIN sys.types AS ty ON c.user_type_id = ty.user_type_id
    WHERE ty.name IN ('date', 'datetime', 'datetime2', 'smalldatetime')
    GROUP BY t.object_id
),
DescriptionInfo AS (
    SELECT t.object_id AS TableObjectId, ep.value AS TableDescription
    FROM sys.tables AS t
    LEFT JOIN sys.extended_properties AS ep 
        ON t.object_id = ep.major_id AND ep.minor_id = 0 AND ep.name = 'MS_Description'
)
SELECT
    ts.SchemaName, ts.TableName, ts.TotalRows, ts.TotalSizeMB,
    ISNULL(tr.OutgoingFKs, 0) AS OutgoingFKs,
    ISNULL(tr.IncomingFKs, 0) AS IncomingFKs,
    CASE 
        WHEN ISNULL(tr.IncomingFKs,0) > ISNULL(tr.OutgoingFKs,0) AND ISNULL(tr.IncomingFKs,0) >= 2 THEN 'Hub (Dimension)'
        WHEN ISNULL(tr.OutgoingFKs,0) > ISNULL(tr.IncomingFKs,0) AND ISNULL(tr.OutgoingFKs,0) >= 2 THEN 'Spoke (Fact)'
        WHEN ISNULL(tr.IncomingFKs,0) = 0 AND ISNULL(tr.OutgoingFKs,0) = 0 THEN 'Standalone'
        ELSE 'Bridge/Lookup'
    END AS TableRole,
    ISNULL(dc.DateColumnCount, 0) AS DateColumnCount,
    dc.DateColumnList,
    CASE 
        WHEN ts.TableName LIKE '%Customer%' THEN 'Customer'
        WHEN ts.TableName LIKE '%Order%' OR ts.TableName LIKE '%Sales%' THEN 'Transaction'
        WHEN ts.TableName LIKE '%Product%' THEN 'Product'
        ELSE 'Other'
    END AS AnalyticsCategory,
    di.TableDescription
FROM TableSizes AS ts
LEFT JOIN TableRelationships AS tr ON ts.object_id = tr.TableObjectId
LEFT JOIN DateColumns AS dc ON ts.object_id = dc.TableObjectId
LEFT JOIN DescriptionInfo AS di ON ts.object_id = di.TableObjectId
ORDER BY 
    CASE WHEN ts.TableName LIKE '%Customer%' THEN 1
         WHEN ts.TableName LIKE '%Order%' OR ts.TableName LIKE '%Sales%' THEN 2
         ELSE 99 END,
    ts.TotalRows DESC;

--------------------------------------------------------------------------------
-- PHASE 4: DOCUMENTATION - "Finalize structure for ERD/Data Dictionary"
-- Strategic Goal: Convert system metadata into business-ready documentation
--------------------------------------------------------------------------------

/*
Q8: Primary Key Identification
Technical: sys.key_constraints + sys.index_columns for PK structure
Strategic: Distinguish natural keys (BusinessEntityID) vs surrogate keys (OrderID)
Use Case: Define unique identifiers for ERD and prevent double-counting in DAX
*/
SELECT
    SCHEMA_NAME(t.schema_id) AS SchemaName, t.name AS TableName,
    kc.name AS PrimaryKeyName, c.name AS ColumnName, ic.key_ordinal AS KeyOrdinal
FROM sys.key_constraints AS kc
INNER JOIN sys.indexes AS i ON kc.parent_object_id = i.object_id AND kc.unique_index_id = i.index_id
INNER JOIN sys.index_columns AS ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.columns AS c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
INNER JOIN sys.tables AS t ON t.object_id = kc.parent_object_id
WHERE kc.type = 'PK'
ORDER BY SchemaName, TableName, PrimaryKeyName, ic.key_ordinal;

/*
Q9: Foreign Key Relationships (Referential Integrity Layer)
Technical: sys.foreign_keys + sys.foreign_key_columns for cardinality
Strategic: Define ERD relationships and understand cascading behaviors
Key Insight: ON DELETE/UPDATE actions reveal data integrity rules
Use Case: Build relationship lines in ERD with correct cardinality notation
*/
SELECT
    fk.name AS ForeignKeyName,
    SCHEMA_NAME(p.schema_id) AS ParentSchema, p.name AS ParentTable, pc.name AS ParentColumn,
    SCHEMA_NAME(r.schema_id) AS ReferencedSchema, r.name AS ReferencedTable, rc.name AS ReferencedColumn,
    fk.delete_referential_action_desc AS OnDelete,
    fk.update_referential_action_desc AS OnUpdate
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.tables AS p ON p.object_id = fkc.parent_object_id
INNER JOIN sys.columns AS pc ON pc.object_id = p.object_id AND pc.column_id = fkc.parent_column_id
INNER JOIN sys.tables AS r ON r.object_id = fkc.referenced_object_id
INNER JOIN sys.columns AS rc ON rc.object_id = r.object_id AND rc.column_id = fkc.referenced_column_id
ORDER BY ParentSchema, ParentTable, ForeignKeyName, fkc.constraint_column_id;

/*
Q10: Column Specification (Data Type Layer)
Technical: sys.columns + sys.types for complete column metadata
Strategic: Foundation for data profiling and Power BI field type mapping
Use Case: Validate data types before ETL transformations
*/
SELECT
    SCHEMA_NAME(t.schema_id) AS SchemaName, t.name AS TableName,
    c.name AS ColumnName, ty.name AS DataType,
    c.max_length AS MaxLength, c.precision AS Precision, c.scale AS Scale,
    c.is_nullable AS IsNullable, c.column_id AS ColumnOrder
FROM sys.tables AS t
JOIN sys.columns AS c ON t.object_id = c.object_id
JOIN sys.types AS ty ON c.user_type_id = ty.user_type_id
ORDER BY SchemaName, TableName, c.column_id;

/*
Q11: Data Dictionary Generator (Metadata-to-Documentation Pipeline)
Technical: Combines 4 system catalog layers into documentation format
Strategic: Auto-generate business-readable data dictionary for 17 analytics tables
Architecture:
  - PK detection: Column-level annotation (not table-level like Q8)
  - FK embedding: Inline relationship context per column
  - Extended properties: Business descriptions from sys.extended_properties
  - Scoped filtering: Only customer analytics subset (not entire database)

Why This Is Advanced:
This is NOT exploration. This is metadata engineering.
You are building a lightweight Data Catalog system (similar to Collibra/Alation).

Real-World Use Cases:
  - Auto-generate Markdown data dictionaries
  - Feed metadata to Power BI semantic models
  - Enable data lineage tracking
  - Support schema drift detection

Portfolio Impact:
Shows you understand that analytics requires documentation automation,
not just ad-hoc querying.
*/
SELECT
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    t.name AS TableName,
    c.name AS ColumnName,
    TYPE_NAME(c.user_type_id) AS DataType,
    
    -- Inline PK indicator (column-level, not table-level)
    CASE WHEN EXISTS (
        SELECT 1 FROM sys.indexes AS i
        INNER JOIN sys.index_columns AS ic 
            ON i.object_id = ic.object_id AND i.index_id = ic.index_id
        WHERE i.is_primary_key = 1 AND ic.object_id = t.object_id AND ic.column_id = c.column_id
    ) THEN 'PK' ELSE '' END AS IsPK,
    
    -- Inline FK reference (embedded relationship context)
    fk.ReferencedSchema AS FK_ReferencesSchema,
    fk.ReferencedTable AS FK_ReferencesTable,
    fk.ReferencedColumn AS FK_ReferencesColumn,
    
    -- Business semantics from extended properties
    CAST(ep.value AS NVARCHAR(500)) AS ColumnDescription

FROM sys.tables AS t
INNER JOIN sys.columns AS c ON t.object_id = c.object_id
    
-- Extended properties = business metadata layer
LEFT JOIN sys.extended_properties AS ep 
    ON ep.major_id = t.object_id AND ep.minor_id = c.column_id AND ep.class = 1
    
-- FK subquery = relationship context layer
LEFT JOIN (
    SELECT 
        fkc.parent_object_id, fkc.parent_column_id,
        SCHEMA_NAME(ref_t.schema_id) AS ReferencedSchema,
        ref_t.name AS ReferencedTable,
        ref_c.name AS ReferencedColumn
    FROM sys.foreign_key_columns AS fkc
    INNER JOIN sys.tables AS ref_t ON fkc.referenced_object_id = ref_t.object_id
    INNER JOIN sys.columns AS ref_c 
        ON fkc.referenced_object_id = ref_c.object_id 
        AND fkc.referenced_column_id = ref_c.column_id
) AS fk ON fk.parent_object_id = t.object_id AND fk.parent_column_id = c.column_id

-- Scoped to 17 customer analytics tables only
WHERE 
    (SCHEMA_NAME(t.schema_id) = 'Sales' AND t.name IN 
        ('Customer', 'SalesOrderHeader', 'SalesOrderDetail', 'SalesTerritory', 
         'SpecialOffer', 'SpecialOfferProduct', 'SalesOrderHeaderSalesReason', 'SalesReason'))
    OR (SCHEMA_NAME(t.schema_id) = 'Person' AND t.name IN 
        ('Person', 'EmailAddress', 'Address', 'StateProvince', 'BusinessEntityAddress', 'AddressType'))
    OR (SCHEMA_NAME(t.schema_id) = 'Production' AND t.name IN 
        ('Product', 'ProductSubcategory', 'ProductCategory'))

ORDER BY SchemaName, TableName, c.column_id;

/*
================================================================================
EXECUTION PLAYBOOK
================================================================================

NEW TO DATABASE (10 min):
1. Q1 → Schema structure
2. Q3 → Customer analytics table finder  
3. Q7 → Complete metadata dashboard

UNDERSTAND RELATIONSHIPS (10 min):
4. Q4 → Hub/spoke classification
5. Q5 → FK topology map
6. Q6 → Temporal column discovery

BUILD ERD (30 min):
7. Start with hubs from Q4 (Customer, Product, Territory)
8. Add spokes from Q4 (SalesOrderHeader, SalesOrderDetail)
9. Map relationships using Q9
10. Add bridge tables (SpecialOfferProduct, BusinessEntityAddress)

GENERATE DATA DICTIONARY:
11. Run Q11 → Export to Markdown/Excel
12. Populate docs/data-dictionary.md

KEY STRATEGIC INSIGHT:
This is not database exploration. This is analytical model design.
You defined business questions first, then selected tables intentionally.

PORTFOLIO DIFFERENTIATOR:
Most analysts show Power BI dashboards.
You show metadata engineering + dimensional thinking + business-question-driven architecture.
That signals: "I design analytical systems, not just consume them."

================================================================================
*/
