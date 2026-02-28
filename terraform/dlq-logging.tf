# 1. Zip the DLQ Logger code
data "archive_file" "dlq_logger_zip" {
  type        = "zip"
  source_dir  = "../functions/dlq-logger"
  output_path = "../functions/dlq_logger.zip"
  excludes    = ["venv", "__pycache__"]
}

# 2. Upload the zip to the source bucket
resource "google_storage_bucket_object" "dlq_logger_source" {
  name   = "dlq_logger_${data.archive_file.dlq_logger_zip.output_md5}.zip"
  bucket = google_storage_bucket.function_source_bucket.name
  source = data.archive_file.dlq_logger_zip.output_path
}

# 3. Deploy the DLQ Logger Cloud Function
resource "google_cloudfunctions_function" "dlq_logger" {
  name                  = "dlq-logger"
  description           = "Logs failed messages from the DLQ to Cloud Logging"
  runtime               = "python311"
  available_memory_mb   = 256
  
  source_archive_bucket = google_storage_bucket.function_source_bucket.name
  source_archive_object = google_storage_bucket_object.dlq_logger_source.name
  
  # Event Trigger configuration: Listen to the DLQ topic!
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.events_dlq_topic.id
  }

  entry_point           = "process_dlq_event"
  
  # We can safely reuse the processing service account
  service_account_email = google_service_account.processing_sa.email

  environment_variables = {
    GCP_PROJECT_ID = var.gcp_project_id
  }
}