-- ============================================
-- 01_staging_create_tables.sql
-- Layer: STAGING
-- Purpose:
--   Create cleaned, standardized tables derived from raw.*
--   This layer fixes types, ensures joinability, and adds basic validation fields.
-- ============================================

CREATE SCHEMA IF NOT EXISTS staging;

-- ---------- staging.plans ----------
DROP TABLE IF EXISTS staging.plans;
CREATE TABLE staging.plans (
    plan_id         INT PRIMARY KEY,
    plan_name       TEXT NOT NULL,
    monthly_price   INT NOT NULL
);

-- ---------- staging.customers ----------
DROP TABLE IF EXISTS staging.customers;
CREATE TABLE staging.customers (
    customer_id          INT PRIMARY KEY,
    signup_month         DATE NOT NULL,
    acquisition_channel  TEXT NOT NULL,
    initial_plan_id      INT NOT NULL
);

-- ---------- staging.customer_month ----------
-- Same grain as raw: one row per customer per month after signup
DROP TABLE IF EXISTS staging.customer_month;
CREATE TABLE staging.customer_month (
    customer_id  INT NOT NULL,
    month        DATE NOT NULL,
    plan_id      INT NULL,
    mrr          INT NOT NULL,
    -- Basic validation flags (simple and useful)
    is_churn_month BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_staging_customer_month
ON staging.customer_month (customer_id, month);

-- ---------- staging.acquisition_cost ----------
DROP TABLE IF EXISTS staging.acquisition_cost;
CREATE TABLE staging.acquisition_cost (
    customer_id          INT PRIMARY KEY,
    acquisition_channel  TEXT NOT NULL,
    signup_month         DATE NOT NULL,
    cac                  NUMERIC(12,2) NOT NULL
);
