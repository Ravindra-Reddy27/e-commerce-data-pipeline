# 1. Zip the Transformer code
data "archive_file" "transformer_zip" {
  type        = "zip"
  source_dir  = "../functions/transformer"
  output_path = "../functions/transformer.zip"
  excludes    = ["venv", "__pycache__"]
}

# 2. Upload the zip to the source bucket
resource "google_storage_bucket_object" "transformer_source" {
  name   = "transformer_${data.archive_file.transformer_zip.output_md5}.zip"
  bucket = google_storage_bucket.function_source_bucket.name
  source = data.archive_file.transformer_zip.output_path
}

# 3. Deploy the Transformer Cloud Function (Inside functions.tf)
resource "google_cloudfunctions_function" "transformer" {
  name                  = "pubsub-to-bigquery-transformer"
  description           = "Validates, transforms, and streams events to BigQuery"
  runtime               = "python311"
  available_memory_mb   = 256
  
  source_archive_bucket = google_storage_bucket.function_source_bucket.name
  source_archive_object = google_storage_bucket_object.transformer_source.name
  
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.events_topic.id
    
    # REQUIRED: Force the function to retry on failure
    failure_policy {
      retry = true
    }
  }

  entry_point           = "transform_and_load"
  service_account_email = google_service_account.processing_sa.email

  environment_variables = {
    GCP_PROJECT_ID         = var.gcp_project_id
    BIGQUERY_DATASET       = var.bigquery_dataset_id
    BIGQUERY_STAGING_TABLE = var.bigquery_staging_table_id
  }
}