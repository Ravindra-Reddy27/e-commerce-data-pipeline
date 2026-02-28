import os
import functions_framework
from google.cloud import bigquery

# Initialize the BigQuery client
bq_client = bigquery.Client()

PROJECT_ID = os.environ.get("GCP_PROJECT_ID", os.environ.get("GOOGLE_CLOUD_PROJECT"))
DATASET_ID = os.environ.get("BIGQUERY_DATASET", "events_dataset")

@functions_framework.http
def run_etl(request):
    """HTTP Cloud Function triggered by Cloud Scheduler to run daily ETL."""
    
    # The exact SQL logic from the project specification
    query = f"""
        MERGE `{PROJECT_ID}.{DATASET_ID}.user_daily_summary` T
        USING (
            SELECT
                user_id,
                DATE(event_timestamp) as event_date,
                COUNT(*) as total_events,
                COUNT(DISTINCT event_type) as event_types_unique
            FROM `{PROJECT_ID}.{DATASET_ID}.events_staging`
            WHERE DATE(event_timestamp) = CURRENT_DATE('UTC')
            GROUP BY 1, 2
        ) S
        ON T.user_id = S.user_id AND T.event_date = S.event_date
        WHEN NOT MATCHED THEN
            INSERT (user_id, event_date, total_events, event_types_unique) 
            VALUES (user_id, event_date, total_events, event_types_unique)
        WHEN MATCHED THEN
            UPDATE SET 
                total_events = S.total_events, 
                event_types_unique = S.event_types_unique;
    """

    try:
        # Execute the query
        query_job = bq_client.query(query)
        query_job.result()  # Block until the job completes
        print(f"ETL job completed successfully. Merged data for {PROJECT_ID}.{DATASET_ID}")
        return ("ETL Execution Successful", 200)
    except Exception as e:
        print(f"ETL Job Failed: {str(e)}")
        return (f"Internal Server Error: {str(e)}", 500)