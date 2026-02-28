# 1. Zip the Archiver code
data "archive_file" "archiver_zip" {
  type        = "zip"
  source_dir  = "../functions/archiver"
  output_path = "../functions/archiver.zip"
  excludes    = ["venv", "__pycache__"]
}

# 2. Upload the zip to the source bucket
resource "google_storage_bucket_object" "archiver_source" {
  name   = "archiver_${data.archive_file.archiver_zip.output_md5}.zip"
  bucket = google_storage_bucket.function_source_bucket.name
  source = data.archive_file.archiver_zip.output_path
}

# 3. Deploy the Archiver Cloud Function
resource "google_cloudfunctions_function" "archiver" {
  name                  = "archiver"
  description           = "Subscribes to events-topic and archives raw payloads to GCS"
  runtime               = "python311"
  available_memory_mb   = 256
  
  source_archive_bucket = google_storage_bucket.function_source_bucket.name
  source_archive_object = google_storage_bucket_object.archiver_source.name
  
  # Event Trigger configuration for Pub/Sub
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.events_topic.id
  }

  entry_point           = "archive_event"
  
  # Principle of least privilege: Use the dedicated processing service account
  service_account_email = google_service_account.processing_sa.email

  environment_variables = {
    GCP_PROJECT_ID = var.gcp_project_id
  }
}