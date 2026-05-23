-- ============================================
-- 04_validate_nulls_and_keys.sql
-- Layer: VALIDATION
-- Purpose:
--   Verify that critical key and measure columns in the fact and dimensions
--   do not contain NULLs and that the composite primary key on the fact is
--   unique.
--
-- Expected result:
--   bad_rows = 0 for every check.
-- ============================================

-- (a) NULL keys in fact
SELECT
    'fact: NULL customer_id'                            AS check_name,
    COUNT(*)                                             AS bad_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END   AS check_status
FROM mart.fact_customer_month
WHERE customer_id IS NULL

UNION ALL

SELECT 'fact: NULL month_start',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM mart.fact_customer_month
WHERE month_start IS NULL

UNION ALL

-- (b) NULL measures that should always be populated
SELECT 'fact: NULL mrr',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM mart.fact_customer_month
WHERE mrr IS NULL

UNION ALL

SELECT 'fact: NULL is_active',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM mart.fact_customer_month
WHERE is_active IS NULL

UNION ALL

-- (c) Composite primary key uniqueness on the fact
SELECT 'fact: duplicate (customer_id, month_start)',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT customer_id, month_start, COUNT(*) AS c
    FROM mart.fact_customer_month
    GROUP BY customer_id, month_start
    HAVING COUNT(*) > 1
) dup

UNION ALL

-- (d) NULL keys in dimensions
SELECT 'dim_customer: NULL customer_id',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM mart.dim_customer
WHERE customer_id IS NULL

UNION ALL

SELECT 'dim_plan: NULL plan_id',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM mart.dim_plan
WHERE plan_id IS NULL

UNION ALL

SELECT 'dim_date: NULL month_start',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM mart.dim_date
WHERE month_start IS NULL;
