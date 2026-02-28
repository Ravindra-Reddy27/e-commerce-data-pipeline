# terraform/dlq.tf

data "google_project" "project" {}

# 1. Topic "events-dlq"
resource "google_pubsub_topic" "events_dlq_topic" {
  name = "events-dlq" 
}

# 2. DLQ Subscription
resource "google_pubsub_subscription" "events_dlq_sub" {
  name  = "events-dlq-sub"
  topic = google_pubsub_topic.events_dlq_topic.id
}

# 3. Grant Google's hidden Pub/Sub agent permission to publish to the DLQ
resource "google_pubsub_topic_iam_member" "dlq_publisher" {
  topic  = google_pubsub_topic.events_dlq_topic.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

# 4. Grant the agent permission to acknowledge messages
resource "google_project_iam_member" "dlq_subscriber" {
  project = var.gcp_project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}