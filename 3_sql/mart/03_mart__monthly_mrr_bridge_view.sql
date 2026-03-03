-- ============================================
-- 03_mart__monthly_mrr_bridge_view.sql
-- Layer: MART
-- Purpose:
--   Create a monthly MRR bridge view that reconciles:
--     Beginning MRR
--   + New MRR
--   + Expansion MRR
--   - Contraction MRR
--   - Churned MRR
--   = Ending MRR
--
-- Notes:
--   Uses mart.fact_customer_month (grain: customer-month).
--   This is executive-grade SaaS reporting logic.
-- ============================================

CREATE SCHEMA IF NOT EXISTS mart;

DROP VIEW IF EXISTS mart.vw_monthly_mrr_bridge;

CREATE VIEW mart.vw_monthly_mrr_bridge AS
WITH monthly AS (
    SELECT
        month_start,

        -- Ending MRR (end-of-month snapshot)
        SUM(mrr) AS ending_mrr,

        -- Customer counts (optional but useful)
        COUNT(DISTINCT CASE WHEN is_active THEN customer_id END) AS active_customers,

        -- Bridge components (all in MRR dollars)
        SUM(CASE WHEN mrr_movement_type = 'New' THEN mrr ELSE 0 END) AS new_mrr,

        SUM(CASE WHEN mrr_movement_type = 'Expansion' THEN mrr_delta ELSE 0 END) AS expansion_mrr,

        -- For contraction/churn, mrr_delta is negative.
        -- We store them as positive numbers for the bridge.
        SUM(CASE WHEN mrr_movement_type = 'Contraction' THEN -mrr_delta ELSE 0 END) AS contraction_mrr,
        SUM(CASE WHEN mrr_movement_type = 'Churn' THEN -mrr_delta ELSE 0 END) AS churned_mrr

    FROM mart.fact_customer_month
    GROUP BY 1
),
bridge AS (
    SELECT
        month_start,
        active_customers,
        ending_mrr,
        new_mrr,
        expansion_mrr,
        contraction_mrr,
        churned_mrr,

        -- Beginning MRR is previous month's ending MRR
        LAG(ending_mrr) OVER (ORDER BY month_start) AS beginning_mrr
    FROM monthly
)
SELECT
    month_start,
    active_customers,

    COALESCE(beginning_mrr, 0) AS beginning_mrr,
    new_mrr,
    expansion_mrr,
    contraction_mrr,
    churned_mrr,
    ending_mrr,

    -- Reconciliation check
    (COALESCE(beginning_mrr, 0) + new_mrr + expansion_mrr - contraction_mrr - churned_mrr) AS calculated_ending_mrr,
    (ending_mrr - (COALESCE(beginning_mrr, 0) + new_mrr + expansion_mrr - contraction_mrr - churned_mrr)) AS bridge_diff
FROM bridge
ORDER BY month_start;