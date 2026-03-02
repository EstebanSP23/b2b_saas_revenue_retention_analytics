-- ============================================
-- 01_mart__create_dimensions.sql
-- Layer: MART
-- Purpose:
--   Create dimension tables for analytics (star schema).
--   Dimensions provide descriptive context for facts.
-- ============================================

CREATE SCHEMA IF NOT EXISTS mart;

-- ---------- mart.dim_date ----------
-- One row per month in the dataset
DROP TABLE IF EXISTS mart.dim_date;
CREATE TABLE mart.dim_date AS
WITH month_series AS (
    SELECT generate_series(
        (SELECT MIN(month) FROM staging.customer_month),
        (SELECT MAX(month) FROM staging.customer_month),
        INTERVAL '1 month'
    )::date AS month_start
)
SELECT
    month_start                                AS month_start,
    EXTRACT(YEAR  FROM month_start)::int       AS year,
    EXTRACT(MONTH FROM month_start)::int       AS month_num,
    TO_CHAR(month_start, 'YYYY-MM')            AS year_month
FROM month_series;

ALTER TABLE mart.dim_date
ADD CONSTRAINT pk_dim_date PRIMARY KEY (month_start);

-- ---------- mart.dim_plan ----------
DROP TABLE IF EXISTS mart.dim_plan;
CREATE TABLE mart.dim_plan AS
SELECT
    plan_id,
    plan_name,
    monthly_price
FROM staging.plans;

ALTER TABLE mart.dim_plan
ADD CONSTRAINT pk_dim_plan PRIMARY KEY (plan_id);

-- ---------- mart.dim_customer ----------
DROP TABLE IF EXISTS mart.dim_customer;
CREATE TABLE mart.dim_customer AS
SELECT
    c.customer_id,
    c.signup_month,
    c.acquisition_channel,
    c.initial_plan_id
FROM staging.customers c;

ALTER TABLE mart.dim_customer
ADD CONSTRAINT pk_dim_customer PRIMARY KEY (customer_id);

-- Optional: helpful indexes for joins
CREATE INDEX IF NOT EXISTS ix_dim_customer_signup_month
ON mart.dim_customer (signup_month);

CREATE INDEX IF NOT EXISTS ix_dim_customer_channel
ON mart.dim_customer (acquisition_channel);