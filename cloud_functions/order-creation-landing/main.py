import csv
import tempfile
import os
import traceback
from datetime import datetime
import time
from collections import OrderedDict
from google.cloud import storage, bigquery
import functions_framework # type: ignore


PROJECT_ID = "gede-lat-landing-dev"
DATASET_ID = "zubale"
PRODUCTS_TABLE = f"{PROJECT_ID}.{DATASET_ID}.products"
DEST_BUCKET = "order-full-results"
CHUNK_SIZE = 10000
CACHE_LIMIT = 500


def lru_get(cache, key, fetch_func):
	if key in cache:
		cache.move_to_end(key)
		return cache[key]
	value = fetch_func(key)
	if value:
		cache[key] = value
		if len(cache) > CACHE_LIMIT:
			cache.popitem(last=False)
	return value


def fetch_product_from_bq(product_id, bq_client):

	'''
	aca en realidad estamos extrallendo toda la tabla porque es pequeña de bigquery,
	una solucion mas eficiente ya que estamos con ordenes seria usar el spanner y acceder al registro individual
	'''

	query = f"""
		SELECT id, name, price
		FROM `{PRODUCTS_TABLE}`
		WHERE id = @pid
		LIMIT 1
	"""

	job = bq_client.query(
		query,
		job_config=bigquery.QueryJobConfig(
			query_parameters=[
				bigquery.ScalarQueryParameter("pid", "INT64", product_id)
			]
		)
	)

	row = next(iter(job), None)
	if row:
		return {"name": row["name"], "price": row["price"]}
	return None


def write_chunk_to_gcs(buffer, chunk_id, storage_client):
	current_time = datetime.utcnow().strftime("%Y-%m-%d-%H%M%S") + f"-{time.time_ns()}"
	temp_file = tempfile.NamedTemporaryFile("w", delete=False, newline="")
	writer = csv.DictWriter(temp_file, fieldnames=[
		"order_created_date", "order_id", "quantity", "product_id",
		"product_name", "total_price"
	])
	writer.writeheader()
	writer.writerows(buffer)
	temp_file.close()

	dest_blob = storage_client.bucket(DEST_BUCKET).blob(
		f"order-full-information-{current_time}-chunk{chunk_id}.csv"
	)
	dest_blob.upload_from_filename(temp_file.name)
	os.unlink(temp_file.name)


@functions_framework.cloud_event
def main(cloud_event: functions_framework.CloudEvent):

	try:
		event = cloud_event.get_data()
		file_name = event.get('name', '')
		bucket_name = event.get('bucket', '')

		storage_client = storage.Client()
		bq_client = bigquery.Client()
		bucket = storage_client.bucket(bucket_name)
		blob = bucket.blob(file_name)

		temp_input = tempfile.NamedTemporaryFile(delete=False)
		blob.download_to_filename(temp_input.name)

		product_cache = OrderedDict()
		buffer = []
		chunk_id = 0

		with open(temp_input.name, newline='') as csvfile:
			reader = csv.DictReader(csvfile)
			for row in reader:
				try:
					product_id = int(row["product_id"])
					quantity = int(row["quantity"])
				except Exception:
					# skip rows with invalid data
					# here we should other mechanism with tickets and alerts
					continue

				product = lru_get(
					product_cache, str(product_id),
					lambda pid: fetch_product_from_bq(int(pid), bq_client)
				)

				if not product:
					# skip unknown product
					continue

				buffer.append({
					"order_created_date": row["created_date"].strip("'"),
					"order_id": row["id"],
					"quantity": quantity,
					"product_id": product_id,
					"product_name": product["name"],
					"total_price": product["price"]
				})

				if len(buffer) >= CHUNK_SIZE:
					write_chunk_to_gcs(buffer, chunk_id, storage_client)
					buffer.clear()
					chunk_id += 1

		if buffer:
			write_chunk_to_gcs(buffer, chunk_id, storage_client)

		os.unlink(temp_input.name)
		print(f"Procesado {file_name} en {chunk_id + 1} chunks.")

	except:
		traceback.print_exc()
		return {'status_code': 500, 'message': 'Fatal error'}
