-- This query finds the top 3 most demanded categories by total quantity sold

-- 1. The JOIN benefits from clustering on orders.product_id.
--    Since the 'orders' table is clustered by 'product_id',
--    BigQuery can efficiently locate relevant data blocks during the join.

-- 2. The 'products' table contains the category information.
--    Joining on product_id (orders) = id (products) leverages this key relationship.

-- 3. If the 'products' table is relatively small (less than ~100 MB),
--    BigQuery will perform a broadcast join, loading the entire products table into RAM,
--    which maximizes join performance and reduces shuffle costs.

-- 4. An even more efficient approach, especially in a static catalog environment,
--    would be to denormalize the 'category' column directly into the 'orders' table at ingestion time,
--    thereby avoiding the join completely and reducing query cost.
--    I would add the category on the function 'order-creation-landing'
--    so we can have the category in which the product was present at the time the product was bought

-- 5. Additionally, if needed, filtering by date (on orders.order_created_date, which partitions the table)
--    can significantly reduce scanned data and speed up the query.

SELECT
    p.category,
    SUM(o.quantity) AS total_quantity

FROM
    `gede-lat-landing-dev.zubale.orders` o

JOIN
    `gede-lat-landing-dev.zubale.products` p
ON
    o.product_id = p.id

-- Optional: uncomment below to restrict to recent orders only, improving scan efficiency
-- WHERE
    -- o.order_created_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH)

GROUP BY
    p.category

ORDER BY
    total_quantity DESC

LIMIT 3