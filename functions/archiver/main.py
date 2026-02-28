import base64
import os
from google.cloud import storage

# Get the project ID from the environment variables injected by Terraform
PROJECT_ID = os.environ.get("GCP_PROJECT_ID", os.environ.get("GOOGLE_CLOUD_PROJECT"))
RAW_BUCKET_NAME = f"{PROJECT_ID}-events-bucket-raw"

# Initialize the storage client globally to reuse the connection pool
storage_client = storage.Client()

# Gen 1 Pub/Sub triggered functions use 'event' and 'context'
def archive_event(event, context):
    """Background Cloud Function triggered by a Pub/Sub topic."""
    
    print(f"Processing Pub/Sub message ID: {context.event_id}")

    # 1. Decode the Pub/Sub message data
    if 'data' in event:
        # Pub/Sub messages are base64 encoded
        pubsub_message = base64.b64decode(event['data']).decode('utf-8')
    else:
        print("Error: No data found in the event.")
        return

    # 2. Prepare the GCS bucket upload
    # Using .bucket() instead of .get_bucket() to adhere to least privilege
    bucket = storage_client.bucket(RAW_BUCKET_NAME)
    
    # Create a unique filename using the context's event_id
    file_name = f"raw_event_{context.event_id}.json"
    blob = bucket.blob(file_name)

    # 3. Upload the raw string directly to the bucket
    blob.upload_from_string(pubsub_message, content_type="application/json")

    print(f"Successfully archived message to {RAW_BUCKET_NAME}/{file_name}")