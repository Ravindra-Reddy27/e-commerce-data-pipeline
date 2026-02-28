# terraform/iam.tf

# Create the dedicated service account for the ingestion functions
resource "google_service_account" "ingestion_sa" {
  account_id   = "ingestion-sa"
  display_name = "Ingestion Service Account"
  description  = "Used by api-ingest and gcs-ingest Cloud Functions to publish events"
}

# Grant the ingestion service account the pubsub.publisher role on the topic
resource "google_pubsub_topic_iam_member" "ingestion_publisher_binding" {
  project = var.gcp_project_id
  topic   = google_pubsub_topic.events_topic.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.ingestion_sa.email}"
}

# Grant the ingestion service account permission to read files from the upload bucket
resource "google_storage_bucket_iam_member" "ingestion_sa_storage_viewer" {
  bucket = google_storage_bucket.events_upload_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.ingestion_sa.email}"
}






# Create the processing service account
resource "google_service_account" "processing_sa" {
  account_id   = "processing-sa"
  display_name = "Processing Service Account"
  description  = "Used by archiver and transformer functions"
}

# Grant necessary roles to the processing service account
resource "google_project_iam_member" "processing_pubsub_subscriber" {
  project = var.gcp_project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.processing_sa.email}"
}

resource "google_project_iam_member" "processing_storage_creator" {
  project = var.gcp_project_id
  role    = "roles/storage.objectCreator"
  member  = "serviceAccount:${google_service_account.processing_sa.email}"
}

# (We will add the BigQuery role when we build the Transformer)

# Grant the processing service account permission to write to BigQuery
resource "google_project_iam_member" "processing_bigquery_editor" {
  project = var.gcp_project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.processing_sa.email}"
}





# Create the ETL service account
resource "google_service_account" "etl_sa" {
  account_id   = "etl-sa"
  display_name = "ETL Service Account"
  description  = "Used by the daily-etl Cloud Function"
}

# Grant the ETL service account permission to run BigQuery jobs
resource "google_project_iam_member" "etl_bq_jobuser" {
  project = var.gcp_project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.etl_sa.email}"
}

# (Note: To successfully read/write data, it also needs Data Editor access to the specific dataset)
resource "google_bigquery_dataset_iam_member" "etl_bq_dataeditor" {
  dataset_id = google_bigquery_dataset.events_dataset.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.etl_sa.email}"
}