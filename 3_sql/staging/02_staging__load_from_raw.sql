-- ============================================
-- 02_staging__load_from_raw.sql
-- Layer: STAGING
-- Purpose:
--   Load staging tables from raw tables with minimal cleaning.
-- ============================================

-- Plans (straight copy)
TRUNCATE TABLE staging.plans;
INSERT INTO staging.plans (plan_id, plan_name, monthly_price)
SELECT plan_id, plan_name, monthly_price
FROM raw.plans;

-- Customers (straight copy)
TRUNCATE TABLE staging.customers;
INSERT INTO staging.customers (customer_id, signup_month, acquisition_channel, initial_plan_id)
SELECT customer_id, signup_month, acquisition_channel, initial_plan_id
FROM raw.customers;

-- Acquisition cost (straight copy)
TRUNCATE TABLE staging.acquisition_cost;
INSERT INTO staging.acquisition_cost (customer_id, acquisition_channel, signup_month, cac)
SELECT customer_id, acquisition_channel, signup_month, cac
FROM raw.acquisition_cost;

-- Customer-month (add simple churn flag)
TRUNCATE TABLE staging.customer_month;
INSERT INTO staging.customer_month (customer_id, month, plan_id, mrr, is_churn_month)
SELECT
    customer_id,
    month,
    plan_id,
    mrr,
    (mrr = 0) AS is_churn_month
FROM raw.customer_month;