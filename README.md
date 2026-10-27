# AdventureWorks2025 End-to-End Customer Analytics

![SQL Server](https://img.shields.io/badge/SQL%20Server-Microsoft-red?logo=microsoftsqlserver&logoColor=white)
![T-SQL](https://img.shields.io/badge/T--SQL-Warehouse-blue)
![SSIS](https://img.shields.io/badge/SSIS-ETL-purple)
![Star Schema](https://img.shields.io/badge/Data%20Model-Star%20Schema-orange)
![Power BI](https://img.shields.io/badge/Power%20BI-Semantic%20Model%20%26%20Dashboards-F2C811?logo=powerbi&logoColor=black)
![DAX](https://img.shields.io/badge/DAX-60%20Measures-orange)
![Python](https://img.shields.io/badge/Python-BTYD%20Modeling-yellow?logo=python&logoColor=blue)
![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)

A customer-centric, end-to-end analytics project built on the **AdventureWorks2025 OLTP database**.
It covers the full journey from **source exploration** to **data warehouse engineering**, **dimensional modeling**, a **Power BI semantic model with DAX**, **interactive dashboards**, and a **Python predictive step** (BTYD models from the Wharton Customer Analytics course) whose results flow back into the warehouse and the dashboards.

The project supports customer analytics use cases such as:

- customer behavior analysis and RFM segmentation
- cohort and retention analysis
- revenue and profitability tracking
- purchase and revenue forecasting, tested honestly against baselines
- executive and analytical dashboarding

---

## Project Objective

Turn raw OLTP data into a business-ready analytical platform using a layered architecture:

- **Bronze**: raw ingestion from the source
- **Silver**: cleansed and transformed analytical layer
- **Gold**: dimensional star schema for reporting and advanced analytics

The Gold layer then feeds:

- a **Power BI semantic model** (relationships and 60 DAX measures)
- **Power BI dashboards**
- **Python BTYD models**, whose outputs are written back to the Gold layer and shown in Power BI

---

## Architecture

```text
AdventureWorks2025 (OLTP)
        │
        ▼
   Bronze  ──  raw copy, metadata-driven SSIS load
        │
        ▼
   Silver  ──  cleansed, standardised, validated
        │
        ▼
    Gold   ──  star schema + customer analytics, cohort and BTYD tables
        │
        ├────────────────────────────┐
        ▼                            ▼
 Power BI semantic model      Python BTYD notebook
 (relationships + DAX)        (reads Gold inputs, writes predictions back)
        │                            │
        └────────────┬───────────────┘
                     ▼
             Power BI dashboards
```

| Layer | Responsibility |
|---|---|
| **OLTP source** | AdventureWorks2025 transactional database |
| **Bronze** | Raw ingestion with minimal transformation, kept for auditing and traceability |
| **Silver** | Standardised, cleaned and validated data ready for modeling |
| **Gold** | Customer-centric star schema: sales facts, RFM metrics, cohort table and BTYD input / prediction / evaluation tables |
| **Semantic model** | Relationships, 60 DAX measures, field parameters and a segment playbook, built in Power BI |
| **Python** | BTYD models (Modified BG/NBD, Gamma-Gamma), baselines, diagnostics and write-back to Gold |
| **Dashboards** | Executive Summary, RFM, Cohort Retention and Customer Forecasting pages |

> **Note on the semantic layer:** the original plan used an SSAS Tabular model. I replaced it with a **Power BI semantic model**, which keeps the model, the DAX measures and the report in one tool and is the layer the dashboards actually use.

---

## Project Phases

| Phase | Topic | Status |
|---|---|---|
| 1 | Business understanding and analytical requirements | ✅ Done |
| 2 | Source discovery, table selection and data dictionary | ✅ Done |
| 3 | Warehouse setup, Bronze layer and SSIS pipeline | ✅ Done |
| 4 | Silver layer | ✅ Done |
| 5 | Gold star schema and load procedure | ✅ Done |
| 6 | Power BI semantic model and DAX measures | ✅ Done |
| 7 | Power BI dashboards | ✅ Done |
| 8 | Python BTYD predictive modeling | ✅ Done |
| 9 | Predictive output integration (write-back to Gold and Power BI) | ✅ Done |

---

## Semantic Model (Phase 6)

A multi-fact star schema in Power BI: **17 tables, 14 relationships, 60 DAX measures in 6 display folders and 2 field parameters.**

| Display folder | Measures |
|---|---|
| Sales & Profitability | 11 |
| Time Intelligence | 4 |
| Reference Cards (YoY, arrows, colours) | 17 |
| RFM Analysis | 11 |
| Cohort | 12 |
| BTYD | 5 |

📁 Full documentation, model diagram and the complete DAX file: [`06_semantic_modeling/`](06_semantic_modeling/)

---

## Python BTYD Modeling (Phase 8 and 9)

I applied the BG/NBD and Gamma-Gamma models from the Wharton Customer Analytics course (Fader and Hardie) to 16,300 customers, using a calibration period and a 90-day holdout, then **tested the results against simple baselines instead of trusting the totals**.

### What I found

| Check | Result |
|---|---|
| Purchases, 90-day holdout | 2,655 predicted vs 2,475 actual (+7.3%) |
| Beats a "same rate for everyone" baseline? | No: that baseline is +9.3% off on the total |
| Per-customer error vs each customer's own historical rate | Model is worse (MAE 0.267 vs 0.232) |
| Ranking of customers (Spearman) | -0.135 |
| `p_alive` (probability a customer is still active) | Collapsed to 1.0 for all 16,300 customers across four model variants |
| Revenue, 90-day holdout | $9.20M predicted vs $5.64M actual (+63%) |

### Why, and what I did about it

- **Dropout could not be estimated.** Few repeat buyers look "gone", so the optimizer concludes nobody leaves. I documented every fix I tried (BG/NBD, weeks instead of days, Pareto/NBD, repeat buyers only) and chose not to fake a probability.
- **Tenure drives purchasing, and BG/NBD cannot see it.** One-time buyers older than a year bought again at about 61%, versus about 8% for newer ones, so the model ranked the best group lowest.
- **Gamma-Gamma's assumption was violated.** Frequency and order value are correlated (0.43), which inflated the revenue forecast.
- **The replacement is transparent:** a rule-based customer status (One-Time Buyer, Active, Cooling, Lapsed Repeat), tested and shown to carry no predictive signal here. `p_alive` is stored as NULL on purpose.

AdventureWorks is synthetic data, so the method and the pipeline are the point, not the business conclusions.

📁 Notebook, explainer and details: [`python/`](python/)

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
│   ├── 3_data_warehouse_etl-silver/
│   └── 4_data_warehouse_etl-gold/
│
├── ssis/
│   ├── README.md
│   └── phase_3_task_6_bronze_ssis_pipeline/
│
├── semantic_modeling/      ← Power BI semantic model: README, diagram, 60 DAX measures
├── power_bi/                  ← dashboard pages and screenshots
├── btyd_python/                    ← BTYD notebook and explainer
│
├── README.md
└── LICENSE
```

---

## How to Reproduce

1. **Database:** run the scripts in `sql/` in order (source discovery, Bronze, Silver, Gold).
2. **Bronze load:** run the SSIS package in `ssis/` (set its connection manager to your server).
3. **Silver and Gold:** run the load procedures (`proc_load_silver_layer`, then `gold.sp_load_complete_datawarehouse`).
4. **Python:**
   - install: `pip install lifetimes pandas numpy matplotlib sqlalchemy pyodbc`
   - set your server name once: `setx SQL_SERVER "YOUR_SERVER\INSTANCE"` (Windows), then restart Jupyter
   - requires the *ODBC Driver 17 for SQL Server*
   - run the notebook in `python/` from top to bottom; it writes predictions back to Gold
5. **Power BI:** open the report, point the data source to your server and refresh.

> The Gold load procedure empties the BTYD output tables and reloads them from staging tables the notebook writes, so running the warehouse refresh after the notebook does not lose the predictions.

---

## 📖 Project Documentation

The GitHub repository focuses on the implementation. For the complete roadmap, architecture diagrams, business requirements, design decisions and detailed technical documentation, visit the Notion workspace.

[![Notion](https://img.shields.io/badge/Notion-Project%20Workspace-black?logo=notion&logoColor=white)](https://app.notion.com/p/adventureworks_end_to_end_customer_analytics_project-2fb5c6a547688018a4c1ceeb6af81e0b)

---

## Tech Stack

- **SQL Server**, **T-SQL**
- **SSIS**
- **Dimensional modeling and star schema design**
- **Power BI** (semantic model and dashboards)
- **DAX**
- **Python** (`numpy`,`pandas`, `lifetimes`, `SQLAlchemy`, `matplotlib`)
- **Excel**

---

## Key Design Principles

- metadata-driven ingestion
- reusable ETL procedures
- layered warehouse architecture
- validation at each warehouse stage
- customer-centric dimensional modeling
- business logic in the semantic model, not in visuals
- predictions written back to the warehouse so one source of truth feeds every report
- honest evaluation: every model is tested against simple baselines, and limits are documented

---

## Next Steps

- supervised challenger model that includes customer tenure, scored on a later cutoff than it is trained on
- PyMC-Marketing with priors (the maintained successor to `lifetimes`)
- true forward forecast with an observation date after the latest order
- run log and current-run view in Gold to monitor prediction drift

---

## Author

### Amr Basha
Microsoft Certified Data Analyst | Power BI Developer | Customer Analytics Enthusiast

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Profile-blue?logo=linkedin&logoColor=white)](https://www.linkedin.com/in/amr-basha-552912289)
[![GitHub](https://img.shields.io/badge/GitHub-Profile-black?logo=github&logoColor=white)](https://github.com/Amr-Bayoumy-Basha)
[![Microsoft Certification](https://img.shields.io/badge/Microsoft-PL--300%20Certified-0078D4?logo=microsoft&logoColor=white)](https://learn.microsoft.com/api/credentials/share/en-gb/AmrBasha-6771/9EADE87E2384B4FE?sharingId=2CD8A1FA31271217)

---

> Dataset: Microsoft AdventureWorks (synthetic). Course reference: Wharton Customer Analytics (Coursera); Fader, Hardie and Lee (2005).
