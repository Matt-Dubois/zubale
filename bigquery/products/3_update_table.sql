MERGE INTO `zubale.zubale.products` T
USING `zubale.zubale.products_stg` S
ON T.id = CAST(S.id AS INT64)

WHEN MATCHED THEN
	UPDATE SET
		name = S.name,
		category = S.category,
		price = CAST(S.price AS FLOAT64)

WHEN NOT MATCHED THEN
	INSERT (id, name, category, price)
	VALUES (
		CAST(S.id AS INT64),
		S.name,
		S.category,
		CAST(S.price AS FLOAT64)
	)
