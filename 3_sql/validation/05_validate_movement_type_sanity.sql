-- ============================================
-- 05_validate_movement_type_sanity.sql
-- Layer: VALIDATION
-- Purpose:
--   Verify that mrr_movement_type is well-formed and that the sign of
--   mrr_delta matches the business meaning of each movement.
--
-- Business rules:
--   - mrr_movement_type must be one of:
--       'New', 'Expansion', 'Contraction', 'Churn', 'Flat', 'Inactive'
--   - 'Other' is the fallback bucket in the CASE statement and should
--       never occur in healthy data; any 'Other' rows indicate a classification gap.
--   - 'New' and 'Expansion' rows must have mrr_delta > 0
--   - 'Contraction' and 'Churn' rows must have mrr_delta < 0
--   - 'Flat' and 'Inactive' rows must have mrr_delta = 0
--   - Inactive rows (is_active = FALSE) must have mrr = 0
--
-- Expected result:
--   bad_rows = 0 for every check.
-- ============================================

-- (a) Unknown movement_type values
SELECT
    'unknown mrr_movement_type value'                   AS check_name,
    COUNT(*)                                             AS bad_rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END   AS check_status
FROM mart.fact_customer_month
WHERE mrr_movement_type NOT IN
    ('New', 'Expansion', 'Contraction', 'Churn', 'Flat', 'Inactive', 'Other')

UNION ALL

-- (b) 'Other' fallback bucket should not occur
SELECT '''Other'' fallback bucket present',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM mart.fact_customer_month
WHERE mrr_movement_type = 'Other'

UNION ALL

-- (c) Positive-movement rows with non-positive mrr_delta
SELECT 'New/Expansion with mrr_delta <= 0',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM mart.fact_customer_month
WHERE mrr_movement_type IN ('New', 'Expansion')
  AND mrr_delta <= 0

UNION ALL

-- (d) Negative-movement rows with non-negative mrr_delta
SELECT 'Contraction/Churn with mrr_delta >= 0',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM mart.fact_customer_month
WHERE mrr_movement_type IN ('Contraction', 'Churn')
  AND mrr_delta >= 0

UNION ALL

-- (e) Flat / Inactive rows with non-zero mrr_delta
SELECT 'Flat/Inactive with mrr_delta <> 0',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM mart.fact_customer_month
WHERE mrr_movement_type IN ('Flat', 'Inactive')
  AND mrr_delta <> 0

UNION ALL

-- (f) Inactive rows with non-zero MRR (a churned customer should not bill)
SELECT 'is_active = FALSE with mrr <> 0',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM mart.fact_customer_month
WHERE is_active = FALSE
  AND mrr <> 0;
