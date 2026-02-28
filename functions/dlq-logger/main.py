import base64
import json

def process_dlq_event(event, context):
    """Triggered by a message on the events-dlq Pub/Sub topic."""
    
    # 1. Decode the raw payload
    if 'data' in event:
        try:
            payload = base64.b64decode(event['data']).decode('utf-8')
        except Exception as e:
            payload = f"Failed to decode base64: {str(e)}"
    else:
        payload = "No payload data provided"

    # 2. Extract the message attributes (which contain the DLQ retry counts)
    attributes = event.get('attributes', {})

    # 3. Format as a structured JSON log for Google Cloud Logging
    log_entry = {
        "severity": "ERROR",
        "message": "DEAD LETTER QUEUE ALERT: Failed message detected in pipeline.",
        "failed_payload": payload,
        "message_attributes": attributes,
        "event_id": context.event_id
    }

    # Print the JSON string so Cloud Logging picks it up as an ERROR
    print(json.dumps(log_entry))