
#--------------------------------- API Ingest Function ---------------------------------#


# 1. Create a bucket to store the zipped Cloud Function source code
resource "google_storage_bucket" "function_source_bucket" {
  name     = "${var.gcp_project_id}-function-source"
  location = var.gcp_region
}

# 2. Automatically zip the local Python code
data "archive_file" "api_ingest_zip" {
  type        = "zip"
  source_dir  = "../functions/api-ingest"
  output_path = "../functions/api_ingest.zip"
}

# 3. Upload the zip file to the storage bucket
resource "google_storage_bucket_object" "api_ingest_source" {
  name   = "api_ingest_${data.archive_file.api_ingest_zip.output_md5}.zip"
  bucket = google_storage_bucket.function_source_bucket.name
  source = data.archive_file.api_ingest_zip.output_path
}

# 4. Deploy the Cloud Function
resource "google_cloudfunctions_function" "api_ingest" {
  name                  = "api-ingest"
  description           = "HTTP ingestion endpoint for e-commerce events"
  runtime               = "python311" 
  available_memory_mb   = 256
  
  # Point to the zipped code in the bucket
  source_archive_bucket = google_storage_bucket.function_source_bucket.name
  source_archive_object = google_storage_bucket_object.api_ingest_source.name
  
  # Configure the trigger and entry point
  trigger_http          = true
  entry_point           = "ingest_event"
  
  # STRICT IAM REQUIREMENT: Attach the specific service account
  service_account_email = google_service_account.ingestion_sa.email

  # Pass environment variables to the Python code
  environment_variables = {
    GCP_PROJECT_ID = var.gcp_project_id
  }
}

# 5. Make the HTTP endpoint publicly accessible (so the e-commerce site can hit it)
resource "google_cloudfunctions_function_iam_member" "public_invoker" {
  project        = google_cloudfunctions_function.api_ingest.project
  region         = google_cloudfunctions_function.api_ingest.region
  cloud_function = google_cloudfunctions_function.api_ingest.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}

# Output the live URL after deployment so we can test it
output "api_ingest_url" {
  value       = google_cloudfunctions_function.api_ingest.https_trigger_url
  description = "The live public URL of the api-ingest Cloud Function"
}


#--------------------------------- GCS Ingest Function ---------------------------------#


# 1. Zip the GCS ingest code
data "archive_file" "gcs_ingest_zip" {
  type        = "zip"
  source_dir  = "../functions/gcs-ingest"
  output_path = "../functions/gcs_ingest.zip"
  excludes    = ["venv", "__pycache__"]
}

# 2. Upload the zip to the source bucket
resource "google_storage_bucket_object" "gcs_ingest_source" {
  name   = "gcs_ingest_${data.archive_file.gcs_ingest_zip.output_md5}.zip"
  bucket = google_storage_bucket.function_source_bucket.name
  source = data.archive_file.gcs_ingest_zip.output_path
}

# 3. Deploy the GCS Ingest Cloud Function
resource "google_cloudfunctions_function" "gcs_ingest" {
  name                  = "gcs-ingest"
  description           = "Processes uploaded JSONL files and publishes to Pub/Sub"
  runtime               = "python311"
  available_memory_mb   = 256
  
  source_archive_bucket = google_storage_bucket.function_source_bucket.name
  source_archive_object = google_storage_bucket_object.gcs_ingest_source.name
  
  # Event Trigger configuration for GCS file uploads
  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.events_upload_bucket.name
  }

  entry_point           = "process_file_upload"
  
  # Principle of least privilege: Use the same ingestion service account
  service_account_email = google_service_account.ingestion_sa.email

  environment_variables = {
    GCP_PROJECT_ID = var.gcp_project_id
  }
}