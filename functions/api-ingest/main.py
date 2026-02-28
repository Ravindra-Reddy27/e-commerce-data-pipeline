import os
import json
import functions_framework
from google.cloud import pubsub_v1

# Safe to define globally
PROJECT_ID = os.environ.get("GCP_PROJECT_ID", os.environ.get("GOOGLE_CLOUD_PROJECT"))
TOPIC_ID = "events-topic"

@functions_framework.http
def ingest_event(request):
    """HTTP Cloud Function to ingest e-commerce events."""
    try:
        request_json = request.get_json(silent=True)
        if not request_json:
            return ({"error": "Invalid or missing JSON payload"}, 400)
    except Exception:
        return ({"error": "Bad Request"}, 400)

    user_id = request_json.get("userId")
    event_type = request_json.get("eventType")

    if not user_id or not event_type:
        return ({"error": "Missing required fields: userId or eventType"}, 400)

    # FIX: Initialize the client INSIDE the function to avoid gRPC thread freezing
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(PROJECT_ID, TOPIC_ID)
    
    message_data = json.dumps(request_json).encode("utf-8")

    try:
        future = publisher.publish(topic_path, message_data)
        future.result() # Block until complete
        return ("Event Accepted", 202)
    except Exception as e:
        print(f"Error publishing message: {e}")
        return ({"error": f"Internal Server Error: {str(e)}"}, 500)