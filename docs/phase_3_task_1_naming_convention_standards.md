
# **Naming Conventions**

This document outlines the naming conventions used for schemas, tables, views, columns, SSIS packages, SQL scripts, and other objects in the data warehouse for the AdventureWorks 2025 project.

---

**📅 Document Created**: May 2026 
**👤 Author**: Azab Basha  
**🏢 Project**: AdventureWorks End-to-End Customer Analytics  
**📂 Phase**: Phase 3 Task 1 Naming Convention Standards


---

## 📋 Table of Contents

- [General Principles](#-general-principles)  
- [Table Naming Conventions](#-table-naming-conventions)  
  - [Bronze Rules](#-bronze-rules)  
  - [Silver Rules](#-silver-rules)  
  - [Gold Rules](#-gold-rules)  
- [Column Naming Conventions](#-column-naming-conventions)  
  - [Natural / Business Keys](#natural--business-keys)  
  - [Surrogate Keys](#surrogate-keys)  
  - [SCD & History Columns](#scd--history-columns)  
  - [Technical / Audit Columns](#technical--audit-columns)  
- [Stored Procedures & Scripts](#-stored-procedure--script-naming)  
- [SSIS Package & Project Naming](#-ssis-package--project-naming)  
- [Files & Artifacts (SQL, Models, Reports)](#-files--artifacts-sql-models-reports)  
- [Examples: AdventureWorks → DWH mappings](#-examples-adventureworks--dwh-mappings)

---

## 🎯 General Principles

- Use English for all object names.  
- Use snake_case (lowercase + underscores) for all database objects, files and variables.  
- Avoid SQL reserved words.  
- Be consistent: choose the convention and apply it across schemas, scripts, SSIS projects, and reports.  
- Keep names readable and business-focused at the Gold layer; keep source fidelity in Bronze.

---

## 🗂️ Table Naming Conventions

### Bronze Rules
- Bronze retains source-system fidelity: table names include a short source prefix and the original schema + table name.
- Pattern:
  - `<src>_<schema>_<table>`
  - `<src>` = source system short code (use `aw` for AdventureWorks 2025)
  - `<schema>` = original OLTP schema (sales, person, production, etc.)
  - `<table>` = original table name (use the exact table name from the OLTP)
- Examples:
  - `aw_sales_customer` → Sales.Customer from AdventureWorks
  - `aw_person_person` → Person.Person
  - `aw_sales_salesorderheader` → Sales.SalesOrderHeader
- Bronze objects should be stored in a `bronze` schema (e.g., `bronze.aw_sales_customer`) in the DWH instance so the physical object name and the schema both make provenance explicit.

### Silver Rules
- Silver contains cleansed/conformed copies; names still preserve source origin.
- Pattern:
  - `<src>_<schema>_<table>`
  - Place in `silver` schema.
- Keep the original table name for traceability, but you may add a suffix when versioning (e.g., `_v1`) if needed for migration testing.
- Examples:
  - `silver.aw_sales_salesorderdetail`
  - `silver.aw_production_product`

### Gold Rules
- Gold uses business-friendly names, designed for analytics and semantic modeling.
- Pattern:
  - `<category>_<entity>` where `<category>` is `dim`, `fact`, `bridge`, `report`, etc.
- Entities should be descriptive and aligned to business language.
- Examples:
  - `dim_customers` (customer master for analytics)
  - `dim_person` (person-level attributes if needed separately)
  - `fact_sales_order_line` (order line-level sales fact)
  - `fact_sales_order` (order-level aggregated fact)
  - `bridge_order_reason` (order ↔ sales_reason M:N)
- Gold objects live in the `gold` schema (e.g., `gold.dim_customers`).

#### Glossary of Category Patterns
| Pattern   | Meaning            | Example |
|-----------|--------------------|---------|
| `dim_`    | Dimension table    | `dim_customers` |
| `fact_`   | Fact table         | `fact_sales_order_line` |
| `bridge_` | Many-to-many bridge| `bridge_customer_address` |
| `report_` | Report-ready table | `report_monthly_revenue` |

---

## 🧾 Column Naming Conventions

### Natural / Business Keys
- Use `<entity>_id` for natural keys coming from source systems.
  - Example: `customer_id` maps to Sales.Customer.CustomerID
  - Example: `business_entity_id` maps to Person.Person.BusinessEntityID

### Surrogate Keys
- Surrogate keys in dimensions use the `_key` suffix.
  - Pattern: `<table_or_entity>_key`
  - Example: `customer_key` for `dim_customers` (INT, identity)
- Surrogate keys should be integers where possible for performance.

### SCD & History Columns
- For SCD2 (historical) dimensions include:
  - `effective_from` (datetime) — when the row became effective
  - `effective_to` (datetime) — when the row was superseded (NULL = current)
  - `is_current` (bit) — 1 = current version, 0 = historical
  - `record_source` (varchar) — source identifier (e.g., `aw.sales.customer`)
- If you have a need for micro-versioning, include `version_number` (int).

### Technical / Audit Columns
- Prefix all system-managed metadata with `dwh_`.
- Recommended technical columns:
  - `dwh_load_date` (datetime) — when row was loaded/processed into this layer
  - `dwh_batch_id` (varchar) — ingestion batch identifier
  - `dwh_record_hash` (varchar) — optional: hash of business columns used for quick change detection
  - `dwh_validation_status` (varchar) — `valid`, `invalid`, `warning` (for DQ results)
  - `dwh_updated_at` (datetime) — last time ETL touched this record (useful for auditing)
- Example:
  - `dwh_load_date`, `dwh_batch_id`, `dwh_record_source`, `dwh_validation_status`

---

## 🛠️ Stored Procedure & Script Naming

### Stored Procedures
- Pattern:
  - `proc_<action>_<layer>_<entity>`
  - `<action>` = `load`, `merge`, `validate`, `purge`, `archive`
  - `<layer>` = `bronze`, `silver`, `gold`
  - `<entity>` = short entity name
- Examples:
  - `proc_load_bronze_aw_sales_salesorderheader`
  - `proc_merge_gold_dim_customers`
  - `proc_validate_silver_aw_sales_salesorderdetail`

### SQL Script Files
- Pattern for script filenames (git-friendly):
  - `<layer>__<object>__<action>.sql`
  - Use double underscores `__` to separate logical parts
- Examples:
  - `bronze__aw_sales_salesorderheader__create_table.sql`
  - `silver__aw_sales_salesorderheader__upsert.sql`
  - `gold__dim_customers__scd2_merge.sql`

---

## 📦 SSIS Package & Project Naming

Because SSIS is your primary ETL tool, standardize package and project names so they are discoverable and deployable.

### SSIS Project
- Pattern:
  - `etl_<project_scope>`
  - Example: `etl_aw_customer_analytics.dtproj` (project file in Visual Studio)

### SSIS Packages
- Pattern:
  - `<layer>.<src>.<schema>.<table>.<action>.dtsx`
  - Use dots to group logical parts and keep file extension `.dtsx`
- Examples:
  - `bronze.aw.sales.salesorderheader.full_load.dtsx`
  - `bronze.aw.sales.salesorderheader.incremental_load.dtsx`
  - `silver.aw.sales.salesorderheader.cleanse.dtsx`
  - `gold.dim.customers.load_scd2.dtsx`
- Package parameters: Use project parameters for environment values (connection strings, batch window, watermark values).
  - Parameter names: `param_<name>` or `env_<name>` (e.g., `param_db_connection`, `param_watermark_orderdate`)

### SSIS Variables
- Use lowercase + underscores and prefix with package area:
  - `var_batch_id`, `var_last_watermark`, `var_row_count`

### Deployment artifacts
- Store exported `.ispac` files in `etl/deployments/` with naming:
  - `etl_aw_customer_analytics__v1.ispac`

---

## 🗂️ Files & Artifacts (SQL, Models, Reports)

- SQL scripts: place under `sql/` organized by layer: `sql/bronze/`, `sql/silver/`, `sql/gold/`
- SSIS packages: put under `etl/packages/` and include source `.dtsx` plus exported `.ispac` in `etl/deployments/`
- SSAS / Tabular models: store model definition files under `models/` (e.g., `models/ssas/aw_customer_analytics.bim`)
- Power BI: place .pbix files under `reports/powerbi/` with naming pattern:
  - `report_<subject>_<audience>_<vX>.pbix` (e.g., `report_rfm_marketing_v1.pbix`)
- Documentation: store markdown files under `docs/` and reference related artifacts (script names, package names).

---

## 🔁 Examples: AdventureWorks → DWH mappings

- AdventureWorks OLTP: Sales.Customer  
  - Bronze: `bronze.aw_sales_customer`  
  - Silver: `silver.aw_sales_customer` (cleansed / conformed)  
  - Gold: `gold.dim_customers` (business-surrogate keys, SCD2 history)

- AdventureWorks OLTP: Person.Person  
  - Bronze: `bronze.aw_person_person`  
  - Silver: `silver.aw_person_person`  
  - Gold: `gold.dim_person` (if separate person master is required)

- AdventureWorks OLTP: Sales.SalesOrderHeader  
  - Bronze: `bronze.aw_sales_salesorderheader`  
  - Silver: `silver.aw_sales_salesorderheader`  
  - Gold:
    - `gold.fact_sales_order` (order-level aggregations)
    - `gold.fact_sales_order_line` (line-level details: joins to `dim_product`)

- AdventureWorks OLTP: Sales.SalesOrderDetail  
  - Bronze: `bronze.aw_sales_salesorderdetail`  
  - Silver: `silver.aw_sales_salesorderdetail`  
  - Gold: `gold.fact_sales_order_line`

- Column examples (OLTP → Bronze/Silver → Gold):
  - OLTP: `SalesOrderID` → Bronze: `salesorderid` or `sales_order_id` → Gold: `sales_order_id`
  - OLTP: `CustomerID` → Bronze: `customerid` → Silver/Gold: `customer_id` (business key) + `customer_key` (surrogate in dim_customers)

---

## ✅ Quick reference checklist (for new artifacts)

- [ ] Bronze table names use `aw_<schema>_<table>` and live in `bronze` schema.  
- [ ] Silver table names preserve `aw_<schema>_<table>` and live in `silver` schema.  
- [ ] Gold objects use `dim_` / `fact_` / `bridge_` naming and live in `gold` schema.  
- [ ] Surrogate keys use `_key` suffix (INT identity).  
- [ ] All technical metadata columns begin with `dwh_`.  
- [ ] SSIS packages follow `<layer>.<src>.<schema>.<table>.<action>.dtsx` pattern and stored in `etl/packages/`.  
- [ ] SQL scripts follow `<layer>__<object>__<action>.sql` and stored in `sql/<layer>/`.  

---

