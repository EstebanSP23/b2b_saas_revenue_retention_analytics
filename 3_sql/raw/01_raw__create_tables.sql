-- ============================================
-- 01_raw__create_tables.sql
-- Layer: RAW
-- Purpose:
--   Create the RAW tables that store CSV data "as loaded".
--   No business logic here — only structure and basic constraints.
--
-- How to run (pgAdmin Query Tool):
--   1) Connect to database: b2b_saas_revenue_retention_analytics
--   2) Execute this script
-- ============================================

-- Ensure schemas exist (safe to run multiple times)
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS mart;

-- ============================================
-- raw.plans
-- 1 row per subscription plan
-- ============================================
DROP TABLE IF EXISTS raw.plans;
CREATE TABLE raw.plans (
    plan_id         INT PRIMARY KEY,
    plan_name       TEXT NOT NULL,
    monthly_price   INT NOT NULL
);

-- ============================================
-- raw.customers
-- 1 row per customer (acquisition attributes)
-- ============================================
DROP TABLE IF EXISTS raw.customers;
CREATE TABLE raw.customers (
    customer_id          INT PRIMARY KEY,
    signup_month         DATE NOT NULL,
    acquisition_channel  TEXT NOT NULL,
    initial_plan_id      INT NOT NULL
);

-- ============================================
-- raw.customer_month
-- Grain: 1 row per customer per month AFTER signup
-- Notes:
--   - plan_id can be NULL when customer churns (mrr = 0)
-- ============================================
DROP TABLE IF EXISTS raw.customer_month;
CREATE TABLE raw.customer_month (
    customer_id  INT NOT NULL,
    month        DATE NOT NULL,
    plan_id      INT NULL,
    mrr          INT NOT NULL
);

-- Prevent duplicates at the customer-month grain
DROP INDEX IF EXISTS raw.ux_raw_customer_month;
CREATE UNIQUE INDEX ux_raw_customer_month
ON raw.customer_month (customer_id, month);

-- ============================================
-- raw.acquisition_cost
-- 1 row per customer with acquisition cost (CAC)
-- CAC = Customer Acquisition Cost
-- ============================================
DROP TABLE IF EXISTS raw.acquisition_cost;
CREATE TABLE raw.acquisition_cost (
    customer_id          INT NOT NULL,
    acquisition_channel  TEXT NOT NULL,
    signup_month         DATE NOT NULL,
    cac                  NUMERIC(12,2) NOT NULL
);