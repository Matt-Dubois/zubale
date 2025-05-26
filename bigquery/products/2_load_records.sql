CREATE OR REPLACE EXTERNAL TABLE `zubale.zubale.products_stg`
(
  id INT64,
  name STRING,
  category STRING,
  price FLOAT64
)

OPTIONS (
  format = 'CSV',
  uris = ['gs://zubale/products.csv'],
  skip_leading_rows = 1
)