-- Find the date with the maximum number of orders

-- 1. The table is partitioned by 'order_created_date', so grouping by this column
--    efficiently scans only the relevant partitions, reducing data processed and cost

-- 2. Using COUNT(DISTINCT order_id) ensures counting unique orders, not product line items

-- 3. If slightly less precision is acceptable, APPROX_COUNT_DISTINCT can be used for faster execution and lower cost,
--    but here it's commented because the exact count is preferred

-- 4. Partition pruning on 'order_created_date' makes queries scalable to millions of records

SELECT
    order_created_date,
    COUNT(DISTINCT order_id) AS total_orders
    -- Uncomment for approximate count with a minimal error margin (0.4%), useful for large datasets:
    -- APPROX_COUNT_DISTINCT(order_id) AS total_orders

FROM
    `zubale.zubale.orders`

GROUP BY
    order_created_date

ORDER BY
    total_orders DESC

LIMIT 1
