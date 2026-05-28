# Bronze SSIS ETL Pipeline

<img width="1172" height="511" alt="ssis_package" src="https://github.com/user-attachments/assets/cc555201-3bc7-4dae-9ea3-921f67f2d057" />

## Overview
This SSIS package is part of the **AdventureWorks2025 Customer Analytics Data Warehouse** project.

It is responsible for loading data from the OLTP source system into the **Bronze Layer** of the data warehouse using a **metadata-driven ETL approach**.

Instead of hardcoding table-by-table loads, the pipeline dynamically reads from a control table:

- `dbo.etl_bronze_table_mapping`

This enables scalable, reusable, and maintainable ETL execution.

---

## ETL Architecture

The Bronze ETL process follows this design:

1. Read mapping configuration from `etl_bronze_table_mapping`
2. Loop through active table mappings (SSIS Foreach Loop Container)
3. Execute a generic stored procedure:
   - `dbo.proc_load_bronze_table`
4. Load data from OLTP → Bronze tables
5. Append ETL audit column (`dwh_load_date`)

---

## Key Components

### 1. Mapping Table (Control Table)
Defines source-to-target relationships:

- Source Schema
- Source Table
- Destination Schema
- Destination Table
- Load Order
- Active Flag

---

### 2. Stored Procedure (Core Loader)
The package uses:

- `dbo.proc_load_bronze_table`

This procedure:
- Truncates the target bronze table
- Loads all data from source table
- Adds ETL audit column (`dwh_load_date`)

---

### 3. SSIS Control Flow Design

- Foreach Loop Container iterates over mapping table
- Executes SQL Task calls stored procedure
- Variables dynamically pass schema/table names

---

## Data Flow Strategy

- Full load (TRUNCATE + INSERT)
- No transformations in Bronze layer
- Schema remains identical to OLTP source
- Used only for raw ingestion and historical capture

---

## Benefits of This Approach

- ✔ Scalable (new tables require only mapping entry)
- ✔ Reusable (single SSIS package handles all tables)
- ✔ Maintainable (no hardcoded pipelines)
- ✔ Metadata-driven orchestration
- ✔ Easy to extend to Silver/Gold layers

---

## Author
Amr Basha  
2026

---

## Notes
This pipeline represents the **Bronze Layer ingestion stage** of a modern Medallion Architecture (Bronze → Silver → Gold).
