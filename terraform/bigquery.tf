# terraform/bigquery.tf

# 1. Create the BigQuery Dataset
resource "google_bigquery_dataset" "events_dataset" {
  dataset_id                 = var.bigquery_dataset_id
  description                = "Dataset for e-commerce event pipeline"
  location                   = var.gcp_region
  delete_contents_on_destroy = true # Useful for development/cleanup
}





# 2. Create the Staging Table
resource "google_bigquery_table" "events_staging" {
  dataset_id = google_bigquery_dataset.events_dataset.dataset_id
  table_id   = var.bigquery_staging_table_id
  deletion_protection = false  # Allows Terraform to delete the table during cleanup
  # The exact schema required by the project specification
  schema = <<EOF
[
  {
    "name": "user_id",
    "type": "STRING",
    "mode": "REQUIRED"
  },
  {
    "name": "event_type",
    "type": "STRING",
    "mode": "REQUIRED"
  },
  {
    "name": "payload",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "event_timestamp",
    "type": "TIMESTAMP",
    "mode": "REQUIRED"
  },
  {
    "name": "ingestion_timestamp",
    "type": "TIMESTAMP",
    "mode": "REQUIRED"
  }
]
EOF
}






# Create the Production Analytics Table (user_daily_summary)
resource "google_bigquery_table" "user_daily_summary" {
  dataset_id = google_bigquery_dataset.events_dataset.dataset_id
  table_id   = "user_daily_summary"
  deletion_protection = false

  # Time-unit partitioning by Day on event_date
  time_partitioning {
    type  = "DAY"
    field = "event_date"
  }

  # Clustered by user_id
  clustering = ["user_id"]

  # The exact schema required by the specification
  schema = <<EOF
[
  {
    "name": "user_id",
    "type": "STRING",
    "mode": "REQUIRED"
  },
  {
    "name": "event_date",
    "type": "DATE",
    "mode": "REQUIRED"
  },
  {
    "name": "total_events",
    "type": "INTEGER",
    "mode": "REQUIRED"
  },
  {
    "name": "event_types_unique",
    "type": "INTEGER",
    "mode": "REQUIRED"
  }
]
EOF
}