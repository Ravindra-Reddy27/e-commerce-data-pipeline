# terraform/monitoring.tf

# Define the custom Cloud Monitoring dashboard
resource "google_monitoring_dashboard" "pipeline_dashboard" {
  dashboard_json = <<EOF
  {
    "displayName": "E-Commerce Pipeline Operations",
    "gridLayout": {
      "columns": "2",
      "widgets": [
        {
          "title": "1. Pub/Sub: events-topic (Published & Unacknowledged)",
          "xyChart": {
            "dataSets": [
              {
                "timeSeriesQuery": {
                  "timeSeriesFilter": {
                    "filter": "metric.type=\"pubsub.googleapis.com/topic/send_request_count\" resource.type=\"pubsub_topic\" resource.label.\"topic_id\"=\"events-topic\""
                  }
                }
              },
              {
                "timeSeriesQuery": {
                  "timeSeriesFilter": {
                    "filter": "metric.type=\"pubsub.googleapis.com/subscription/num_unacked_messages_by_region\" resource.type=\"pubsub_subscription\""
                  }
                }
              }
            ]
          }
        },
        {
          "title": "2. Pub/Sub: events-dlq (Dead Letter Queue)",
          "xyChart": {
            "dataSets": [
              {
                "timeSeriesQuery": {
                  "timeSeriesFilter": {
                    "filter": "metric.type=\"pubsub.googleapis.com/topic/send_request_count\" resource.type=\"pubsub_topic\" resource.label.\"topic_id\"=\"events-dlq\""
                  }
                }
              }
            ]
          }
        },
        {
          "title": "3. Cloud Functions: Executions & Errors",
          "xyChart": {
            "dataSets": [
              {
                "timeSeriesQuery": {
                  "timeSeriesFilter": {
                    "filter": "metric.type=\"cloudfunctions.googleapis.com/function/execution_count\" resource.type=\"cloud_function\""
                  }
                }
              }
            ]
          }
        },
        {
          "title": "4. BigQuery: events_staging Inserted Rows",
          "xyChart": {
            "dataSets": [
              {
                "timeSeriesQuery": {
                  "timeSeriesFilter": {
                    "filter": "metric.type=\"bigquery.googleapis.com/storage/uploaded_row_count\" resource.type=\"bigquery_dataset\" resource.label.\"dataset_id\"=\"events_dataset\"",
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "perSeriesAligner": "ALIGN_SUM"
                    }
                  }
                }
              }
            ]
          }
        }
      ]
    }
  }
  EOF
}
