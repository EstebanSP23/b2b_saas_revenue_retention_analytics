-- ============================================
-- 06_validate_growth_efficiency_sanity.sql
-- Layer: VALIDATION
-- Purpose:
--   Sanity-check the derived SaaS unit-economics view
--   mart.vw_growth_efficiency. These are KPIs that go straight onto the
--   executive dashboard, so they need to satisfy basic business invariants.
--
-- Business rules:
--   - active_customers >= churned_customers
--   - active_customers >= 0, new_customers >= 0, churned_customers >= 0
--   - marketing_spend >= 0
--   - cac >= 0 when defined
--   - arpu  > 0 whenever total_mrr > 0 and active_customers > 0
--   - churn_rate in [0, 1]
--   - ltv_cac_ratio is NULL only when cac is NULL/0 or churn_rate is NULL/0
--
-- Expected result:
--   bad_rows = 0 for every check.
-- ============================================

-- (a) Negative counts or spend
SELECT
    'negative count or spend'                            AS check_name,
    COUNT(*)                                              AS bad_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END    AS check_status
FROM mart.vw_growth_efficiency
WHERE new_customers    < 0
   OR active_customers < 0
   OR churned_customers < 0
   OR marketing_spend  < 0

UNION ALL

-- (b) More customers churned than were active in the month
SELECT 'churned_customers > active_customers',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM mart.vw_growth_efficiency
WHERE churned_customers > active_customers

UNION ALL

-- (c) Negative CAC
SELECT 'cac < 0',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM mart.vw_growth_efficiency
WHERE cac IS NOT NULL
  AND cac < 0

UNION ALL

-- (d) Positive revenue and active customers but ARPU not positive
SELECT 'mrr > 0 and active_customers > 0 but arpu <= 0',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM mart.vw_growth_efficiency
WHERE total_mrr > 0
  AND active_customers > 0
  AND (arpu IS NULL OR arpu <= 0)

UNION ALL

-- (e) churn_rate outside [0, 1]
SELECT 'churn_rate outside [0, 1]',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM mart.vw_growth_efficiency
WHERE churn_rate IS NOT NULL
  AND (churn_rate < 0 OR churn_rate > 1)

UNION ALL

-- (f) ltv_cac_ratio NULL while both inputs are well-defined
SELECT 'ltv_cac_ratio NULL despite valid cac and churn_rate',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM mart.vw_growth_efficiency
WHERE ltv_cac_ratio IS NULL
  AND cac IS NOT NULL AND cac > 0
  AND churn_rate IS NOT NULL AND churn_rate > 0
  AND arpu IS NOT NULL AND arpu > 0;
