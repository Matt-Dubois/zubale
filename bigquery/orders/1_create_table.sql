CREATE TABLE `zubale.zubale.orders`
(
  order_created_date    DATE,
  order_id              INT64,
  product_id            INT64,
  product_name          STRING,
  quantity              INT64,
  total_price           FLOAT64
)

PARTITION BY            order_created_date
CLUSTER BY              product_id
