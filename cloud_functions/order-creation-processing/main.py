from google.cloud import storage, bigquery
import functions_framework  # type: ignore


PROJECT_ID = "gede-lat-landing-dev"
DATASET_ID = "zubale"
TABLE_ID = "orders"
BUCKET_NAME = "order-full-results"


def main(request):

    storage_client = storage.Client()
    bq_client = bigquery.Client()

    bucket = storage_client.bucket(BUCKET_NAME)
    blobs = list(bucket.list_blobs(prefix="order-full-information"))

    csv_blobs = [blob for blob in blobs if blob.name.endswith(".csv")]

    if not csv_blobs:
        print("No hay archivos para procesar.")
        return "No hay archivos CSV para cargar", 200

    uris = [f"gs://{BUCKET_NAME}/{blob.name}" for blob in csv_blobs]

    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        autodetect=False,
        field_delimiter=",",
        write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
        schema=[
            bigquery.SchemaField("order_created_date", "DATE"),
            bigquery.SchemaField("order_id", "INT64"),
            bigquery.SchemaField("quantity", "INT64"),
            bigquery.SchemaField("product_id", "INT64"),
            bigquery.SchemaField("product_name", "STRING"),
            bigquery.SchemaField("total_price", "FLOAT64"),
        ],
    )

    table_ref = f"{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}"
    load_job = bq_client.load_table_from_uri(uris, table_ref, job_config=job_config)

    try:
        load_job.result()
        print(f"Cargados {len(uris)} archivos en un solo load job.")

        for blob in csv_blobs:
            blob.delete()
            print(f"Borrado: {blob.name}")

    except Exception as e:
        print(f"Error al cargar archivos: {e}")
        return f"Error: {e}", 500

    return f"Cargados {len(uris)} archivos en un solo job", 200
