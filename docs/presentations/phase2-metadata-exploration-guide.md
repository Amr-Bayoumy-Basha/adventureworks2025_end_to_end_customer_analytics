# Phase 2: Metadata Exploration V2
## A Comprehensive Visual Learning Guide
### AdventureWorks 2025 — Customer Analytics Intelligence Layer

> **Conversion Note:** This Markdown file is structured as a 45-slide presentation.
> Each `---` separator marks a new slide. Import into Google Slides, PowerPoint, or use
> a Markdown-to-slides tool (e.g., Marp, Slidev, Reveal.js) for best results.
>
> **Color scheme:**
> - 🔵 Phase 1 (Discovery) — Blue tones
> - 🟢 Phase 2 (Relationships) — Green tones
> - 🟣 Phase 3 (Integration) — Purple tones
> - 🟠 Phase 4 (Documentation) — Orange tones

---

<!-- SLIDE 1 — Title -->
## 🗂️ Slide 1: Title Slide

```
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   PHASE 2: METADATA EXPLORATION V2                          ║
║   ─────────────────────────────────                         ║
║   Building an Analytical Intelligence Layer                 ║
║   on AdventureWorks 2025                                    ║
║                                                              ║
║   Author  : Azab Basha                                      ║
║   Date    : May 2026                                        ║
║   Database: SQL Server — AdventureWorks 2025                ║
║   Phase   : 2 of 4 (Table Selection & ERD Design)           ║
║                                                              ║
║   "Define the questions first. Then find the data."         ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

**Tags:** `#SQLServer` `#Metadata` `#ERD` `#CustomerAnalytics` `#DataEngineering`

---

<!-- SLIDE 2 — What is Metadata Exploration? -->
## 🔍 Slide 2: What Is Metadata Exploration — And Why Does It Matter?

### The Problem Every Analyst Faces

> You open a new database. It has **72 tables**. Where do you start?

Most analysts do this:
- ❌ Open the table list and click randomly
- ❌ Google "AdventureWorks tables"
- ❌ Ask a colleague "which tables should I use?"

### The Better Way: **Metadata-Driven Discovery**

| Without Metadata Exploration | With Metadata Exploration |
|------------------------------|--------------------------|
| Hours of manual browsing | 10-minute systematic scan |
| Random table selection | Business-question-driven selection |
| Missing relationships | Complete FK topology map |
| No documentation | Auto-generated data dictionary |
| "I think this table is right" | "I *know* this table fits because..." |

> 💡 **Key Insight:** System catalog views (`sys.tables`, `sys.schemas`, `sys.foreign_keys`) are **free** to query — zero performance cost on production databases.

---

<!-- SLIDE 3 — The 4-Phase Journey Analogy -->
## 🏙️ Slide 3: Think of It Like Exploring a New City

### The City Map Analogy

```
You arrive in a NEW CITY (= new database)

PHASE 1 — "Get Your Bearings"  🔵
  ┌─────────────────────────────────┐
  │ Look at the city map            │
  │ Identify neighborhoods (schemas)│
  │ Count buildings (tables)        │
  │ Mark the busiest streets (rows) │
  └─────────────────────────────────┘

PHASE 2 — "Learn the Roads"  🟢
  ┌─────────────────────────────────┐
  │ Find which roads connect where  │
  │ Identify major hubs (airports)  │
  │ Map the subway lines (FK paths) │
  └─────────────────────────────────┘

PHASE 3 — "Create Your Guide"  🟣
  ┌─────────────────────────────────┐
  │ Combine everything into one map │
  │ Your personal city dashboard    │
  └─────────────────────────────────┘

PHASE 4 — "Document for Others"  🟠
  ┌─────────────────────────────────┐
  │ Write the travel guide          │
  │ Mark every street & landmark    │
  │ Share with your team            │
  └─────────────────────────────────┘
```

> 🎯 **You are the cartographer. The database is the uncharted territory.**

---

<!-- SLIDE 4 — The 7 Strategic Questions -->
## 🎯 Slide 4: The 7 Strategic Customer Analytics Questions

> **Rule #1:** Define business questions BEFORE selecting tables.

```
┌────────────────────────────────────────────────────────────┐
│  Q1 │ Who are our MOST VALUABLE customers?                 │
│     │ → CLV, Revenue, Order Count                         │
├────────────────────────────────────────────────────────────┤
│  Q2 │ Which customers are UNPROFITABLE or risky?          │
│     │ → Returns, Discounts, Recency                       │
├────────────────────────────────────────────────────────────┤
│  Q3 │ How do customers DIFFER in behavior?                │
│     │ → RFM Scores, Basket Size, Category Diversity       │
├────────────────────────────────────────────────────────────┤
│  Q4 │ Are NEWER customer cohorts better or worse?         │
│     │ → Cohort Retention Rate, Revenue per Cohort         │
├────────────────────────────────────────────────────────────┤
│  Q5 │ Who is likely still ACTIVE vs "dead"?               │
│     │ → Last Purchase Date, Inter-purchase Time           │
├────────────────────────────────────────────────────────────┤
│  Q6 │ What ACTIONS should we take? (Prescriptive)         │
│     │ → Predicted CLV, Discount ROI, Incremental Lift     │
├────────────────────────────────────────────────────────────┤
│  Q7 │ What is the VALUE of our entire customer base?      │
│     │ → CBCV, Cohort Aggregates, Portfolio Projections    │
└────────────────────────────────────────────────────────────┘
```

**These 7 questions drive EVERY table selection decision in Phase 2.**

---

<!-- SLIDE 5 — Presentation Roadmap -->
## 🗺️ Slide 5: Your Learning Roadmap

```
INTRODUCTION                         YOU ARE HERE ★
  ↓
PHASE 1: HIGH-LEVEL DISCOVERY  🔵   Slides 6–15
  ├── Query #1: Schema Overview
  ├── Query #2: Table Sizes & Storage
  └── Query #3: Customer Analytics Finder
  ↓
PHASE 2: RELATIONSHIP DISCOVERY  🟢  Slides 16–25
  ├── Query #4: Hub & Spoke Analysis
  ├── Query #5: FK Relationship Map
  └── Query #6: Date/Time Finder
  ↓
PHASE 3: INTEGRATION  🟣            Slides 26–30
  └── Query #7: "One Query to Rule Them All"
  ↓
PHASE 4: DETAILED DOCUMENTATION  🟠  Slides 31–38
  ├── Query #8:  Primary Keys
  ├── Query #9:  Foreign Keys (ERD Core)
  ├── Query #10: Column Details
  └── Query #11: Data Dictionary Extraction
  ↓
TECHNICAL DEEP DIVES               Slides 39–42
  ↓
WRAP-UP & KEY TAKEAWAYS            Slides 43–45
```

> 💡 Estimated reading time: **45 minutes** | Estimated study time: **3 hours**

---

<!-- ══════════════════════════════════════════════════════════ -->
<!-- PHASE 1: HIGH-LEVEL DISCOVERY  (Slides 6–15) 🔵         -->
<!-- ══════════════════════════════════════════════════════════ -->

## 🔵 Slide 6: Phase 1 Overview — High-Level Discovery

```
╔══════════════════════════════════════════════════════════════╗
║  🔵  PHASE 1: HIGH-LEVEL DISCOVERY                         ║
║  "What exists and what matters?"                            ║
║                                                              ║
║  Goal: Classify entities by ANALYTICAL VALUE               ║
║        — not just by size or name                           ║
║                                                              ║
║  Three Power Queries:                                        ║
║  ┌──────────────────────────────────────────────────────┐   ║
║  │  Q1: Schema Overview      → Domain mapping           │   ║
║  │  Q2: Table Sizes          → Volume classification    │   ║
║  │  Q3: Analytics Finder     → Semantic tagging         │   ║
║  └──────────────────────────────────────────────────────┘   ║
║                                                              ║
║  Time Investment: ~10 minutes to run all three              ║
║  Output: Complete landscape of 71+ tables                   ║
╚══════════════════════════════════════════════════════════════╝
```

**Key Principle:** Every minute spent here saves hours of wrong-table rabbit holes later.

---

<!-- SLIDE 7 — Query #1: Schema Overview -->
## 🔵 Slide 7: Query #1 — Schema Overview

### Business Purpose
> **Goal:** Identify schema-level business domains in under 10 seconds.
> Focus ERD effort on high-density schemas (Sales, Person, Production).

### The SQL — Simple but Strategic

```sql
SELECT
    s.name AS SchemaName,
    COUNT(t.object_id) AS TableCount
FROM sys.schemas AS s
LEFT JOIN sys.tables AS t         -- ← Why LEFT? Include empty schemas too!
    ON t.schema_id = s.schema_id
GROUP BY s.name
HAVING COUNT(t.object_id) > 0    -- ← Filter AFTER aggregation (not WHERE)
ORDER BY TableCount DESC;
```

### Key SQL Concepts
| Concept | Why It Matters Here |
|---------|---------------------|
| `LEFT JOIN` | Keeps schemas even if they have 0 tables (full picture) |
| `GROUP BY` | Aggregates all tables under each schema |
| `HAVING` | Filters aggregated results (can't use `WHERE` on COUNT) |

### System Catalog Objects Used
- `sys.schemas` → Logical containers for database objects
- `sys.tables` → Metadata for all user-defined tables

---

<!-- SLIDE 8 — Query #1 Visual Output & Takeaway -->
## 🔵 Slide 8: Query #1 — Visual Domain Map

### Expected Output from AdventureWorks 2025

```
Schema Domain Map (sorted by table density)
══════════════════════════════════════════════

  Production  ████████████████████████  25 tables  ← Product catalog
  Person      █████████████            13 tables  ← Customer context
  Sales       ███████████████████      19 tables  ← ★ PRIMARY FOCUS ★
  HumanResources ████████              6 tables   ← Employee data
  Purchasing  ████████                 5 tables   ← Vendor/supply
  dbo         ██                       4 tables   ← Utility tables

══════════════════════════════════════════════
  TOTAL: 72 tables 68 across 5 business domains and 4 dbo as system and metadata tables
```

### Strategic Insight
```
  Sales Schema    → Transactions, Orders, Customers (HIGH priority)
  Person Schema   → Customer profiles, addresses (HIGH priority)
  Production Schema → Products, categories (MEDIUM priority)
  Others          → Out of scope for customer analytics
```

> 💡 **Key Takeaway:** Metadata catalog views = **zero performance cost**.
> You can run these on production databases without any concern.

---

<!-- SLIDE 9 — Query #2: Table Sizes & Row Counts -->
## 🔵 Slide 9: Query #2 — Table Sizes & Row Counts

### Business Purpose
> **Goal:** Identify operational hotspots — which tables hold the most data?
> **Why It Matters:** Large tables = fact candidates. Small tables = dimension candidates.

### The SQL — Storage Engine Access

```sql
SELECT
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    t.name AS TableName,
    SUM(p.rows) AS TotalRows,
    CAST(ROUND(SUM(a.total_pages) * 8.0 / 1024, 2)
         AS DECIMAL(18,2)) AS TotalSizeMB
FROM sys.tables AS t
JOIN sys.partitions AS p
    ON t.object_id = p.object_id          -- Storage pages
JOIN sys.allocation_units AS a
    ON p.partition_id = a.container_id    -- Space allocation
WHERE p.index_id IN (0, 1)               -- Heap(0) or Clustered(1) only
GROUP BY t.schema_id, t.name
ORDER BY TotalRows DESC, TotalSizeMB DESC;
```

### SQL Server Storage Concepts (8KB Pages)
```
┌─────────────────────────────────────────────────┐
│  1 Page    =   8 KB  (SQL Server I/O unit)       │
│  1 Extent  =  64 KB  (8 pages, allocation block) │
│  1 MB      = 128 pages                           │
│                                                   │
│  TotalSizeMB = total_pages × 8KB / 1024          │
│              = total_pages × 0.0078125 MB         │
└─────────────────────────────────────────────────┘
```

---

<!-- SLIDE 10 — Query #2 Visual & Takeaway -->
## 🔵 Slide 10: Query #2 — Fact vs Dimension Comparison

### Visual: Table Size Distribution

```
FACT TABLES (High Row Count) — Transactional Grain
══════════════════════════════════════════════════════
  SalesOrderDetail    ████████████████████  ~121,000 rows
  TransactionHistory  ██████████████████    ~113,000 rows
  WorkOrder           ████████              ~72,591 rows
  SalesOrderHeader    ███████               ~31,465 rows

DIMENSION TABLES (Low Row Count) — Reference Grain
══════════════════════════════════════════════════════
  Product             ████                  ~504 rows
  Customer            ████                  ~19,820 rows
  SalesTerritory      █                     ~10 rows
  ProductCategory     ▌                     ~4 rows
```

### Why This Signals Star Schema Structure
```
         ┌──────────────┐
         │  Customer    │  ← Dimension (small, stable)
         └──────┬───────┘
                │  FK
    ┌───────────▼───────────┐
    │   SalesOrderHeader    │  ← Fact (large, grows daily)
    └───────────┬───────────┘
                │  FK
         ┌──────▼───────┐
         │SalesOrderDetail│ ← Grain fact (largest!)
         └──────────────┘
```

> 💡 **Key Takeaway:** `SalesOrderDetail` (not `SalesOrderHeader`) is the transaction grain.
> Avoid double-counting by always joining at the detail level.

---

<!-- SLIDE 11 — Query #3: Customer Analytics Finder -->
## 🔵 Slide 11: Query #3 — Customer Analytics Table Classifier

### Business Purpose
> **Goal:** Auto-identify Customer/Transaction/Product tables for RFM/CLV/Cohort analysis.
> **Why This Matters:** Replaces 30 minutes of manual browsing with a 3-second query.

### The SQL — Semantic Inference via CASE

```sql
SELECT
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    t.name AS TableName,
    SUM(p.rows) AS TotalRows,
    CASE
        WHEN t.name LIKE '%Customer%' THEN 'Customer'   -- Priority 1
        WHEN t.name LIKE '%Person%'   THEN 'Person'
        WHEN t.name LIKE '%Order%'
          OR t.name LIKE '%Sales%'    THEN 'Transaction' -- Priority 2
        WHEN t.name LIKE '%Product%'  THEN 'Product'
        WHEN t.name LIKE '%Address%'  THEN 'Location'
        ELSE 'Other'
    END AS AnalyticsCategory,
    CASE
        WHEN t.name LIKE '%Customer%'               THEN 1  -- TOP priority
        WHEN t.name LIKE '%Order%'
          OR t.name LIKE '%Sales%'                  THEN 2
        ELSE 99
    END AS Priority
FROM sys.tables AS t
JOIN sys.partitions AS p ON t.object_id = p.object_id
JOIN sys.allocation_units AS a ON p.partition_id = a.container_id
WHERE p.index_id IN (0,1)
  AND (t.name LIKE '%Customer%' OR t.name LIKE '%Person%'
       OR t.name LIKE '%Order%' OR t.name LIKE '%Sales%'
       OR t.name LIKE '%Product%' OR t.name LIKE '%Address%')
GROUP BY t.schema_id, t.name
ORDER BY Priority, TotalRows DESC;
```

---

<!-- SLIDE 12 — Query #3 Concepts & Output -->
## 🔵 Slide 12: Query #3 — Semantic Tagging in Action

### How Semantic Inference Works

```
Table Name          Pattern Matched        Category Assigned
─────────────────────────────────────────────────────────────
Customer          → LIKE '%Customer%'  → 'Customer'      (P1)
Person            → LIKE '%Person%'    → 'Person'        (P2)
SalesOrderHeader  → LIKE '%Order%'     → 'Transaction'   (P3)
SalesOrderDetail  → LIKE '%Sales%'     → 'Transaction'   (P3)
Product           → LIKE '%Product%'   → 'Product'       (P4)
Address           → LIKE '%Address%'   → 'Location'      (P5)
StateProvince     → LIKE '%State%'     → 'location'      (P5)
Employee          → (no match)         → filtered out    (P99)
```

### Analytics Category Classification

```
┌─────────────────────────────────────────────────────────┐
│  Customer Analytics Finder Output                       │
│                                                         │
│  PRIORITY 1 — CUSTOMER TABLES                          │
│  ● Customer (Sales)      — 19,820 rows  ← Core entity  │
│                                                         │
│  PRIORITY 2 — TRANSACTION TABLES                       │
│  ● SalesOrderHeader      — 31,465 rows  ← Orders       │
│  ● SalesOrderDetail      — 121,317 rows ← Line items   │
│                                                         │
│  OTHER — REFERENCE TABLES                              │
│  ● Person, Product, Address...                          │
└─────────────────────────────────────────────────────────┘
```

> 💡 **Future Application:** This pattern is the foundation of commercial metadata catalogs
> like **Collibra** and **Alation** — they use similar semantic tagging at scale.

---

<!-- SLIDE 13 — Phase 1 Key Concepts Summary -->
## 🔵 Slide 13: Phase 1 — SQL Concepts Recap

### What You Learned in Phase 1

| Concept | Where Used | Why Important |
|---------|------------|---------------|
| `sys.schemas` | Q1 | Lists all logical domains |
| `sys.tables` | Q1, Q2, Q3 | Core metadata for all tables |
| `LEFT JOIN` | Q1 | Keeps schemas even with 0 tables |
| `HAVING` vs `WHERE` | Q1 | Filter on aggregates, not raw rows |
| `sys.partitions` | Q2, Q3 | Accesses storage layer metadata |
| `sys.allocation_units` | Q2 | Calculates actual disk usage |
| `8KB page formula` | Q2 | `pages × 8 / 1024 = MB` |
| `CASE expression` | Q3 | Pattern-based category assignment |
| `LIKE patterns` | Q3 | `%Customer%`, `%Order%`, `%Sales%` |
| Priority ordering | Q3 | Business-value-driven sorting |

### Phase 1 Deliverable
> After Phase 1, you know:
> - ✅ Which schemas matter for customer analytics
> - ✅ Which tables are likely facts vs dimensions
> - ✅ Which tables to focus on (Customer, SalesOrder*)

---

<!-- SLIDE 14 — Phase 1 Business Impact -->
## 🔵 Slide 14: Phase 1 — Business Impact

### Before vs After Phase 1

```
BEFORE Phase 1 Discovery:
────────────────────────────────────────────────
  "I'll just look at the table list and guess..."
   72 tables... which one is customer data?
   Is it Customer? Person? SalesPerson?
   → Hours wasted, wrong tables selected

AFTER Phase 1 Discovery (10 minutes):
────────────────────────────────────────────────
  ✅ Sales schema: 19 tables → Our primary domain
  ✅ Person schema: 13 tables → Customer profiles
  ✅ Production schema: 25 tables → Products only
  
  ✅ SalesOrderDetail: 121K rows → Transaction grain
  ✅ Customer: 19K rows → Master entity
  
  ✅ Customer analytics tables identified:
     Priority 1: Customer
     Priority 2: SalesOrderHeader, SalesOrderDetail
     Support:    Person, Product, Address
```

> 🎯 **Portfolio Insight:** This systematic approach proves you think like
> a **data architect**, not just a dashboard builder.

---

<!-- SLIDE 15 — Phase 1 Takeaway -->
## 🔵 Slide 15: Phase 1 — The Big Takeaway

```
╔══════════════════════════════════════════════════════════════╗
║  🔵  PHASE 1 COMPLETE                                       ║
║                                                              ║
║  You now know:                                              ║
║                                                              ║
║  1. THE LANDSCAPE  — 6 schemas, 72 tables                  ║
║  2. THE CANDIDATES — 17 customer analytics tables          ║
║                                                              ║
║  Time Spent: ~10 minutes                                    ║
║  Value Gained: Weeks of wrong-path prevention               ║
║                                                              ║
║  Next: Phase 2 — How do these tables CONNECT?              ║
║  "A map without roads is just a picture."                   ║
╚══════════════════════════════════════════════════════════════╝
```

**Phase 1 → Phase 2 Bridge:**
- You know WHAT tables exist ✅
- Now you need to know HOW they relate 🟢

---

<!-- ══════════════════════════════════════════════════════════ -->
<!-- PHASE 2: RELATIONSHIP DISCOVERY  (Slides 16–25) 🟢       -->
<!-- ══════════════════════════════════════════════════════════ -->

## 🟢 Slide 16: Phase 2 Overview — Relationship Discovery

```
╔══════════════════════════════════════════════════════════════╗
║  🟢  PHASE 2: TOPOLOGY — "How do entities connect?"        ║
║                                                              ║
║  Goal: Detect dimensional model patterns                    ║
║        (hubs, spokes, bridges)                              ║
║                                                              ║
║  Three Strategic Queries:                                    ║
║  ┌──────────────────────────────────────────────────────┐   ║
║  │  Q4: Hub & Spoke Analysis  → Role classification     │   ║
║  │  Q5: FK Relationship Map   → Topology density        │   ║
║  │  Q6: Date/Time Finder      → Temporal anchors        │   ║
║  └──────────────────────────────────────────────────────┘   ║
║                                                              ║
║  Output: Complete FK topology + temporal intelligence        ║
╚══════════════════════════════════════════════════════════════╝
```

### Why This Phase Is Critical
Without relationship maps, you'll:
- ❌ Create wrong JOIN paths → wrong numbers
- ❌ Miss bridge tables → data fan-out errors
- ❌ Use wrong date columns → incorrect time-series

---

<!-- SLIDE 17 — Query #4: Hub & Spoke Analysis -->
## 🟢 Slide 17: Query #4 — Hub & Spoke Analysis (Graph Theory!)

### The Graph Theory Connection
> A relational database is actually a **directed graph**:
> - Tables = nodes
> - Foreign keys = directed edges
> - High in-degree = hub (dimension)
> - High out-degree = spoke (fact)

### CTE Architecture Explained

```sql
WITH TableRelationships AS (        -- ← Step 1: Build the graph
    SELECT
        SCHEMA_NAME(t.schema_id) AS SchemaName,
        t.name AS TableName,
        COUNT(DISTINCT fk_out.object_id) AS OutgoingFKs, -- Out-degree
        COUNT(DISTINCT fk_in.object_id)  AS IncomingFKs  -- In-degree
    FROM sys.tables AS t
    LEFT JOIN sys.foreign_keys AS fk_out               -- Tables I point TO
        ON t.object_id = fk_out.parent_object_id
    LEFT JOIN sys.foreign_keys AS fk_in                -- Tables pointing at ME
        ON t.object_id = fk_in.referenced_object_id
    GROUP BY t.schema_id, t.name
)
SELECT *, ...                       -- ← Step 2: Classify roles
FROM TableRelationships
WHERE (IncomingFKs + OutgoingFKs) > 0;
```

**Why Two Separate LEFT JOINs?**
- `fk_out`: "This table has a FK pointing TO another table" → Spoke behavior
- `fk_in`: "Other tables have FKs pointing TO this table" → Hub behavior

---

<!-- SLIDE 18 — Query #4 Classification Logic & Visual -->
## 🟢 Slide 18: Query #4 — Table Role Classification

### Classification Rules

```sql
CASE
  WHEN IncomingFKs > OutgoingFKs AND IncomingFKs >= 2
    THEN 'Hub (Dimension)'    -- Many tables reference ME
  WHEN OutgoingFKs > IncomingFKs AND OutgoingFKs >= 2
    THEN 'Spoke (Fact)'       -- I reference MANY tables
  WHEN IncomingFKs = 0 AND OutgoingFKs = 0
    THEN 'Standalone'         -- Isolated island
  ELSE 'Bridge/Lookup'        -- Equal or mixed
END AS TableRole
```

### Visual: Hub-Spoke Diagram

```
         ┌─────────────┐
         │  Customer   │  ← HUB (Dimension) — 5 incoming FKs
         └──────┬──────┘
                │
    ┌───────────┴────────────────────────────┐
    │                                        │
┌───▼───────────────┐             ┌──────────▼─────┐
│  SalesOrderHeader │◄── SPOKE ──►│  SpecialOffer  │
│  (Fact Table)     │             │  (Lookup/Bridge)│
└───┬───────────────┘             └────────────────┘
    │  FK to: Customer, Territory
    │  FK to: SalesPerson, Currency
    ▼
┌───────────────────┐
│  SalesOrderDetail │  ← SPOKE (Fact) — 4 outgoing FKs
└───────────────────┘
    FK to: SalesOrder, Product, SpecialOffer
```

> 💡 **Key Takeaway:** Hub tables = your DIMENSION tables in a star schema.
> Spoke tables = your FACT tables. This tells you the warehouse design before you build it!

---

<!-- SLIDE 19 — Query #5: FK Relationship Map -->
## 🟢 Slide 19: Query #5 — FK Relationship Map with Density Metrics

### Business Purpose
> **Goal:** Identify the most heavily connected tables for ERD design focus.
> Know WHICH specific tables are connected and HOW densely.

### Window Functions — A Powerful SQL Pattern

```sql
SELECT
    SCHEMA_NAME(r.schema_id) AS ReferencedSchema,
    r.name AS ReferencedTable,
    SCHEMA_NAME(p.schema_id) AS ParentSchema,
    p.name AS ParentTable,
    fk.name AS ForeignKeyName,

    -- Window function: count FKs across ALL rows for the same referenced table
    COUNT(*) OVER (PARTITION BY r.object_id) AS FKDensityAsReferenced,

    -- Window function: count FKs across ALL rows for the same parent table
    COUNT(*) OVER (PARTITION BY p.object_id) AS FKDensityAsParent

FROM sys.foreign_keys AS fk
INNER JOIN sys.tables AS p ON p.object_id = fk.parent_object_id
INNER JOIN sys.tables AS r ON r.object_id = fk.referenced_object_id
ORDER BY FKDensityAsReferenced DESC;
```

### Why Window Functions Here?
```
Regular COUNT → One row per group
Window COUNT  → KEEPS all rows AND adds the group total

Result: Every FK relationship row also shows
        "how many total FKs does this referenced table have"
        → FKDensityAsReferenced = connectivity score
```

---

<!-- SLIDE 20 — Query #5 Visual Output -->
## 🟢 Slide 20: Query #5 — Understanding FK Density

### FK Density Explained

```
FKDensityAsReferenced = How many tables point TO this table?
                      = "How popular is this table as a reference?"

FKDensityAsParent    = How many tables does this table point to?
                     = "How dependent is this table on others?"
```

### Sample Output Visualization

```
ReferencedTable      ParentTable              FK Density (as Ref)
───────────────────────────────────────────────────────────────
Person.Person       ← Sales.Customer          7  ← MOST referenced!
Person.Person       ← Sales.SalesPerson       7
Person.Person       ← HR.Employee             7
Person.Person       ← Person.EmailAddress     7
Person.Person       ← Person.BusinessEntity   7
...

Sales.SalesOrderHeader ← Sales.SalesOrderDetail  4
Sales.SalesOrderHeader ← Sales.Reasons           4
```

### ERD Construction Insight

```
High FKDensityAsReferenced → Draw this table FIRST in your ERD
                           → It's a central entity (dimension)
High FKDensityAsParent     → Draw outgoing edges from this table
                           → It's a dependent entity (fact/bridge)
```

> 💡 **Key Takeaway:** `Person.Person` is the most referenced entity (7+ FKs).
> In ERD design, draw `Person` at the center of the Person cluster.

---

<!-- SLIDE 21 — Query #6: Date/Time Finder -->
## 🟢 Slide 21: Query #6 — Temporal Column Discovery

### Why Dates Are Critical for Customer Analytics

> **Without date columns: No time-series analytics possible.**
> RFM needs a "last purchase date." Cohorts need "first purchase date."
> Retention needs "days since last purchase."

### Business Purpose
> **Goal:** Find ALL temporal anchors in the database.
> Classify each by its analytical role (Transaction, Audit, Fulfillment, etc.)

### The SQL

```sql
SELECT
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    SUM(p.rows) AS TableRowCount,
    CASE
        WHEN c.name LIKE '%Order%Date%'
          OR c.name LIKE '%Purchase%'   THEN 'Transaction Date'
        WHEN c.name LIKE '%Birth%'      THEN 'Birth Date'
        WHEN c.name LIKE '%Modified%'   THEN 'Audit Date'
        WHEN c.name LIKE '%Ship%'       THEN 'Fulfillment Date'
        ELSE 'Other Date'
    END AS DateCategory
FROM sys.tables AS t
JOIN sys.columns AS c ON t.object_id = c.object_id
JOIN sys.types AS ty ON c.user_type_id = ty.user_type_id  -- ← Type filter
JOIN sys.partitions AS p ON t.object_id = p.object_id
WHERE ty.name IN ('date', 'datetime', 'datetime2', 'smalldatetime')
  AND p.index_id IN (0,1)
GROUP BY t.schema_id, t.name, c.name, ty.name
ORDER BY TableRowCount DESC;
```

---

<!-- SLIDE 22 — Query #6 Date Semantics & Analytics Use Cases -->
## 🟢 Slide 22: Query #6 — Date Semantics & Analytics Use Cases

### Date Category Taxonomy

```
DATE CATEGORIES IN ADVENTUREWORKS
═══════════════════════════════════════════════════════════
  Transaction Date  → OrderDate, DueDate
  Purpose: PRIMARY temporal grain for RFM, cohort, retention

  Fulfillment Date  → ShipDate
  Purpose: Delivery performance, SLA analysis

  Audit Date        → ModifiedDate, CreatedDate
  Purpose: Data lineage, schema change tracking (NOT for analytics)

  Birth Date        → BirthDate (Person table)
  Purpose: Age-based segmentation, generational analysis

  Other Date        → StartDate, EndDate (SalesTerritory history)
  Purpose: Slowly Changing Dimension (SCD Type 2) tracking
```

### Analytics Use Cases per Date Type

```
┌────────────────────────────────────────────────────────────┐
│  RFM Analysis        → OrderDate (Recency = MAX(OrderDate))│
│  Cohort Analysis     → MIN(OrderDate) per customer         │
│  Retention Analysis  → Days between OrderDates             │
│  Age Segmentation    → DATEDIFF(year, BirthDate, GETDATE())│
│  Time-to-Ship        → DATEDIFF(day, OrderDate, ShipDate)  │
└────────────────────────────────────────────────────────────┘
```

> 💡 **Key Insight:** `OrderDate` in `SalesOrderHeader` is your PRIMARY temporal anchor.
> It's the foundation of every time-based analysis in this project.

---

<!-- SLIDE 23 — Query #6 System Object Deep Dive -->
## 🟢 Slide 23: Query #6 — Understanding sys.columns & sys.types

### System Catalog: The Database's DNA

```
sys.columns — Every column in every table
═══════════════════════════════════════════
  object_id      → Links to sys.tables
  column_id      → Column position (ordinal)
  name           → Column name
  user_type_id   → Links to sys.types
  max_length     → Storage size limit
  is_nullable    → Can it be NULL?
  precision      → Numeric precision
  scale          → Decimal places

sys.types — Data type registry
═══════════════════════════════════════════
  user_type_id   → Unique type identifier
  name           → 'date', 'datetime', 'nvarchar', etc.
  system_type_id → Built-in vs user-defined types
```

### Why Filter `index_id IN (0, 1)`?
```
index_id = 0 → HEAP (no clustered index, full table scan storage)
index_id = 1 → CLUSTERED INDEX (most common, data stored in order)
index_id > 1 → NON-CLUSTERED INDEX (secondary copies — DON'T count twice!)

Without this filter: Row counts would be MULTIPLIED by number of indexes!
```

---

<!-- SLIDE 24 — Phase 2 FK Topology Summary -->
## 🟢 Slide 24: Phase 2 — Complete FK Topology Map

### AdventureWorks Customer Analytics Topology

```
                    PERSON CLUSTER
               ┌─────────────────────┐
               │    Person.Person    │← Most referenced entity
               │    (BusinessEntity) │
               └──┬──────────────────┘
                  │ FK (BusinessEntityID)
         ┌────────┴────────┐
         │                 │
    ┌────▼──────┐    ┌─────▼──────────┐
    │ Customer  │    │  EmailAddress  │
    │ (Sales)   │    │  Address       │
    └────┬──────┘    └────────────────┘
         │ FK (CustomerID)
         ▼
    ┌────────────────────────┐
    │   SalesOrderHeader     │
    │   (Transaction Fact)   │
    └────┬───────────────────┘
         │ FK (SalesOrderID)
    ┌────▼───────────────────────────┐
    │      SalesOrderDetail          │
    │  (Line Item Grain — LARGEST)   │
    └────┬───────────────────────────┘
         │ FK (ProductID)
    ┌────▼──────────────────────┐
    │  Product → Subcategory    │
    │         → Category        │
    └───────────────────────────┘
```

---

<!-- SLIDE 25 — Phase 2 Takeaway -->
## 🟢 Slide 25: Phase 2 — The Big Takeaway

```
╔══════════════════════════════════════════════════════════════╗
║  🟢  PHASE 2 COMPLETE                                       ║
║                                                              ║
║  You now know:                                              ║
║                                                              ║
║  1. TABLE ROLES    — Hub (dim) vs Spoke (fact) vs Bridge    ║
║  2. FK TOPOLOGY    — Who connects to whom, with density     ║
║  3. TEMPORAL ANCHORS — OrderDate is the primary grain       ║
║                                                              ║
║  Key Tables Identified:                                     ║
║  ● Customer, Person     → HUBS (dimensions)                 ║
║  ● SalesOrderHeader     → SPOKE (transaction fact)          ║
║  ● SalesOrderDetail     → SPOKE (line item grain)           ║
║  ● SpecialOfferProduct  → BRIDGE (many-to-many resolver)    ║
║                                                              ║
║  Next: Phase 3 — Combine ALL metadata into ONE query!       ║
╚══════════════════════════════════════════════════════════════╝
```

---

<!-- ══════════════════════════════════════════════════════════ -->
<!-- PHASE 3: INTEGRATION  (Slides 26–30) 🟣                  -->
<!-- ══════════════════════════════════════════════════════════ -->

## 🟣 Slide 26: Phase 3 Overview — The Integration Phase

```
╔══════════════════════════════════════════════════════════════╗
║  🟣  PHASE 3: INTEGRATION                                   ║
║  "Combine everything into one metadata dashboard"            ║
║                                                              ║
║  The Challenge: You now have data from 6 separate queries.  ║
║  Running them separately = context-switching overhead.       ║
║                                                              ║
║  The Solution: ONE unified CTE query                        ║
║                                                              ║
║  Query #7: "One Query to Rule Them All"                     ║
║  ┌──────────────────────────────────────────────────────┐   ║
║  │  TableSizes CTE      → Storage & volume metrics      │   ║
║  │  TableRelationships  → FK topology                   │   ║
║  │  DateColumns         → Temporal capabilities         │   ║
║  │  DescriptionInfo     → Business metadata             │   ║
║  └──────────────────────────────────────────────────────┘   ║
╚══════════════════════════════════════════════════════════════╝
```

**This is where you go from analyst to metadata engineer.**

---

<!-- SLIDE 27 — Query #7: Multi-CTE Architecture -->
## 🟣 Slide 27: Query #7 — Multi-CTE Architecture Breakdown

### What Is a CTE (Common Table Expression)?

```sql
-- A CTE is a named, temporary result set used within ONE query
WITH MyCTE AS (
    SELECT ...    -- This runs ONCE
)
SELECT * FROM MyCTE; -- Use it like a table
```

### Q7 Has FOUR CTEs — Each Handles One Metadata Layer

```
WITH TableSizes AS (          ← Layer 1: Infrastructure Intel
    ...storage metrics...
),
TableRelationships AS (       ← Layer 2: FK Topology
    ...FK counting...
),
DateColumns AS (              ← Layer 3: Temporal Data
    ...date columns...
),
DescriptionInfo AS (          ← Layer 4: Business Semantics
    ...extended properties...
)
SELECT
    ts.SchemaName, ts.TableName,
    ts.TotalRows, ts.TotalSizeMB,
    tr.OutgoingFKs, tr.IncomingFKs,
    ... TableRole classification ...
    dc.DateColumnCount, dc.DateColumnList,
    di.TableDescription
FROM TableSizes ts
LEFT JOIN TableRelationships tr ...  ← Merge all layers
LEFT JOIN DateColumns dc ...
LEFT JOIN DescriptionInfo di ...
```

---

<!-- SLIDE 28 — Query #7: CTE Deep Dive -->
## 🟣 Slide 28: Query #7 — Inside Each CTE

### CTE 1: TableSizes — Infrastructure Intelligence
```sql
-- Answers: "How big is each table?"
SELECT t.schema_id, t.object_id,
       SCHEMA_NAME(t.schema_id) AS SchemaName,
       t.name AS TableName,
       SUM(p.rows) AS TotalRows,
       CAST(ROUND(SUM(a.total_pages) * 8.0 / 1024, 2)
            AS DECIMAL(18,2)) AS TotalSizeMB
FROM sys.tables AS t
JOIN sys.partitions AS p ...
JOIN sys.allocation_units AS a ...
WHERE p.index_id IN (0,1)
GROUP BY t.schema_id, t.object_id, t.name
```

### CTE 3: DateColumns — Temporal Intelligence
```sql
-- Answers: "Does this table support time-series analysis?"
SELECT t.object_id AS TableObjectId,
       COUNT(*) AS DateColumnCount,
       STRING_AGG(c.name, ', ') AS DateColumnList  -- ← Aggregates all date col names
FROM sys.tables AS t
JOIN sys.columns AS c ON t.object_id = c.object_id
JOIN sys.types AS ty ON c.user_type_id = ty.user_type_id
WHERE ty.name IN ('date','datetime','datetime2','smalldatetime')
GROUP BY t.object_id
```

### What Is `STRING_AGG`?
```sql
-- Without STRING_AGG: Multiple rows per table
--   SalesOrderHeader | OrderDate
--   SalesOrderHeader | DueDate
--   SalesOrderHeader | ShipDate

-- With STRING_AGG: One row per table
--   SalesOrderHeader | OrderDate, DueDate, ShipDate
```

---

<!-- SLIDE 29 — Query #7: ISNULL & Business Metadata -->
## 🟣 Slide 29: Query #7 — Business Metadata & ISNULL

### CTE 4: DescriptionInfo — Business Semantics
```sql
-- Answers: "What does this table mean in business terms?"
SELECT t.object_id AS TableObjectId,
       ep.value AS TableDescription
FROM sys.tables AS t
LEFT JOIN sys.extended_properties AS ep
    ON t.object_id = ep.major_id
   AND ep.minor_id = 0          -- ← 0 = table level (not column)
   AND ep.name = 'MS_Description'  -- ← Standard description property
```

### What Are Extended Properties?
```
sys.extended_properties = a "sticky notes" system for database objects

You can attach ANY metadata to ANY object:
  ALTER TABLE Sales.Customer
  ADD CONSTRAINT ... ;

  EXEC sp_addextendedproperty
    @name = 'MS_Description',
    @value = 'Master customer record for B2B and B2C customers',
    @level0type = 'Schema', @level0name = 'Sales',
    @level1type = 'Table',  @level1name = 'Customer';
```

### The ISNULL Pattern
```sql
-- LEFT JOIN means some rows will have NULL for missing metadata
-- ISNULL converts NULL to a safe default value

ISNULL(tr.OutgoingFKs, 0)  -- If no FK record: show 0, not NULL
ISNULL(dc.DateColumnCount, 0)  -- If no dates: show 0, not NULL
```

---

<!-- SLIDE 30 — Query #7 Visual Data Flow & Metadata Mart Concept -->
## 🟣 Slide 30: Query #7 — The Metadata Mart Concept

### Data Flow Diagram

```
  sys.tables ──────────────────────────────────────────────────┐
       │                                                        │
       ├──► sys.partitions                                      │
       │         └──► sys.allocation_units ──► TableSizes CTE  │
       │                                                        │
       ├──► sys.foreign_keys (fk_out + fk_in) ──► TableRel CTE │
       │                                                        │
       ├──► sys.columns ──► sys.types ──► DateColumns CTE      │
       │                                                        │
       └──► sys.extended_properties ──► DescriptionInfo CTE    │
                                                                │
                    4 CTEs JOIN on object_id ◄──────────────────┘
                              │
                              ▼
                    ┌─────────────────────┐
                    │  Unified Metadata   │
                    │    Dashboard        │
                    │                     │
                    │  ● Table name       │
                    │  ● Row count        │
                    │  ● Size in MB       │
                    │  ● FK in/out count  │
                    │  ● Table role       │
                    │  ● Date columns     │
                    │  ● Business desc    │
                    │  ● Analytics cat    │
                    └─────────────────────┘
```

> 💡 **Metadata Mart Concept:** This is a lightweight version of what enterprise tools
> (Apache Atlas, DataHub, Collibra) do at scale. You built it with pure SQL.
> **Portfolio Signal:** "I understand data governance and cataloging principles."

---

<!-- ══════════════════════════════════════════════════════════ -->
<!-- PHASE 4: DETAILED DOCUMENTATION  (Slides 31–38) 🟠       -->
<!-- ══════════════════════════════════════════════════════════ -->

## 🟠 Slide 31: Phase 4 Overview — Detailed Documentation

```
╔══════════════════════════════════════════════════════════════╗
║  🟠  PHASE 4: DOCUMENTATION                                 ║
║  "Finalize structure for ERD and Data Dictionary"           ║
║                                                              ║
║  Goal: Convert raw system metadata into                     ║
║        business-ready documentation artifacts               ║
║                                                              ║
║  Four Final Queries:                                         ║
║  ┌──────────────────────────────────────────────────────┐   ║
║  │  Q8:  Primary Keys   → Identity layer                │   ║
║  │  Q9:  Foreign Keys   → ERD backbone                  │   ║
║  │  Q10: Column Details → Schema blueprint              │   ║
║  │  Q11: Data Dictionary → Complete documentation       │   ║
║  └──────────────────────────────────────────────────────┘   ║
║                                                              ║
║  Output: ERD-ready data + auto-generated Data Dictionary    ║
╚══════════════════════════════════════════════════════════════╝
```

---

<!-- SLIDE 32 — Query #8: Primary Keys -->
## 🟠 Slide 32: Query #8 — Primary Key Identification

### Business Purpose
> **Goal:** Define unique identifiers for ERD — prevent double-counting in DAX.
> **Strategic Value:** Distinguish natural keys vs surrogate keys.

### The SQL

```sql
SELECT
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    t.name AS TableName,
    kc.name AS PrimaryKeyName,
    c.name AS ColumnName,
    ic.key_ordinal AS KeyOrdinal  -- ← Position in composite key
FROM sys.key_constraints AS kc
INNER JOIN sys.indexes AS i
    ON kc.parent_object_id = i.object_id
   AND kc.unique_index_id = i.index_id  -- ← PK is always an index
INNER JOIN sys.index_columns AS ic
    ON i.object_id = ic.object_id
   AND i.index_id  = ic.index_id
INNER JOIN sys.columns AS c
    ON ic.object_id  = c.object_id
   AND ic.column_id  = c.column_id
INNER JOIN sys.tables AS t
    ON t.object_id = kc.parent_object_id
WHERE kc.type = 'PK'              -- ← Only Primary Key constraints
ORDER BY SchemaName, TableName, ic.key_ordinal;
```

### System Objects Used
| Object | Role |
|--------|------|
| `sys.key_constraints` | Lists PK and UNIQUE constraints |
| `sys.indexes` | Connects constraint to index structure |
| `sys.index_columns` | Lists columns in each index |
| `sys.columns` | Provides column names and metadata |

---

<!-- SLIDE 33 — Query #8 Composite Keys & KeyOrdinal -->
## 🟠 Slide 33: Query #8 — Composite vs Single Keys

### Why KeyOrdinal Matters

```
Single-Column PK (most common):
──────────────────────────────
  Table: Customer
  PK: CustomerID   (KeyOrdinal = 1)
  → One column uniquely identifies each customer

Composite PK (bridge tables):
──────────────────────────────
  Table: SalesOrderDetail
  PK: SalesOrderID  (KeyOrdinal = 1)
      SalesOrderDetailID (KeyOrdinal = 2)
  → TWO columns together = unique line item

  Table: SpecialOfferProduct
  PK: SpecialOfferID (KeyOrdinal = 1)
      ProductID       (KeyOrdinal = 2)
  → Classic many-to-many bridge PK
```

### PK Types in AdventureWorks Customer Analytics Tables

```
Natural Key (meaningful ID):    BusinessEntityID → Person.Person
Surrogate Key (system number):  CustomerID       → Sales.Customer
Composite Key (bridge tables):  SalesOrderID + SalesOrderDetailID
```

> 💡 **ERD Implication:** KeyOrdinal tells you the correct column ORDER
> in composite PKs — critical for DBML and ERD notation.

---

<!-- SLIDE 34 — Query #9: Foreign Keys (ERD Core) -->
## 🟠 Slide 34: Query #9 — Foreign Keys (ERD Backbone)

### Business Purpose
> **Goal:** Build ERD relationship lines with correct cardinality.
> **Why It Matters:** ON DELETE/UPDATE actions reveal data integrity rules.

### The SQL — Column-Level FK Mapping

```sql
SELECT
    fk.name AS ForeignKeyName,
    SCHEMA_NAME(p.schema_id) AS ParentSchema,
    p.name AS ParentTable,
    pc.name AS ParentColumn,      -- ← Column with the FK value
    SCHEMA_NAME(r.schema_id) AS ReferencedSchema,
    r.name AS ReferencedTable,
    rc.name AS ReferencedColumn,  -- ← Column being referenced (usually PK)
    fk.delete_referential_action_desc AS OnDelete,   -- CASCADE? NO ACTION?
    fk.update_referential_action_desc AS OnUpdate
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc
    ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.tables AS p
    ON p.object_id = fkc.parent_object_id
INNER JOIN sys.columns AS pc
    ON pc.object_id = p.object_id
   AND pc.column_id = fkc.parent_column_id    -- ← Column-level resolution
INNER JOIN sys.tables AS r
    ON r.object_id = fkc.referenced_object_id
INNER JOIN sys.columns AS rc
    ON rc.object_id = r.object_id
   AND rc.column_id = fkc.referenced_column_id
ORDER BY ParentSchema, ParentTable, fkc.constraint_column_id;
```

---

<!-- SLIDE 35 — Query #9 Referential Actions & ERD Generation -->
## 🟠 Slide 35: Query #9 — Referential Actions & ERD Generation

### Referential Integrity Actions

```
ON DELETE / ON UPDATE — What happens when a parent row changes?

Action         Meaning                           When to Use
─────────────────────────────────────────────────────────────
NO ACTION    → Reject the change (default)     Most FK constraints
CASCADE      → Propagate change to children    Soft deletes, archives
SET NULL     → Set child FK to NULL            Optional relationships
SET DEFAULT  → Set child FK to default value   Rare, special cases
```

### How Q9 Output Generates ERD Edges

```
Q9 Output Row:
  FK: FK_SalesOrderHeader_Customer
  ParentTable:     Sales.SalesOrderHeader
  ParentColumn:    CustomerID
  ReferencedTable: Sales.Customer
  ReferencedColumn:CustomerID
  OnDelete:        NO ACTION
  OnUpdate:        NO ACTION

→ ERD Edge Generated:
  Sales.SalesOrderHeader.CustomerID → Sales.Customer.CustomerID
  Notation: Many-to-One  (N:1)
  Action:   Restricted (NO CASCADE)

DBML Translation:
  Ref: Sales.SalesOrderHeader.CustomerID
       > Sales.Customer.CustomerID
```

> 💡 **Key Takeaway:** Q9 output can be programmatically converted to DBML, ERD JSON,
> or Mermaid ERD syntax. Automation of ERD generation = metadata engineering skill.

---

<!-- SLIDE 36 — Query #10: Column Details -->
## 🟠 Slide 36: Query #10 — Column Details (Schema Blueprint)

### Business Purpose
> **Goal:** Foundation for data profiling and Power BI field type mapping.
> **Use Case:** Validate data types BEFORE writing ETL transformations.

### The SQL

```sql
SELECT
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLength,   -- For varchar/nvarchar: char limit
    c.precision AS Precision,    -- For numeric: total digits
    c.scale AS Scale,            -- For numeric: decimal places
    c.is_nullable AS IsNullable, -- Can this be NULL? (0/1)
    c.column_id AS ColumnOrder   -- Position in table
FROM sys.tables AS t
JOIN sys.columns AS c ON t.object_id = c.object_id
JOIN sys.types AS ty ON c.user_type_id = ty.user_type_id
ORDER BY SchemaName, TableName, c.column_id;
```

### Why Nullability Impacts Analytics

```
is_nullable = 1 (Can be NULL):
  ● COUNT(column) < COUNT(*) — will undercounts!
  ● AVG(column) ignores NULLs — potentially misleading
  ● JOIN on nullable FK creates LEFT JOIN requirement

is_nullable = 0 (Cannot be NULL):
  ● Safe to use in GROUP BY without ISNULL wrapper
  ● COUNT(column) = COUNT(*) — guaranteed
  ● FK always has a value — INNER JOIN is safe
```

---

<!-- SLIDE 37 — Query #11: Data Dictionary Extraction -->
## 🟠 Slide 37: Query #11 — Data Dictionary Extraction (The Final Boss!)

### Business Purpose
> **Goal:** Build a complete, auto-generated business data dictionary.
> **Scope:** The 17 carefully selected customer analytics tables only.
> **Output:** Documentation-ready result set for Markdown/Excel export.

### Why This Is Advanced: Metadata Engineering, Not Just Querying

```
Q1–Q10:  Metadata EXPLORATION  → "What's there?"
Q11:     Metadata ENGINEERING  → "Document it systematically"

Q11 Combines 4 Metadata Layers in One Query:
┌──────────────────────────────────────────────────────────┐
│  Layer 1: sys.tables + sys.columns  → Structure         │
│  Layer 2: sys.extended_properties   → Descriptions      │
│  Layer 3: sys.indexes (PK subquery) → Key annotations   │
│  Layer 4: sys.foreign_key_columns   → Relationship ctx  │
└──────────────────────────────────────────────────────────┘
```

### The 17 Scoped Tables

```sql
WHERE
  (SCHEMA_NAME(t.schema_id) = 'Sales' AND t.name IN
    ('Customer','SalesOrderHeader','SalesOrderDetail','SalesTerritory',
     'SpecialOffer','SpecialOfferProduct',
     'SalesOrderHeaderSalesReason','SalesReason'))
  OR (SCHEMA_NAME(t.schema_id) = 'Person' AND t.name IN
    ('Person','EmailAddress','Address','StateProvince',
     'BusinessEntityAddress','AddressType'))
  OR (SCHEMA_NAME(t.schema_id) = 'Production' AND t.name IN
    ('Product','ProductSubcategory','ProductCategory'))
```

---

<!-- SLIDE 38 — Query #11 Output & Portfolio Impact -->
## 🟠 Slide 38: Query #11 — Output Structure & Portfolio Impact

### Sample Output Row

```
SchemaName  | Sales
TableName   | SalesOrderHeader
ColumnName  | CustomerID
DataType    | int
IsPK        | (empty — not a PK column)
FK_Schema   | Sales
FK_Table    | Customer
FK_Column   | CustomerID
Description | (from MS_Description extended property if set)
```

### Real-World Applications of Q11

```
Auto-generate Markdown data dictionaries:
  → Pipe Q11 output into Python/PowerShell → README.md

Feed metadata to Power BI semantic models:
  → Import descriptions as field tooltips

Enable data lineage tracking:
  → FK columns reveal upstream/downstream dependencies

Support schema drift detection:
  → Compare Q11 output over time → find changed columns

Create API documentation:
  → Q11 = schema documentation for REST API endpoints
```

> 💡 **Portfolio Differentiator:** Most analysts show Power BI dashboards.
> **You built a lightweight Data Catalog system** — similar to Collibra or Alation.
> That signals: *"I design analytical systems, not just consume them."*

---

<!-- ══════════════════════════════════════════════════════════ -->
<!-- TECHNICAL DEEP DIVES  (Slides 39–42)                     -->
<!-- ══════════════════════════════════════════════════════════ -->

## ⚙️ Slide 39: SQL Server Internals — Pages, Partitions & Indexes

### The Storage Engine (Simplified)

```
SQL SERVER STORAGE HIERARCHY
═══════════════════════════════════════════════════════════════

  DATABASE
    └── FILEGROUP (logical storage group)
          └── DATA FILE (.mdf / .ndf)
                └── EXTENT (8 pages = 64 KB)
                      └── PAGE (8 KB — fundamental I/O unit)
                            ├── Data Page        (rows of data)
                            ├── Index Page       (B-tree nodes)
                            ├── LOB Page         (text/blob data)
                            └── IAM Page         (allocation map)

sys.allocation_units types:
  IN_ROW_DATA   → Standard row data (type 1)
  LOB_DATA      → Text, image, XML columns (type 2)
  ROW_OVERFLOW  → Varchar rows > 8060 bytes (type 3)
```

### Why index_id IN (0, 1) Filter?

```
sys.partitions rows per table:
  index_id = 0  → Heap table data (no clustered index)
  index_id = 1  → Clustered index data (common case)
  index_id = 2  → Non-clustered index #1  ← SKIP! Double counting!
  index_id = 3  → Non-clustered index #2  ← SKIP!
  ...

Without the filter:  TotalRows = 31465 × 4 = 125860 (WRONG!)
With the filter:     TotalRows = 31465 (CORRECT)
```

---

<!-- SLIDE 40 — Advanced SQL Concepts Summary -->
## ⚙️ Slide 40: Advanced SQL Concepts in This Framework

### CTEs (Common Table Expressions)

```sql
-- Pattern: WITH name AS ( subquery ) SELECT ...
-- Benefit: Named, reusable subquery — readable and maintainable
-- Alternative: Nested subqueries (harder to read and debug)

WITH A AS (...), B AS (...), C AS (...)
SELECT ... FROM A LEFT JOIN B ... LEFT JOIN C ...
-- Each CTE can reference previous CTEs!
```

### Window Functions

```sql
-- Pattern: aggregate() OVER (PARTITION BY ... ORDER BY ...)
-- Benefit: Row-level aggregation WITHOUT collapsing rows

COUNT(*) OVER (PARTITION BY r.object_id)
-- Returns: the total FK count for each referenced table
-- Every row KEEPS its own data PLUS gets the group total
-- Unlike GROUP BY which COLLAPSES rows into one per group
```

### Metadata Joins Pattern

```
Strategy: Always join on object_id + column_id pairs
  sys.tables.object_id      = sys.columns.object_id
  sys.columns.user_type_id  = sys.types.user_type_id
  sys.indexes.object_id     = sys.index_columns.object_id
             + index_id       + index_id

Golden Rule: Never assume column names are unique.
             Always join on system IDs, not names.
```

---

<!-- SLIDE 41 — Architecture Patterns Comparison -->
## ⚙️ Slide 41: Architecture Patterns Comparison

### Ad-Hoc Querying vs Metadata Engineering

```
AD-HOC QUERYING (What most analysts do):
──────────────────────────────────────────────────────
  Q: "How many rows in Customer table?"
  A: SELECT COUNT(*) FROM Sales.Customer;
  
  Q: "What tables have a Customer FK?"
  A: (manually browse Object Explorer for 20 minutes)
  
  Q: "What date columns are available?"
  A: (look at each table's design individually)

  Result: 2 hours of exploration per database

METADATA ENGINEERING (What this framework teaches):
──────────────────────────────────────────────────────
  Run Q1–Q3: Complete landscape in 60 seconds
  Run Q4–Q6: Full topology in 60 seconds
  Run Q7:    Unified dashboard in 30 seconds
  Run Q8–Q11: Complete documentation in 90 seconds
  
  Result: Total database understanding in ~5 minutes
          Repeatable across ANY SQL Server database
```

### Maturity Scale

```
Level 1 — Manual Explorer:   "Let me click around and see"
Level 2 — Query Writer:      "Let me SELECT * and filter"
Level 3 — Metadata Reader:   "Let me query sys.tables"
Level 4 — Metadata Engineer: "Let me build a metadata pipeline"
Level 5 — Catalog Architect: "Let me build Apache Atlas/DataHub"

★ This framework puts you at Level 4 ★
```

---

<!-- SLIDE 42 — Graph Theory in Relational Databases -->
## ⚙️ Slide 42: Graph Theory in Relational Databases

### Why Databases Are Graphs

```
GRAPH THEORY CONCEPT → DATABASE EQUIVALENT
─────────────────────────────────────────────────────────
  Node (Vertex)       → Table
  Directed Edge       → Foreign Key constraint
  In-degree           → IncomingFKs (referenced by others)
  Out-degree          → OutgoingFKs (references others)
  Hub node            → High in-degree → Dimension table
  Leaf node           → High out-degree → Fact table
  Isolated node       → Standalone table (no FKs)
  Bridge node         → Equal in/out → Junction table
```

### Practical Graph Analysis

```
Q4 Query IS a graph analysis query:
  1. Build adjacency list (FK relationships)
  2. Calculate node degrees (in/out FK counts)
  3. Classify nodes by degree pattern

This is EXACTLY what graph databases (Neo4j, Amazon Neptune) do
— we're doing it inside SQL Server!

Real-world application:
  ● Data lineage graphs in dbt
  ● Table dependency graphs in Apache Airflow
  ● Impact analysis graphs in Collibra
  ● ERD auto-generation in DBML tools
```

> 💡 **Key Insight:** Understanding FK topology as a graph problem
> is a transferable skill to data engineering tools beyond SQL.

---

<!-- ══════════════════════════════════════════════════════════ -->
<!-- WRAP-UP  (Slides 43–45)                                   -->
<!-- ══════════════════════════════════════════════════════════ -->

## 🎓 Slide 43: Complete 4-Phase Workflow Visual

### The End-to-End Metadata Exploration Playbook

```
┌─────────────────────────────────────────────────────────────┐
│                  NEW DATABASE ENCOUNTERED                   │
└──────────────────────────┬──────────────────────────────────┘
                           │
                    (10 minutes)
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  🔵 PHASE 1: DISCOVERY                                      │
│  Q1 → Schema map (6 schemas, 75 tables)                    │
│  Q2 → Table sizes (fact vs dim candidates)                 │
│  Q3 → Customer analytics finder (17 tables)               │
└──────────────────────────┬──────────────────────────────────┘
                    (10 minutes)
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  🟢 PHASE 2: TOPOLOGY                                       │
│  Q4 → Hub/spoke roles (Customer=Hub, Orders=Spoke)         │
│  Q5 → FK density map (Person most referenced)             │
│  Q6 → Temporal anchors (OrderDate = primary grain)        │
└──────────────────────────┬──────────────────────────────────┘
                    (5 minutes)
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  🟣 PHASE 3: INTEGRATION                                    │
│  Q7 → Unified metadata dashboard (all tables scored)      │
└──────────────────────────┬──────────────────────────────────┘
                    (30 minutes)
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  🟠 PHASE 4: DOCUMENTATION                                  │
│  Q8  → PK identification                                   │
│  Q9  → FK relationship map → ERD edges                    │
│  Q10 → Column types → data profiling                      │
│  Q11 → Data dictionary → documentation artifacts          │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
              ✅ ERD COMPLETE + DATA DICTIONARY GENERATED
              ✅ Ready for star schema design
              ✅ Ready for Power BI semantic model
              ✅ Ready for dbt project setup
```

---

<!-- SLIDE 44 — Key Technical Concepts Extraction Table -->
## 🎓 Slide 44: Key Technical Concepts Reference Table

| Concept | Query | Description | Skill Level |
|---------|-------|-------------|-------------|
| `sys.schemas` | Q1 | Schema-level metadata | ⭐ Beginner |
| `sys.tables` | Q1–Q11 | Table-level metadata | ⭐ Beginner |
| `LEFT JOIN` on catalogs | Q1 | Include empty containers | ⭐⭐ Intermediate |
| `HAVING` vs `WHERE` | Q1 | Filter aggregated results | ⭐⭐ Intermediate |
| `sys.partitions` | Q2 | Storage layer access | ⭐⭐ Intermediate |
| `sys.allocation_units` | Q2 | Space calculation | ⭐⭐ Intermediate |
| 8KB page formula | Q2 | `pages × 8 / 1024` | ⭐⭐ Intermediate |
| `CASE` + `LIKE` | Q3 | Semantic pattern matching | ⭐⭐ Intermediate |
| CTE architecture | Q4, Q7 | Named temp result sets | ⭐⭐⭐ Advanced |
| Bidirectional FK joins | Q4 | Graph in-degree/out-degree | ⭐⭐⭐ Advanced |
| Window `COUNT OVER` | Q5 | Row-level aggregation | ⭐⭐⭐ Advanced |
| `sys.types` date filter | Q6 | Type-based column search | ⭐⭐ Intermediate |
| `STRING_AGG` | Q7 | Concatenate within group | ⭐⭐⭐ Advanced |
| `ISNULL` on joins | Q7 | Null-safe LEFT JOINs | ⭐⭐ Intermediate |
| `sys.key_constraints` | Q8 | PK constraint access | ⭐⭐⭐ Advanced |
| `sys.index_columns` | Q8 | Composite key ordinal | ⭐⭐⭐ Advanced |
| `sys.foreign_key_columns` | Q9 | Column-level FK mapping | ⭐⭐⭐ Advanced |
| Referential actions | Q9 | CASCADE/NO ACTION behavior | ⭐⭐⭐ Advanced |
| `sys.extended_properties` | Q11 | Business metadata layer | ⭐⭐⭐⭐ Expert |
| Metadata mart pattern | Q7, Q11 | Multi-layer metadata join | ⭐⭐⭐⭐ Expert |

---

<!-- SLIDE 45 — Portfolio Impact & Next Steps -->
## 🎓 Slide 45: Portfolio Impact Statement & Next Steps

```
╔══════════════════════════════════════════════════════════════╗
║  🏆  WHAT YOU'VE BUILT                                      ║
║                                                              ║
║  A Metadata Intelligence Framework that:                    ║
║                                                              ║
║  ✅ Discovers database landscape in < 10 minutes            ║
║  ✅ Maps FK topology using graph theory principles          ║
║  ✅ Identifies temporal anchors for time-series analytics   ║
║  ✅ Generates unified metadata dashboard (Q7)               ║
║  ✅ Auto-generates ERD-ready relationship maps              ║
║  ✅ Produces data dictionary from system catalogs           ║
║  ✅ Scopes to business-question-driven table selection      ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

### What This Signals to Employers

```
Most data analysts show:  "I built a Power BI dashboard"
You show:                 "I designed the analytical system
                           that powers the dashboard"

Skills demonstrated:
  ✦ Metadata engineering (not just querying)
  ✦ Dimensional modeling thinking
  ✦ SQL Server internals knowledge
  ✦ Graph theory application
  ✦ Documentation automation
  ✦ Business-question-driven architecture
```

### Your Next Steps

```
IMMEDIATE (this week):
  1. Run all 11 queries on AdventureWorks 2025
  2. Export Q11 output to Markdown data dictionary
  3. Build the ERD in dbdiagram.io using Q9 output

SHORT-TERM (next month):
  4. Apply this framework to a new database
  5. Extend Q11 to all 75 tables (remove WHERE clause)
  6. Build Power BI semantic model using Q10 output

LONG-TERM (next quarter):
  7. Build dbt project on top of this ERD
  8. Create Python wrapper for Q1–Q11 automation
  9. Write a blog post: "Building a Metadata Catalog with Pure SQL"
```

---

## 📚 Appendix: Resources & References

### SQL Server System Catalog Views Reference

| View | Description |
|------|-------------|
| `sys.schemas` | Database schemas |
| `sys.tables` | User-defined tables |
| `sys.columns` | Table columns |
| `sys.types` | Data types |
| `sys.partitions` | Table/index partitions |
| `sys.allocation_units` | Storage allocation |
| `sys.foreign_keys` | FK constraint objects |
| `sys.foreign_key_columns` | FK column-level mappings |
| `sys.key_constraints` | PK and UNIQUE constraints |
| `sys.indexes` | Table index structures |
| `sys.index_columns` | Columns in each index |
| `sys.extended_properties` | Custom metadata annotations |

### Related Project Files

- `sql/phase_2_task_1_metadata_explorqtion.sql` — All 11 queries
- `sql/phase_2_task_4_customer_analytics_erd.dbml` — Final ERD
- `docs/phase_2_task_2_table_selection_methodolgy.md` — Table selection guide
- `docs/phase_2_task_3_customer_analytics_data_dictionary.md` — Data dictionary

### Conversion Instructions (Markdown → PPTX)

1. **Marp (CLI):** `npx @marp-team/marp-cli phase2-metadata-exploration-guide.md --pptx`
2. **Slidev:** Copy slide content into Slidev project structure
3. **Reveal.js:** Use `---` separators as slide breaks
4. **Google Slides:** Paste section content manually, one `---` per slide
5. **PowerPoint:** Use "Insert → Slides from Outline" feature with this file

---

*Generated for: AdventureWorks 2025 End-to-End Customer Analytics Project*
*Author: Azab Basha | Phase 2 Task 1 | May 2026*
