# AdventureWorks2025 End-to-End Customer Analytics

![SQL](https://img.shields.io/badge/SQL-Language-blue)
![SQL Server](https://img.shields.io/badge/SQL%20Server-Microsoft-red?logo=microsoftsqlserver&logoColor=white)
![SSIS](https://img.shields.io/badge/SSIS-ETL-purple)
![Star Schema](https://img.shields.io/badge/Data%20Model-Star%20Schema-orange)
![Power BI](https://img.shields.io/badge/Power%20BI-Visualization-F2C811?logo=powerbi&logoColor=black)
![DAX](https://img.shields.io/badge/DAX-KPIs-orange)
![Python](https://img.shields.io/badge/Python-Predictive%20Analytics-yellow?logo=python&logoColor=blue)
![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)

A customer-centric end-to-end analytics project built on the **AdventureWorks2025 OLTP database**.  
This repository documents the full journey from **operational source exploration** to **data warehouse engineering**, **dimensional modeling**, **Power BI analytics**, and **Python-based predictive analysis**.

The project is designed to support customer analytics use cases such as:

- customer behavior analysis
- customer segmentation
- purchasing pattern analysis
- revenue and profitability tracking
- predictive customer intelligence
- executive and analytical dashboarding

---

## Project Objective

The goal of this project is to build a modern analytics solution that transforms raw OLTP data into a business-ready analytical platform.

The solution follows a layered architecture:

- **Bronze** → raw ingestion from source
- **Silver** → cleansed and transformed analytical layer
- **Gold** → dimensional star schema for reporting and advanced analytics

This foundation will then feed:

- **OLAP / semantic modeling**
- **Power BI dashboards**
- **DAX KPI frameworks**
- **Python predictive models**
- **predictive output tables integrated back into the warehouse**

---

## Current Progress

### Completed so far

#### 1. Business and Analytics Foundation
- Defined business understanding and analytical requirements
- Established customer analytics project scope
- Identified core business questions and analytical goals

#### 2. Source Discovery and Planning
- Explored the AdventureWorks2025 OLTP source system
- Performed metadata-driven table selection methodology
- Built a customer analytics data dictionary
- Defined naming convention standards

#### 3. Data Warehouse Engineering
- Created the initial warehouse database structure
- Built the **Bronze layer**
- Configured metadata-driven table mapping for ingestion
- Developed reusable Bronze load stored procedures
- Implemented **Bronze layer row count validation**

#### 4. SSIS Orchestration
- Built a **metadata-driven SSIS Bronze ETL pipeline**
- Used a control table to dynamically manage source-to-target mappings
- Implemented scalable ingestion logic through reusable ETL design

#### 5. Silver Layer Development
- Performed Bronze layer exploratory data analysis
- Designed and created the **Silver layer DDL**
- Built Silver transformation/load procedure(s)
- Added Silver layer validation checks

#### 6. Gold Layer Development
- Performed analytical SQL validation
- Designed and created the **Gold star schema**
- Built and populated the **Date dimension**
- Developed Gold layer load procedure(s)
- Added Gold layer validation logic

---

## Repository Structure

```text
.
├── docs/
│   ├── phase_1_business_understanding_and_analytical_requirements.md
│   ├── phase_2_task_2_table_selection_methodolgy.md
│   ├── phase_2_task_3_customer_analytics_data_dictionary.md
│   ├── phase_3_task_1_naming_convention_standards.md
│   └── presentations/
│
├── sql/
│   ├── 1_source_discovery/
│   ├── 2_warehouse_etl-bronze/
│   │   ├── phase_3_task_2_initial_database_creation.sql
│   │   ├── phase_3_task_3_brozne_layer_ddl.sql
│   │   ├── phase_3_task_4_bronze_table_mapping_configuration.sql
│   │   ├── phase_3_task_5_proc_load_bronze_layer.sql
│   │   └── phase_3_task_7_bronze_row_count_validation.sql
│   │
│   ├── 3_data_warehouse_etl-silver/
│   │   ├── phase_4_task_1_bronze_layer_eda.sql
│   │   ├── phase_4_task_2_silver_layer_ddl.sql
│   │   ├── phase_4_task_3_proc_load_silver_layer.sql
│   │   └── phase_4_task_4_silver_row_count_validation.sql
│   │
│   └── 4_data_warehouse_etl-gold/
│       ├── phase_5_task_1_analytical_sql_validation.sql
│       ├── phase_5_task_2_gold_star_schema_ddl.sql
│       ├── phase_5_task_3_populate_dim_date.sql
│       ├── phase_5_task_4_proc_load_gold_layer.sql
│       └── phase_5_task_5_gold_layer_validation.sql
│
├── ssis/
│   ├── README.md
│   └── phase_3_task_6_bronze_ssis_pipeline/
│
├── README.md
└── LICENSE
```

---

## Architecture Overview

### 1. OLTP Source
The AdventureWorks2025 transactional database acts as the operational source system.

### 2. Bronze Layer
The Bronze layer ingests raw source data with minimal transformation and preserves source structure for downstream processing.

### 3. Silver Layer
The Silver layer standardizes, cleans, and prepares data for analytics-oriented modeling.

### 4. Gold Layer
The Gold layer contains the **customer-centric star schema** used for reporting, KPI calculations, and advanced analytics.

### 5. Next Integrated Analytics Layer
The next stage of the project will extend the warehouse into a broader analytical ecosystem with:

- OLAP / semantic modeling
- Power BI reporting layer
- DAX measures and KPI calculations
- Python-based predictive modeling
- predictive outputs written back into the warehouse
- Power BI predictive dashboards powered by warehouse + model outputs

---

## Next Roadmap

### Phase 6 — OLAP / Semantic Modeling
Planned next steps include:
- building the analytical semantic layer on top of the Gold schema
- defining business-friendly measures and hierarchies
- optimizing the model for dashboard consumption
- preparing the model for KPI-driven reporting

### Phase 7 — Power BI Dashboard Development
Planned dashboard work includes:
- executive customer overview dashboards
- sales and revenue analysis
- customer segmentation dashboards
- cohort and retention analysis
- product affinity / behavioral analysis
- predictive insight visualizations

### Phase 8 — DAX KPI Layer
Planned KPI work includes:
- revenue KPIs
- customer lifetime value indicators
- repeat purchase metrics
- recency / frequency / monetary metrics
- churn-risk indicators
- customer growth and retention KPIs

### Phase 9 — Python-Based Predictive Analytics
Planned data science work includes:
- feature engineering from warehouse data
- customer segmentation enhancement
- predictive scoring models
- behavioral analysis modeling
- purchase propensity / risk modeling
- exporting model outputs back into the warehouse

### Phase 10 — Predictive Output Integration
An additional table will be added to the **Gold star schema** to store **BYTD / predictive outputs** so they can be synchronized with:

- the warehouse
- the OLAP / semantic model
- Power BI dashboards

This will allow predictive insights to become part of the final business-facing reporting layer.

---

## Tech Stack

- **SQL Server**
- **T-SQL**
- **SSIS**
- **Dimensional Modeling**
- **Star Schema Design**
- **Power BI**
- **DAX**
- **Python**
- **Excel**

---

## Key Design Principles

- metadata-driven ingestion
- reusable ETL procedures
- layered warehouse architecture
- validation at each warehouse stage
- customer-centric dimensional modeling
- analytics-ready schema design
- future-ready integration with machine learning outputs

---

## Current Status

**Warehouse build is complete through the Gold layer foundation.**  
The project is now moving into the next major stage:

- OLAP / semantic modeling
- dashboard development in Power BI
- predictive analytics in Python
- integration of predictive outputs into the Gold analytical layer

This repository is under active development and will continue expanding as each phase is completed.

---

## Future Additions to the Repository

- star schema diagrams
- OLAP / semantic model documentation
- Power BI dashboard screenshots
- DAX measure documentation
- Python notebooks for predictive modeling
- predictive output table design
- end-to-end architecture diagrams
- final portfolio-ready business walkthrough

---

## Author

### Amr Basha
Microsoft Certified Data Analyst | Power BI Developer | Customer Analytics Enthusiast

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Profile-blue?logo=linkedin&logoColor=white)](https://www.linkedin.com/in/azab-basha-552912289)
[![GitHub](https://img.shields.io/badge/GitHub-Profile-black?logo=github&logoColor=white)](https://github.com/settings/profile)
[![Microsoft Certification](https://img.shields.io/badge/Microsoft-PL--300%20Certified-0078D4?logo=microsoft&logoColor=white)](https://learn.microsoft.com/api/credentials/share/en-gb/AmrBasha-6771/9EADE87E2384B4FE?sharingId=2CD8A1FA31271217)

---

> This repository will be continuously updated as the project progresses from warehouse engineering into semantic modeling, dashboarding, and predictive analytics.
