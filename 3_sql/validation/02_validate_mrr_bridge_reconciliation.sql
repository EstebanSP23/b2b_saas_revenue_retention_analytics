-- ============================================
-- 02_validate_mrr_bridge_reconciliation.sql
-- Layer: VALIDATION
-- Purpose:
--   Verify that the monthly MRR bridge reconciles for every month:
--     beginning_mrr + new_mrr + expansion_mrr
--                   - contraction_mrr - churned_mrr
--                   = ending_mrr
--
--   The view mart.vw_monthly_mrr_bridge already exposes a bridge_diff column.
--   This script aggregates that diff to flag any month where the bridge
--   fails to reconcile.
--
-- Expected result:
--   bad_months = 0 (every monthly bridge reconciles exactly, since mrr is INT).
-- ============================================

-- Per-month detail: any month with a non-zero bridge_diff
SELECT
    month_start,
    beginning_mrr,
    new_mrr,
    expansion_mrr,
    contraction_mrr,
    churned_mrr,
    ending_mrr,
    calculated_ending_mrr,
    bridge_diff,
    CASE WHEN bridge_diff = 0 THEN 'PASS' ELSE 'FAIL' END AS check_status
FROM mart.vw_monthly_mrr_bridge
ORDER BY month_start;

-- Summary: count of months that fail to reconcile
SELECT
    COUNT(*)                                                        AS total_months,
    SUM(CASE WHEN bridge_diff <> 0 THEN 1 ELSE 0 END)                AS bad_months,
    MAX(ABS(bridge_diff))                                            AS max_abs_diff,
    CASE
        WHEN SUM(CASE WHEN bridge_diff <> 0 THEN 1 ELSE 0 END) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END                                                              AS check_status
FROM mart.vw_monthly_mrr_bridge;
