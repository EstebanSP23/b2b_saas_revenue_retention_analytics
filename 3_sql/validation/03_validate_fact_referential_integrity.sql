-- ============================================
-- 03_validate_fact_referential_integrity.sql
-- Layer: VALIDATION
-- Purpose:
--   Verify that every foreign key referenced in mart.fact_customer_month
--   resolves to its corresponding dimension. Orphan keys would silently
--   break dashboard filters and slicers.
--
-- Checks:
--   (a) Every customer_id  in the fact exists in mart.dim_customer.
--   (b) Every non-NULL plan_id in the fact exists in mart.dim_plan.
--       (plan_id can be NULL on churned customer-months; that's expected.)
--   (c) Every month_start  in the fact exists in mart.dim_date.
--
-- Expected result:
--   orphan_rows = 0 for every check.
-- ============================================

-- (a) Orphan customers
SELECT
    'customer_id missing in dim_customer'              AS check_name,
    COUNT(*)                                            AS orphan_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END  AS check_status
FROM mart.fact_customer_month f
LEFT JOIN mart.dim_customer d
    ON d.customer_id = f.customer_id
WHERE d.customer_id IS NULL

UNION ALL

-- (b) Orphan plans (ignore NULL plan_id on churned rows)
SELECT
    'plan_id missing in dim_plan',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM mart.fact_customer_month f
LEFT JOIN mart.dim_plan d
    ON d.plan_id = f.plan_id
WHERE f.plan_id IS NOT NULL
  AND d.plan_id IS NULL

UNION ALL

-- (c) Orphan months
SELECT
    'month_start missing in dim_date',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM mart.fact_customer_month f
LEFT JOIN mart.dim_date d
    ON d.month_start = f.month_start
WHERE d.month_start IS NULL;
