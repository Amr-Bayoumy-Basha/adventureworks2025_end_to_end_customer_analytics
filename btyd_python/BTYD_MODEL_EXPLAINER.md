# 📊 BTYD Model Notebook Explainer (`btyd_model.ipynb`)

What this notebook does, what it found, and what it deliberately does **not** claim.

---

## 1) 🎯 Objective

Apply the customer-base methods from the Wharton Customer Analytics course (BG/NBD and Gamma-Gamma) to the AdventureWorks warehouse, **test them honestly against simple baselines**, and write the results to the Gold layer for Power BI.

**Result in one paragraph:** the models ran and produced purchase and revenue forecasts, but on this dataset they did not beat simple baselines, they could not estimate customer "death" (`p_alive`), and they misranked customers because buying depends on customer tenure, which BG/NBD cannot represent. Every step and every failed attempt is documented in the notebook.

---

## 2) 🏗️ Data Flow

1. **Silver**: cleaned transactions.
2. **Gold input table** `gold.fact_customer_btyd_inputs`: one row per customer (`frequency`, `recency`, `T`, `monetary_value`, holdout purchases and revenue). History is split into a **calibration period** (the models learn from it) and a 90-day **holdout** (hidden, used only to test).
3. **Python notebook**: fit, validate, diagnose, label.
4. **Gold output tables** `fact_customer_btyd_predictions` and `fact_customer_btyd_eval`, plus `stg_` staging tables so a warehouse refresh restores them.
5. **Power BI**: Customer Forecasting page.

> `observation_date` is the **end of the holdout**. The "90-day forecast" is a **backtest** of a window that has already happened.

---

## 3) 🧠 Models

| Model | Purpose | Assumption |
|---|---|---|
| Modified BG/NBD | Expected purchases | Steady buying rate per customer; customers may "die" after purchases |
| Gamma-Gamma | Expected order value | Order value is unrelated to purchase frequency |

One-time buyers have no order history, so they receive the **median order value of repeat buyers** (an assumption, not a model estimate).

**Gamma-Gamma check:** the correlation between frequency and order value is **0.428**, so the assumption is **violated**. Order-value and revenue forecasts should be read with caution.

---

## 4) ✅ Scorecard on the 90-day Holdout

| Measure | Result |
|---|---|
| Actual purchases | 2,475 |
| Predicted purchases | 2,654.6 |
| Volume error | +7.3% |

### Against simple baselines (built from calibration data only)

| Method | Volume error | MAE | Rank correlation |
|---|---|---|---|
| MBG/NBD model | +7.3% | 0.2667 | -0.135 |
| Each customer's own historical rate | -10.2% | 0.2319 | 0.003 |
| Same rate for everyone | +9.3% | 0.2722 | n/a |

**Reading it:** the model's total is no better than a constant rate, its per-customer error is worse than each customer's own historical rate, and its ranking of customers is negative. **The +7.3% total is not evidence of predictive skill.**

### Lift by prediction decile (1 = lowest predicted)

| Decile | Predicted | Actual |
|---|---|---|
| 1 | 0.094 | **0.566** |
| 2–9 | 0.12 – 0.20 | 0.06 – 0.11 |
| 10 | 0.343 | 0.307 |

The lowest-rated decile produced about **920 of the 2,475** holdout purchases (37%) while the model expected about 150. Errors in other deciles cancelled out, which is why the total looked good.

---

## 5) ⚠️ Problem A: the Dropout Parameters Collapse (`p_alive`)

Every model returned dropout parameters near zero, so `p_alive` was **1.0 for all 16,300 customers**. The model was effectively saying "nobody ever leaves".

| Attempt | Result |
|---|---|
| Modified BG/NBD, days | a = 3.7e-15, b = 1.2e-05, standard errors larger than the estimates |
| BG/NBD, days, penalizer 0.01 | a = 5.1e-22, b = 5.9e-13 |
| BG/NBD, weeks, penalizer 0.05 | ConvergenceError |
| Pareto/NBD, weeks | s = 2.9e-09, `p_alive` std = 5.6e-10 (one unique value) |
| Modified BG/NBD, repeat buyers only | a = 2.7e-14, `p_alive` std = 2.5e-14 |

(`fit_method='L-BFGS-B'` is not a real option in `lifetimes` and was silently ignored, so it tested nothing new.)

### Why
- Among repeat buyers, the median customer has been silent for only **0.34×** their usual gap, and only **9.8%** are more than 2× overdue. Almost nobody looks like they left, so the optimizer concludes nobody leaves.
- **61.5% of customers were acquired in the last three quarters** and make up most one-time buyers. The 64% one-time share largely reflects a young customer base that has had little time to buy again.

### Rejected ideas
- A recency formula blended into `p_alive`: it is a rule, not a probability.
- Typing "stable business prior" parameters into the model: that invents the answer.
- Injecting parameters fitted on repeat buyers only: BG/NBD needs one-time buyers to learn about dropout.

**Decision:** `p_alive` is stored as NULL.

---

## 6) ⚠️ Problem B: Tenure Drives Purchasing (and the Model Can't See It)

Decile 1 is **99.4% one-time buyers with an average tenure of 599 days**. Splitting one-time buyers by how long they have been customers:

| Tenure | Customers | Bought again in holdout |
|---|---|---|
| 0–90 days | 3,062 | 6.8% |
| 91–180 days | 2,901 | 6.8% |
| 181–365 days | 3,264 | 11.0% |
| 366–540 days | 336 | 65.8% |
| 541–720 days | 347 | 73.8% |
| 721+ days | 518 | 50.2% |

In total: under 1 year 8.3% (9,227 customers) versus over 1 year 61.4% (1,201 customers).

The model rates long-tenure one-time buyers lowest because it assumes a steady buying rate and reads a long silence as low interest. In this data the opposite holds. These rates are **descriptive**: they were measured on the same holdout window. A fair test would train on an earlier cutoff and score a later one. The cause (real behaviour or how AdventureWorks was generated) is **not established**.

---

## 7) 🧮 Customer Status, Value Tier, Actions

### `alive_status` (descriptive rule, not a probability)
Compares how long a customer has been silent with how often they usually buy. The column keeps its old name because the SQL load procedure and Power BI expect it.

| Status | Rule | Customers | Bought again in holdout |
|---|---|---|---|
| One-Time Buyer | no repeat purchase | 10,428 | 14.4% |
| Active Repeat | silent ≤ 1× usual gap | 4,842 | 12.7% |
| Cooling Repeat | 1× to 2× | 455 | 12.5% |
| Lapsed Repeat | > 2× | 575 | 11.8% |

Lapsed vs Active: z = -0.58, **not statistically different**. Silence does not predict repurchase here. The "One-Time Buyer" rate averages two very different groups (see section 6).

The model also over-predicts repeat buyers, and because it assumes nobody leaves, it forecasts the most purchases for the longest-silent customers:

| Status | Predicted per customer | Actual | Gap |
|---|---|---|---|
| Active Repeat | 0.210 | 0.152 | +38% |
| Cooling Repeat | 0.242 | 0.178 | +36% |
| Lapsed Repeat | 0.249 | 0.162 | +54% |
| One-Time Buyer | 0.133 | 0.150 | -11% |

### `value_tier`
Quarters of customers by predicted 90-day revenue (Low, Medium, High, Top). It is **relative**: each tier always holds 25% of customers.

### `action_segment`
Business rules, **not model-validated targeting**:

| Segment | Rule | Customers |
|---|---|---|
| Second-Purchase Campaign | One-Time Buyer | 10,428 |
| Retain & Grow | Active, High or Top tier | 3,131 |
| Nurture | Active, other tiers | 1,711 |
| Win-Back | Cooling or Lapsed, other tiers | 707 |
| Win-Back High Value | Cooling or Lapsed, High or Top tier | 323 |

Because status does not predict repurchase, any real campaign should be run as a test with a control group.

---

## 8) 💵 Revenue

Predicted 90-day revenue: **$9,197,838** (expected purchases × expected order value).

Actual holdout revenue is calculated in SQL on the exact 90-day window. An earlier Python/SQL check used a 91-day window, which explained the purchase-day mismatch (2,538 vs 2,475). Actual revenue: **$[fill after rerun]**, error **[fill]%**.

The Gamma-Gamma assumption is violated (section 3) and one-time buyers receive an assumed order value, so the revenue forecast is the least reliable output. Treat the revenue backtest as a check, not as proof of accuracy.

---

## 9) 🔧 Engineering Notes

| Issue | Fix |
|---|---|
| Tiny negative values break SQL `CHECK` constraints | `.clip(lower=0.0)` before writing |
| Gamma-Gamma needs repeat buyers | One-time buyers receive the repeat-buyer median |
| SQLAlchemy 2.x needs executable objects | `text(...)` |
| Gold load procedure truncates fact tables and refills from `stg_` tables | Notebook also writes both staging tables, in one transaction |
| Wrong holdout window (91 vs 90 days) in an earlier revenue query | Revenue now calculated in SQL on the exact 90 days |
| Hard-coded server name | `SQL_SERVER` environment variable |

---

## 10) 🗂️ Output Tables

`gold.fact_customer_btyd_predictions`: `p_alive` (NULL), predicted purchases and revenue (30 and 90 days), expected order value, `alive_status`, `value_tier`, `action_segment`, `run_id`.
`gold.fact_customer_btyd_eval`: actual vs predicted holdout purchases and revenue, absolute and percentage error, `alive_status`.

---

## 11) 🚧 Limitations

- Backtest, not a live forecast.
- No advantage over simple baselines in this dataset; customer ranking is negative.
- No usable churn probability.
- Purchasing depends on tenure, which BG/NBD cannot represent.
- Gamma-Gamma assumption violated (correlation 0.428).
- Status and action rules are not validated predictors.
- One-time buyers' order value is assumed; value tier is relative.
- The tenure finding is descriptive, from one holdout window.
- AdventureWorks is synthetic, so the method and pipeline are the point, not the business conclusions.
- `lifetimes` is in maintenance mode; PyMC-Marketing is its maintained successor.

---

## 12) 🚀 Next Steps

1. Build a supervised challenger that predicts "buys in the next 90 days" with tenure as a feature, trained on an earlier cutoff and scored on a later one, then compare its lift with the baselines.
2. Check the gap between first and second purchase to understand the tenure pattern.
3. Try PyMC-Marketing with priors.
4. Run with an observation date after the latest order for a true forward forecast.
5. Keep a run log and a current-run view to monitor drift.

---

**References:** Fader, Hardie and Lee (2005), *Counting Your Customers the Easy Way* (BG/NBD); Fader and Hardie, Gamma-Gamma spend model; Wharton Customer Analytics (Coursera).
