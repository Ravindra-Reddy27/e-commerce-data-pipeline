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
    bucket = "e-commerce-pipeline-488411-tfstate"
    prefix = "terraform/state"
  }
}