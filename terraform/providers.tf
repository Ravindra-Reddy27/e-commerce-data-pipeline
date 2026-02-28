terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

# terraform/backend.tf
terraform {
  backend "gcs" {
    bucket = "${var.gcp_project_id}-tfstate"
    prefix = "terraform/state"
  }
}