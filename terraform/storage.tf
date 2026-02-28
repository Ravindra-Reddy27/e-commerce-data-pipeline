# terraform/storage.tf

# Create the bucket for file uploads
resource "google_storage_bucket" "events_upload_bucket" {
  name          = "${var.gcp_project_id}-events-bucket-uploads"
  location      = var.gcp_region
  force_destroy = true # Allows Terraform to delete the bucket even if it contains files during cleanup
}

# Create the bucket for raw archived events
resource "google_storage_bucket" "events_raw_bucket" {
  name          = "${var.gcp_project_id}-events-bucket-raw"
  location      = var.gcp_region
  force_destroy = true 
}