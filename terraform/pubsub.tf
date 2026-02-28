# terraform/pubsub.tf

# Create the main Pub/Sub topic for incoming events
resource "google_pubsub_topic" "events_topic" {
  name = "events-topic"

  # Ensure APIs are enabled before creating this resource
  depends_on = [google_project_service.apis]
}

