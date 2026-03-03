-- ============================================
-- 04_mart__monthly_retention_view.sql
-- Layer: MART
-- Purpose:
--   Monthly retention metrics:
--     - Logo retention (customer retention)
--     - GRR (Gross Revenue Retention)
--     - NRR (Net Revenue Retention)
--
-- Definitions:
--   Existing customers for month M = customers with prev_mrr > 0 in month M
--   GRR = (Beginning MRR - Contraction - Churn) / Beginning MRR
--   NRR = (Beginning MRR + Expansion - Contraction - Churn) / Beginning MRR
-- ============================================

CREATE SCHEMA IF NOT EXISTS mart;

DROP VIEW IF EXISTS mart.vw_monthly_retention;

CREATE VIEW mart.vw_monthly_retention AS
WITH base AS (
    SELECT
        month_start,

        -- Existing customers in this month = had revenue last month
        COUNT(DISTINCT CASE WHEN prev_mrr > 0 THEN customer_id END) AS existing_customers,

        -- Retained customers = existing customers who are still active this month
        COUNT(DISTINCT CASE WHEN prev_mrr > 0 AND mrr > 0 THEN customer_id END) AS retained_customers,

        -- Beginning MRR (only from existing customers)
        SUM(CASE WHEN prev_mrr > 0 THEN prev_mrr ELSE 0 END) AS beginning_mrr_existing,

        -- Movement components for existing customers only
        SUM(CASE WHEN prev_mrr > 0 AND mrr_movement_type = 'Expansion' THEN mrr_delta ELSE 0 END) AS expansion_mrr_existing,
        SUM(CASE WHEN prev_mrr > 0 AND mrr_movement_type = 'Contraction' THEN -mrr_delta ELSE 0 END) AS contraction_mrr_existing,
        SUM(CASE WHEN prev_mrr > 0 AND mrr_movement_type = 'Churn' THEN -mrr_delta ELSE 0 END) AS churned_mrr_existing
    FROM mart.fact_customer_month
    GROUP BY 1
)
SELECT
    month_start,
    existing_customers,
    retained_customers,

    CASE
        WHEN existing_customers = 0 THEN NULL
        ELSE retained_customers::numeric / existing_customers
    END AS logo_retention_rate,

    beginning_mrr_existing,
    expansion_mrr_existing,
    contraction_mrr_existing,
    churned_mrr_existing,

    CASE
        WHEN beginning_mrr_existing = 0 THEN NULL
        ELSE (beginning_mrr_existing - contraction_mrr_existing - churned_mrr_existing)::numeric
             / beginning_mrr_existing
    END AS grr,

    CASE
        WHEN beginning_mrr_existing = 0 THEN NULL
        ELSE (beginning_mrr_existing + expansion_mrr_existing - contraction_mrr_existing - churned_mrr_existing)::numeric
             / beginning_mrr_existing
    END AS nrr

FROM base
ORDER BY month_start;