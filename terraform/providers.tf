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
    bucket = "internship-review-509606-tfstate"  # Add your bucket name here like : YOUR_PROJECT_ID-tfstate . 
    prefix = "terraform/state"
  }
}