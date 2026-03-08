-- ============================================
-- 05_mart__create_vw_growth_efficiency.sql
-- Layer: MART
-- Object: mart.vw_growth_efficiency
--
-- Purpose:
--   Create a monthly SaaS growth efficiency view
--   combining customer lifecycle activity with
--   marketing acquisition cost.
--
-- Grain:
--   1 row per month
--
-- Description:
--   Aggregates customer revenue movements from
--   mart.fact_customer_month and joins them with
--   acquisition spend from raw.acquisition_cost
--   to calculate key SaaS unit economics metrics.
--
-- Metrics Included:
--     - marketing_spend
--     - new_customers
--     - active_customers
--     - beginning_active_customers
--     - churned_customers
--     - total_mrr
--
-- Derived SaaS Metrics:
--     - CAC (Customer Acquisition Cost)
--     - ARPU (Average Revenue Per User)
--     - churn_rate (customer churn)
--     - LTV (Lifetime Value approximation)
--     - LTV/CAC ratio
--
-- Key Formulas:
--     CAC        = marketing_spend / new_customers
--     ARPU       = total_mrr / active_customers
--     churn_rate = churned_customers / beginning_active_customers
--     LTV        = ARPU / churn_rate
--     LTV/CAC    = LTV / CAC
--
-- Notes:
--   • Metrics are calculated at monthly grain
--   • Division-by-zero handled with NULLIF
--   • Rounding applied for presentation clarity
-- ============================================

CREATE OR REPLACE VIEW mart.vw_growth_efficiency AS
WITH monthly_spend AS (
	SELECT
		signup_month	AS month_start,
		SUM(cac) 		AS marketing_spend
	FROM raw.acquisition_cost
	GROUP BY signup_month
),
monthly_customer_metrics AS (
	SELECT
		month_start,
		COUNT(DISTINCT CASE WHEN mrr_movement_type = 'New' THEN customer_id END) 	AS new_customers,
		COUNT(DISTINCT CASE WHEN mrr > 0 THEN customer_id END) 						AS active_customers,
		COUNT(DISTINCT CASE WHEN prev_mrr > 0 THEN customer_id END) 				AS beginning_active_customers,
		COUNT(DISTINCT CASE WHEN mrr_movement_type = 'Churn' THEN customer_id END)	AS churned_customers,
		SUM(mrr) AS total_mrr
	FROM mart.fact_customer_month
	GROUP BY month_start		
),
base_metrics AS (
	SELECT
		c.month_start,
		COALESCE(s.marketing_spend, 0) AS marketing_spend,
		c.new_customers,
		c.active_customers,
		c.beginning_active_customers,
		c.churned_customers,
		c.total_mrr,
		COALESCE(s.marketing_spend, 0)::numeric / NULLIF(c.new_customers, 0) AS cac,
		c.total_mrr::numeric / NULLIF(c.active_customers, 0) AS arpu,
		c.churned_customers::numeric / NULLIF(c.beginning_active_customers, 0) churn_rate
	FROM monthly_customer_metrics c
	LEFT JOIN monthly_spend s
		ON c.month_start = s.month_start
)
SELECT
	month_start,
	marketing_spend,
	new_customers,
	active_customers,
	beginning_active_customers,
	churned_customers,
	total_mrr,
	ROUND(cac, 2)			AS cac,
	ROUND(arpu, 2)			AS arpu,
	ROUND(churn_rate, 4)	AS churn_rate,
	ROUND(arpu / NULLIF(churn_rate, 0), 2)						AS ltv,
	ROUND((arpu / NULlIF(churn_rate, 0)) / NULLIF(cac, 0), 2)	AS ltv_cac_ratio
FROM base_metrics
ORDER BY month_start;