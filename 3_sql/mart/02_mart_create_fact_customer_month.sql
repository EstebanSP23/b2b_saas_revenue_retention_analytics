-- ============================================
-- 02_mart__create_fact_customer_month.sql
-- Layer: MART
-- Purpose:
--   Create the core fact table at grain:
--     1 row per customer per month
--   Adds basic analytics-friendly fields:
--     - active flag
--     - churn flag
--     - previous month MRR and delta (movement)
-- ============================================

CREATE SCHEMA IF NOT EXISTS mart;

DROP TABLE IF EXISTS mart.fact_customer_month CASCADE;

CREATE TABLE mart.fact_customer_month AS
WITH base AS (
    SELECT
        cm.customer_id,
        cm.month AS month_start,
        cm.plan_id,
        cm.mrr,
        cm.is_churn_month,
        -- previous month MRR for the same customer
        LAG(cm.mrr) OVER (
            PARTITION BY cm.customer_id
            ORDER BY cm.month
        ) AS prev_mrr
    FROM staging.customer_month cm
)
SELECT
    b.customer_id,
    b.month_start,
    b.plan_id,
    b.mrr,

    -- Status flags
    (b.mrr > 0) AS is_active,
    b.is_churn_month,

    -- Movement features
    COALESCE(b.prev_mrr, 0) AS prev_mrr,
    (b.mrr - COALESCE(b.prev_mrr, 0)) AS mrr_delta,

    -- Movement type (simple classification)
    CASE
        WHEN COALESCE(b.prev_mrr, 0) = 0 AND b.mrr > 0 THEN 'New'
        WHEN COALESCE(b.prev_mrr, 0) > 0 AND b.mrr = 0 THEN 'Churn'
        WHEN b.mrr = 0 AND COALESCE(b.prev_mrr, 0) = 0 THEN 'Inactive'
        WHEN b.mrr > COALESCE(b.prev_mrr, 0) THEN 'Expansion'
        WHEN b.mrr < COALESCE(b.prev_mrr, 0) AND b.mrr > 0 THEN 'Contraction'
        WHEN b.mrr = COALESCE(b.prev_mrr, 0) AND b.mrr > 0 THEN 'Flat'
        ELSE 'Other'
    END AS mrr_movement_type
FROM base b;

-- Keys / indexes
ALTER TABLE mart.fact_customer_month
ADD CONSTRAINT pk_fact_customer_month PRIMARY KEY (customer_id, month_start);

CREATE INDEX IF NOT EXISTS ix_fact_customer_month_month
ON mart.fact_customer_month (month_start);

CREATE INDEX IF NOT EXISTS ix_fact_customer_month_plan
ON mart.fact_customer_month (plan_id);