-- Challenge 2: Adjust `total_price` values in orders when a known currency mismatch occurred in the OMS.
--
-- Context:
-- The Order Management System (OMS) incorrectly stored prices in a local currency without converting to USD.
-- This led to `total_price` values being ~5.65x higher than expected (e.g., stored as pesos instead of dollars).
--
-- Goal:
-- Correct the affected records by applying a conversion rate (e.g., 0.1771 for MXN → USD).
-- Two main correction strategies are shown:
--   1. Update by specific `order_id`s.
--   2. Update by specific `order_created_date`s.
--
-- Why this was solved with SQL instead of a Cloud Function:
-- - Updates are simple, deterministic, and infrequent (one-off data fix).
-- - SQL is more transparent and auditable for data engineering teams reviewing BigQuery logs.
-- - This allows manual control over exactly which records are updated and how.
-- - Running native SQL avoids unnecessary orchestration overhead or latency from invoking Cloud Functions.
--
-- Best practice recommendation:
-- A production-grade implementation would still use a Cloud Function to:
--   1. Retrieve the correct `conversion_rate` dynamically from an external system or config file.
--   2. Trigger this SQL via the BigQuery API or use a parameterized stored procedure.
--   3. Optionally validate or log updates (e.g., to a `data_fixes_audit` table).
--
-- This hybrid approach allows the **efficiency of SQL** and **flexibility of code orchestration**.
--
-- The queries below use DECLARE for editable parameters, supporting safe re-use and quick patching.

DECLARE conversion_rate FLOAT64 DEFAULT 0.1771155684;

UPDATE
    `zubale.zubale.orders`
SET
    total_price = total_price * conversion_rate
WHERE order_id IN (
    11
)