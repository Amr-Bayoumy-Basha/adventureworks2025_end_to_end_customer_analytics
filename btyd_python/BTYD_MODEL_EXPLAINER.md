# 📊 BTYD Model Notebook Explainer (`btyd_model.ipynb`)

This document explains what the BTYD (Buy Till You Die) notebook does, what it found, and what it deliberately does **not** claim.

---

## 1) 🎯 Objective

Apply the probabilistic customer-base methods from the Wharton Customer Analytics course (BG/NBD and Gamma-Gamma) to the AdventureWorks warehouse, and turn the results into forecasts that Power BI can use.

The notebook produces:

- Expected purchases per customer for the next 30 and 90 days
- Expected order value per customer
- Expected revenue (expected purchases × expected order value)
- A transparent customer status, value tier and action segment
- A holdout scorecard showing how accurate the forecasts were

It does **not** produce a probability that a customer is still active (`p_alive`). Section 6 explains why.

---

## 2) 🏗️ End-to-End Data Flow

1. **Silver layer**: cleaned transactions with customer identities.
2. **Gold input table** `gold.fact_customer_btyd_inputs`: one row per customer with `frequency`, `recency`, `T`, `monetary_value` and the holdout count. The SQL splits history into a **calibration period** (the models learn from this) and a 90-day **holdout** (hidden, used only for testing).
3. **Python notebook**: fits the models, validates, labels customers.
4. **Gold output tables**: `fact_customer_btyd_predictions` and `fact_customer_btyd_eval`, plus matching `stg_` staging tables.
5. **Power BI**: the Customer Forecasting page reads the two output tables.

> `observation_date` is the **end of the holdout**. The "90-day forecast" is therefore a **backtest** of a window that has already happened, not a forecast of the future.

---

## 3) 🧠 Models

### A) Transaction model: Modified BG/NBD (`ModifiedBetaGeoFitter`)

Estimates how often each customer buys, and (in theory) the chance they stop buying after each purchase. The modified version lets dropout begin right after the first purchase, which suits a customer base with many one-time buyers.

Used for: `predicted_purchases_30d`, `predicted_purchases_90d`.

### B) Spend model: Gamma-Gamma (`GammaGammaFitter`)

Estimates the average order value of customers who have bought more than once. It assumes order value is unrelated to purchase frequency, and the notebook checks the correlation to test this.

One-time buyers have no order history, so they receive the **median order value of repeat buyers**. This is an assumption, not a model estimate.

---

## 4) ✅ What the Validation Shows

Results on the 90-day holdout the model never saw:

| Measure | Result |
|---|---|
| Actual purchases | 2,475 |
| Predicted purchases | 2,654.6 |
| Volume error | **+7.3%** |
| MAE per customer (model) | 0.267 |
| MAE if we predict "nobody buys" | 0.152 |
| MAE if we predict the average for everyone | 0.262 |

**How to read it.** The model gets the **total** about right, which is what budgeting and capacity planning need. It is **not** clearly better than a simple guess at the **individual** level, because 86% of customers buy nothing in 90 days and a zero-guess is hard to beat. The decile lift table in the notebook shows the same thing: ranking customers by predicted purchases separates only the heaviest buyers.

---

## 5) ⚠️ The Dropout Problem (`p_alive`)

### What happened
All three models tried (MBG/NBD, BG/NBD, Pareto/NBD) returned dropout parameters near zero, so `p_alive` came out as 1.0 for every customer. The model was effectively saying "nobody ever leaves".

### Why
A BTYD model learns about "death" from customers who go quiet for much longer than their normal rhythm. This data has very few of them:

- The typical repeat buyer has been silent for about **0.34×** their usual gap between purchases.
- Only about **10%** of repeat buyers are more than 2× overdue.
- **64%** of customers bought only once, and slow buying already explains that.

The optimizer finds no evidence of leaving, so it assumes no one leaves.

### What we decided
- Keep the model for purchase and revenue forecasts, where it works.
- **Do not publish a `p_alive`.** An earlier version blended in a recency formula and labelled the result `p_alive`. That number was not a model output, so it was removed. The column is stored as NULL.

### Ideas we rejected
- Typing "stable business prior" parameters into the model by hand. That invents the answer.
- Injecting parameters fitted on repeat buyers only. BG/NBD needs the one-time buyers to learn about dropout.

---

## 6) 🧮 Customer Status, Value Tier and Actions

### `alive_status` (descriptive rule, not a probability)

Compares how long a customer has been silent with how often they usually buy. The column keeps its old name because the SQL load procedure and Power BI expect it.

| Status | Rule | Customers |
|---|---|---|
| One-Time Buyer | no repeat purchase | 10,428 |
| Active Repeat | silent ≤ 1× usual gap | 4,842 |
| Cooling Repeat | silent 1× to 2× usual gap | 455 |
| Lapsed Repeat | silent > 2× usual gap | 575 |

### Does the rule predict anything?

Share of each status that bought again in the holdout:

| Status | Bought again |
|---|---|
| Active Repeat | 12.7% |
| Cooling Repeat | 12.5% |
| Lapsed Repeat | 11.8% |
| One-Time Buyer | 14.4% |

The rates are essentially the same for every status. The notebook runs a significance test between Lapsed and Active, and the difference is within what chance would produce. **In this dataset, being silent longer does not make a customer less likely to buy again.** This agrees with the model's finding of no detectable dropout.

### `value_tier`
Quarters of customers ranked by predicted 90-day revenue (Low, Medium, High, Top). It is **relative**: each tier always holds 25% of customers.

### `action_segment`
Simple business rules:

| Segment | Rule |
|---|---|
| Second-Purchase Campaign | One-Time Buyer |
| Win-Back High Value | Cooling or Lapsed, with High or Top value tier |
| Win-Back | Cooling or Lapsed, other value tiers |
| Retain & Grow | Active, with High or Top value tier |
| Nurture | everything else |

**These are rules to test, not model-proven targeting.** Because the holdout shows status does not predict repurchase, a real campaign should be run as a test with a control group.

---

## 6b) 🔧 Engineering Notes and Workarounds

| Issue | Cause | Fix in the notebook |
|---|---|---|
| Negative tiny values breaking SQL `CHECK` constraints | Floating-point rounding | `.clip(lower=0.0)` on all predictions before writing |
| Gamma-Gamma fails for one-time buyers | Needs repeat purchases | Train on repeat buyers, give one-time buyers the repeat-buyer median |
| SQLAlchemy 2.x rejecting raw SQL strings | Requires executable objects | `from sqlalchemy import text` and `connection.execute(text(...))` |
| Warehouse refresh wiping predictions | The Gold load procedure truncates both fact tables and refills them only from `stg_` tables | The notebook also writes `gold.stg_customer_btyd_predictions` and `gold.stg_customer_btyd_eval` |
| Holdout revenue was an estimate | It used holdout purchases × calibration order value | The notebook reads real holdout revenue from Silver and checks that purchase counts match; it falls back to the estimate with a warning |
| Hard-coded server name | Machine name in code | Read from the `SQL_SERVER` environment variable |

---

## 7) 🗂️ Output Tables

### `gold.fact_customer_btyd_predictions`
Per customer: `p_alive` (NULL), predicted purchases and revenue (30 and 90 days), expected order value, `alive_status`, `value_tier`, `action_segment`, `run_id`.

### `gold.fact_customer_btyd_eval`
Per customer: actual vs predicted holdout purchases and revenue, absolute error, percentage error, `alive_status`.

Both are reloaded from the `stg_` tables whenever the Gold layer is refreshed.

---

## 8) 🚧 Limitations

- **Backtest, not a live forecast.** Re-run with the observation date after your latest order to forecast forward.
- **Good at totals, weak at ranking individuals.**
- **No usable churn probability** in this data.
- **Status and action rules are not validated predictors.**
- **One-time buyers' order value is assumed.**
- **Value tier is relative.**
- **AdventureWorks is synthetic data.** The pipeline and method are the point, not the business conclusions.
- **`lifetimes` is in maintenance mode.** PyMC-Marketing is its maintained successor.

---

## 9) 🚀 Next Steps

1. Run the notebook against a forward cutoff date for a true forecast.
2. Add a supervised challenger (for example logistic regression or LightGBM predicting "buys in the next 90 days") and compare it with the BTYD ranking using a lift table.
3. Try PyMC-Marketing with priors.
4. Track runs over time: keep a run log and a current-run view so score drift can be monitored.

---

**References:** Fader, Hardie and Lee (2005), *Counting Your Customers the Easy Way* (BG/NBD); Fader and Hardie, Gamma-Gamma spend model; Wharton Customer Analytics (Coursera).
