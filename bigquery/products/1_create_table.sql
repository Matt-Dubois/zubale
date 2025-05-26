CREATE TABLE `zubale.zubale.products`
(
	id				INT64 NOT NULL,
	name			STRING,
	category		STRING,
	price			FLOAT64
)

CLUSTER BY			category