-- Select the database returned by `terraform output -raw catalog_database`
-- in Athena before running these queries.

-- 1. Reconciliation
SELECT
    (SELECT COUNT(*) FROM etl_curated) AS valid_rows,
    (SELECT COUNT(*) FROM etl_rejected) AS rejected_rows,
    (SELECT COUNT(*) FROM etl_curated)
      + (SELECT COUNT(*) FROM etl_rejected) AS total_source_rows;

-- 2. Rejected rows by reason
SELECT
    error_reason,
    COUNT(*) AS rejected_rows
FROM etl_rejected
GROUP BY error_reason
ORDER BY rejected_rows DESC;

-- 3. Business summary
SELECT
    region,
    status,
    COUNT(*) AS transaction_count,
    ROUND(SUM(total_amount), 2) AS total_amount
FROM etl_curated
GROUP BY region, status
ORDER BY region, status;

