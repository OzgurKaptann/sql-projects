# E‑commerce Funnel (GA4 + BigQuery)

> A compact, production‑ready set of SQL queries to analyze a GA4 e‑commerce funnel in BigQuery — from session starts to purchase — including an optional engagement‑to‑purchase correlation study.

## What’s Inside
- **queries/**: Ordered SQL files (`Query_I.sql`, `Query_II.sql`, …).
- **assets/**: Placeholder for charts or exports (optional).

## Dataset & Assumptions
- Source: **GA4 export in BigQuery** (events table like `events_*`).
- Session identity uses **`user_pseudo_id` + `ga_session_id`** (or `session_id`) depending on your schema.
- Purchases are identified via the `purchase` event and associated revenue parameters.
- Nulls are handled with `COALESCE` and guarded casts (e.g., `SAFE_CAST`).

## Query Guide
### 1.Query SQL  — `Query_I.sql`
**Why:** To measure how many engaged sessions progress from product interaction to starting checkout.
**What it does:**
- Defines clean session keys and joins event‑level data where needed.
- Aggregates per session to compute step‑level metrics (counts, flags, ratios).
- Uses `COALESCE` to avoid null propagation in calculations.
**Outputs:** session‑level table or a metrics table usable for dashboards.

### 2.Query  SQL  — `Query_II.sql`
**Why:** To measure how many engaged sessions progress from product interaction to starting checkout.
**What it does:**
- Defines clean session keys and joins event‑level data where needed.
- Aggregates per session to compute step‑level metrics (counts, flags, ratios).
- Uses `COALESCE` to avoid null propagation in calculations.
**Outputs:** session‑level table or a metrics table usable for dashboards.

### 3.Query  SQL  — `Query_III.sql`
**Why:** To compute final conversion at purchase and connect it back to earlier funnel steps.
**What it does:**
- Defines clean session keys and joins event‑level data where needed.
- Aggregates per session to compute step‑level metrics (counts, flags, ratios).
- Uses `COALESCE` to avoid null propagation in calculations.
**Outputs:** session‑level table or a metrics table usable for dashboards.

### 4.Query  SQL  — `Query_IV.sql`
**Why:** To quantify the relationship between engagement (presence and duration) and the likelihood of purchase at the session level.
**What it does:**
- Defines clean session keys and joins event‑level data where needed.
- Aggregates per session to compute step‑level metrics (counts, flags, ratios).
- Uses `COALESCE` to avoid null propagation in calculations.
**Outputs:** session‑level table or a metrics table usable for dashboards.

## How to Run
1. Open **BigQuery** and select your GA4 dataset.
2. Run the queries in order (`Query_I` → `Query_II` → …).
3. Replace placeholder dataset/table names with yours where necessary.
4. Export results to `assets/` if you want to version outputs (CSV/Parquet).

## Notes on Correlation
- `session_engaged` vs `purchase` → **point‑biserial correlation** (implemented via `CORR` between a binary and a numeric).
- `engagement_time_msec` vs `purchase` → **Pearson correlation** at the session level.
- Always inspect distributions and consider confounders (traffic source, device, new vs returning).

## Suggested Insights to Report on LinkedIn
- Share **top‑of‑funnel → purchase** drop‑offs (e.g., PDP → ATC → Checkout → Purchase).
- Compare **engaged vs non‑engaged sessions** in conversion rate and AOV.
- Include a ** one‑line takeaway** per step: *“Engaged sessions convert ~3× more than non‑engaged sessions.”*

## Attribution
Created by **Özgür Kaptan**. If you find it useful, ⭐ the repo and connect on LinkedIn.
