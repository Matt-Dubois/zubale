-- Find the most demanded product by total quantity sold

-- 1. Grouping by 'product_id' instead of 'product_name' is much more efficient and reliable:
--    - 'product_id' is an integer, which reduces storage and processing overhead.
--    - Using IDs avoids costly string comparisons and grouping

-- 2. Clustering the 'orders' table by 'product_id' improves this query's performance significantly,
--    since BigQuery can skip irrelevant blocks and quickly aggregate grouped data

-- 3. Even if not initially requested, adding 'product_id' to the schema is critical for scaling and query speed

-- 4. Ordering by total_quantity and limiting results is efficient after clustering and partition pruning

SELECT
    product_id,
    SUM(quantity) AS total_quantity

FROM
    `zubale.zubale.orders`

GROUP BY
    product_id

ORDER BY
    total_quantity DESC

LIMIT 1
