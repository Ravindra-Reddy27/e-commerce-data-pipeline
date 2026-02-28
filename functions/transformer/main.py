import base64
import json
import os
from datetime import datetime, timezone
import functions_framework
from google.cloud import bigquery

# Retrieve configuration from environment variables
DATASET_ID = os.environ.get("BIGQUERY_DATASET", "events_dataset")
TABLE_ID = os.environ.get("BIGQUERY_STAGING_TABLE", "events_staging")

# Initialize the BigQuery client globally for performance
bq_client = bigquery.Client()

def transform_and_load(event, context):
    """Triggered by a Pub/Sub message. Transforms and loads to BigQuery."""
    
    # 1. Decode and Parse the JSON payload
    if 'data' not in event:
        raise ValueError("No data found in the event.")
        
    try:
        message_data = base64.b64decode(event['data']).decode('utf-8')
        event_data = json.loads(message_data)
    except Exception as e:
        print(f"Failed to decode or parse message: {e}")
        # Throwing the error triggers a retry, eventually routing to the DLQ
        raise 
        
    # 2. Validate required fields
    user_id = event_data.get("userId")
    event_type = event_data.get("eventType")
    
    if not user_id or not event_type:
        print(f"Invalid event schema: {event_data}")
        raise ValueError("Missing required fields: userId or eventType")

    # 3 & 4. Transform and enrich data
    # Stringify the payload field safely
    payload_raw = event_data.get("payload")
    payload_str = json.dumps(payload_raw) if payload_raw else None
    
    # Grab existing timestamp or create a new one, format as ISO 8601 string
    event_timestamp = event_data.get("timestamp")
    if not event_timestamp:
        event_timestamp = datetime.now(timezone.utc).isoformat()
        
    # Add the current ingestion timestamp
    ingestion_timestamp = datetime.now(timezone.utc).isoformat()
    
    # Create the exact row dictionary that matches our BigQuery schema
    row_to_insert = {
        "user_id": user_id,
        "event_type": event_type,
        "payload": payload_str,
        "event_timestamp": event_timestamp,
        "ingestion_timestamp": ingestion_timestamp
    }
    
    # 5. Stream the transformed record into BigQuery
    table_ref = bq_client.dataset(DATASET_ID).table(TABLE_ID)
    
    # insert_rows_json performs a streaming insert into BigQuery
    errors = bq_client.insert_rows_json(table_ref, [row_to_insert])
    
    if errors:
        print(f"Encountered errors while inserting rows: {errors}")
        raise RuntimeError(f"BigQuery insert failed: {errors}")
    else:
        print(f"Successfully inserted 1 row into {DATASET_ID}.{TABLE_ID}")