# 📊 BTYD Model Notebook Explainer (`btyd_model.ipynb`)

This document explains the purpose, logic, modeling decisions, and production outputs of the **BTYD (Buy Till You Die)** notebook implementation in this project.

---

## 1) 🎯 Objective

The notebook builds a **predictive Customer Lifetime Value (CLV) framework** that estimates:

- Probability a customer is still active (`p_alive`)
- Expected future purchases (30-day and 90-day horizons)
- Expected future revenue
- Actionable customer segments for retention/growth strategy

It is designed for deployment with the **AdventureWorks customer analytics warehouse** and supports direct downstream BI consumption.

---

## 2) 🏗️ End-to-End Data Flow

The notebook sits in a broader medallion-style pipeline:

1. **Silver Layer**  
   Cleaned transactional records and mapped customer identities.

2. **Gold Input Layer**  
   Prepared BTYD feature table (`gold.fact_customer_btyd_inputs`) with:
   - `frequency`
   - `recency`
   - `T`
   - `monetary_value`
   - holdout metrics for evaluation

3. **Python Modeling Layer (`btyd_model.ipynb`)**
   - MBG/NBD for transaction behavior
   - Gamma-Gamma for spend estimation
   - fallback logic for numerical/model edge cases

4. **Gold Prediction Output Layer**
   - `gold.fact_customer_btyd_predictions`
   - `gold.fact_customer_btyd_eval`

---

## 3) 🧠 Modeling Components

### A) Transaction Model: Modified BG/NBD

**Library Class:** `ModifiedBetaGeoFitter`  
**Why modified?**  
Standard BG/NBD assumes churn can only happen after repeat behavior starts. In retail reality, many customers are one-time buyers. The **Modified** variant allows dropout starting at time zero, better reflecting acquisition-heavy populations.

Outputs include:
- `p_alive_raw`
- `predicted_purchases_30d`
- `predicted_purchases_90d`

---

### B) Monetary Model: Gamma-Gamma

**Library Class:** `GammaGammaFitter`  
Trained only on customers with:
- `frequency > 0`
- `monetary_value > 0`

This estimates:
- `expected_avg_order_value`

If data is sparse or non-eligible, a robust fallback is used (median-based backfill) to keep revenue predictions stable and prevent pipeline failure.

---

## 4) ⚠️ Engineering Issues Encountered + Fixes

### Issue 1: `p_alive` flattening at ~1.0
- **Symptom:** Little/no variance in survival probabilities.
- **Cause:** Optimization instability due to low repeat density and long customer age horizon.
- **Fix:** Recency-based decay fallback blended with raw model output when variance is too low.

---

### Issue 2: Gamma-Gamma failures for one-time buyers
- **Symptom:** Missing expected order values and downstream errors.
- **Cause:** Gamma-Gamma requires repeat purchase behavior.
- **Fix:** Train on valid subset, then backfill remaining customers with a safe empirical median.

---

### Issue 3: SQL constraint violations (negative tiny floats)
- **Symptom:** Insert failures under strict CHECK constraints.
- **Cause:** Numerical rounding artifacts (e.g., tiny negative scientific notation values).
- **Fix:** Apply `.clip(lower=0.0)` to predictions before database writeback.

---

### Issue 4: SQLAlchemy execution error (`text` not defined / raw SQL handling)
- **Symptom:** Failure at truncate/write boundary.
- **Cause:** SQLAlchemy 2.x requires executable SQL objects.
- **Fix:** `from sqlalchemy import text` and execute SQL via `connection.execute(text(...))`.

---

## 5) 🧮 Derived Business Features

After predictions, the notebook creates strategy-friendly labels:

- **`alive_status`**  
  Bucketed from `p_alive` into:
  - Likely Dead
  - At Risk
  - Active
  - Very Active

- **`value_tier`**  
  Quartile-style segmentation from predicted 90-day revenue:
  - Low / Medium / High / Top

- **`action_segment`**  
  Rule-based recommendation:
  - Win-Back
  - Win-Back High Value
  - Retain & Grow
  - Nurture

These fields bridge statistical output to direct CRM/commercial action.

---

## 6) 🗂️ Output Tables

### `gold.fact_customer_btyd_predictions`
Customer-level scored output:
- survival probability
- future purchases
- future revenue
- segmentation labels
- run identifier

### `gold.fact_customer_btyd_eval`
Model evaluation output:
- actual vs predicted holdout purchases
- actual vs predicted holdout revenue
- absolute error
- percent error metrics

---

## 7) ✅ Validation Snapshot (Current Run)

Observed holdout-level performance in development:

- **Actual holdout purchases:** `2,475`
- **Predicted holdout purchases:** `2,660.47`
- **Volume error:** `~7.49%`
- **MAE per customer:** `0.2658`

This is within typical commercial tolerance thresholds for directional demand/retention planning.

---

## 8) 🚀 Why This Notebook Matters

`btyd_model.ipynb` is not only a modeling prototype; it is a **production-oriented scoring design** with:

- resilient error handling
- numerical safety controls
- database-ready payload formatting
- direct alignment to BI and decision workflows

It transforms raw customer transactions into actionable lifecycle intelligence.

---

## 9) Next Enhancements

Recommended next step:
- Build a **weekly SQL reporting view layer** to track:
  - score drift
  - segment migration
  - prediction error trends
  - run-over-run stability by cohort

This will complete the feedback loop between model scoring and business performance monitoring.
