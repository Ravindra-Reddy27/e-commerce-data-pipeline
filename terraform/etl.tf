# 1. Zip the ETL code
data "archive_file" "daily_etl_zip" {
  type        = "zip"
  source_dir  = "../functions/daily-etl"
  output_path = "../functions/daily_etl.zip"
  excludes    = ["venv", "__pycache__"]
}

# 2. Upload the zip
resource "google_storage_bucket_object" "daily_etl_source" {
  name   = "daily_etl_${data.archive_file.daily_etl_zip.output_md5}.zip"
  bucket = google_storage_bucket.function_source_bucket.name
  source = data.archive_file.daily_etl_zip.output_path
}

# 3. Deploy the ETL Cloud Function
resource "google_cloudfunctions_function" "daily_etl" {
  name                  = "daily-etl"
  description           = "Runs daily ETL aggregation on BigQuery"
  runtime               = "python311"
  available_memory_mb   = 256
  
  source_archive_bucket = google_storage_bucket.function_source_bucket.name
  source_archive_object = google_storage_bucket_object.daily_etl_source.name
  
  trigger_http          = true
  entry_point           = "run_etl"
  
  # Attach the specific ETL service account
  service_account_email = google_service_account.etl_sa.email

  environment_variables = {
    GCP_PROJECT_ID   = var.gcp_project_id
    BIGQUERY_DATASET = var.bigquery_dataset_id
  }
}

# 4. Create the Cloud Scheduler Job to trigger the function
resource "google_cloud_scheduler_job" "daily_etl_trigger" {
  name             = "trigger-daily-etl"
  description      = "Triggers the daily-etl Cloud Function at 01:00 UTC"
  schedule         = "0 1 * * *" # 01:00 UTC daily
  time_zone        = "UTC"
  attempt_deadline = "320s"

  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions_function.daily_etl.https_trigger_url

    # Secure the endpoint using OIDC so only the Scheduler can invoke it
    oidc_token {
      service_account_email = google_service_account.etl_sa.email
    }
  }
}

# 5. Grant the ETL SA permission to invoke the function via Scheduler
resource "google_cloudfunctions_function_iam_member" "etl_invoker" {
  project        = google_cloudfunctions_function.daily_etl.project
  region         = google_cloudfunctions_function.daily_etl.region
  cloud_function = google_cloudfunctions_function.daily_etl.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${google_service_account.etl_sa.email}"
}