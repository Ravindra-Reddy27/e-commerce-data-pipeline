# terraform/variables.tf

variable "gcp_project_id" {
  description = "The ID of the Google Cloud project"
  type        = string
}

variable "gcp_region" {
  description = "The default region for GCP resources"
  type        = string
  default     = "us-central1"
}

variable "bigquery_dataset_id" {
  description = "The ID of the BigQuery dataset"
  type        = string
  default     = "events_dataset"
}

variable "bigquery_staging_table_id" {
  description = "The ID of the BigQuery staging table"
  type        = string
  default     = "events_staging"
}