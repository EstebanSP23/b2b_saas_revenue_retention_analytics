-- ============================================
-- 01_validate_row_counts_raw_vs_staging.sql
-- Layer: VALIDATION
-- Purpose:
--   Verify that every table in the staging layer has the same row count as
--   its corresponding raw table. Any non-zero diff indicates that rows were
--   lost or duplicated during the raw -> staging load.
--
-- Expected result:
--   diff = 0 for every table.
-- ============================================

WITH counts AS (
    SELECT 'plans' AS table_name,
           (SELECT COUNT(*) FROM raw.plans)             AS raw_rows,
           (SELECT COUNT(*) FROM staging.plans)         AS staging_rows
    UNION ALL
    SELECT 'customers',
           (SELECT COUNT(*) FROM raw.customers),
           (SELECT COUNT(*) FROM staging.customers)
    UNION ALL
    SELECT 'customer_month',
           (SELECT COUNT(*) FROM raw.customer_month),
           (SELECT COUNT(*) FROM staging.customer_month)
    UNION ALL
    SELECT 'acquisition_cost',
           (SELECT COUNT(*) FROM raw.acquisition_cost),
           (SELECT COUNT(*) FROM staging.acquisition_cost)
)
SELECT
    table_name,
    raw_rows,
    staging_rows,
    (staging_rows - raw_rows) AS diff,
    CASE WHEN staging_rows = raw_rows THEN 'PASS' ELSE 'FAIL' END AS check_status
FROM counts
ORDER BY table_name;
