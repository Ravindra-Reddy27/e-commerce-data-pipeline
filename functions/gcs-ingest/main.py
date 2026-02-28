import os
import json
import functions_framework
from google.cloud import pubsub_v1, storage

PROJECT_ID = os.environ.get("GCP_PROJECT_ID", os.environ.get("GOOGLE_CLOUD_PROJECT"))
TOPIC_ID = "events-topic"

# Cloud Storage trigger entry point
@functions_framework.cloud_event
def process_file_upload(cloud_event):
    """Triggered by a change to a Cloud Storage bucket."""
    data = cloud_event.data

    bucket_name = data["bucket"]
    file_name = data["name"]

    print(f"Processing file: {file_name} from bucket: {bucket_name}")

    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(file_name)

    # Download the file contents as a string
    file_contents = blob.download_as_text()

    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(PROJECT_ID, TOPIC_ID)

    publish_count = 0

    # Process each line in the newline-delimited JSON file
    for line in file_contents.splitlines():
        line = line.strip()
        if not line:
            continue
        
        try:
            # Validate it's proper JSON
            event_data = json.loads(line)
            
            # Repackage as bytes for Pub/Sub
            message_bytes = json.dumps(event_data).encode("utf-8")
            
            # Publish to Pub/Sub
            future = publisher.publish(topic_path, message_bytes)
            future.result() # Wait for confirmation
            publish_count += 1
            
        except json.JSONDecodeError as e:
            print(f"Skipping invalid JSON line: {line}. Error: {e}")
        except Exception as e:
            print(f"Error publishing line: {e}")

    print(f"Successfully published {publish_count} events to {TOPIC_ID}.")