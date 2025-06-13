#!/bin/bash

# === Usage ===
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 JOB_REFERENCE"
  exit 1
fi

JOB_REFERENCE="$1"

echo "Querying records for JobReference='$JOB_REFERENCE'..."

# Fetch records from Spanner, now including RecordId to construct the log URL
RECORDS_JSON=$(gcloud spanner databases execute-sql "$GCP_DATABASE_ID" \
  --instance="$GCP_INSTANCE_ID" \
  --project="$GCP_PROJECT_ID" \
  --sql="SELECT Model, Status, Device, RecordId FROM RunRecord WHERE JobReference='$JOB_REFERENCE';" \
  --format=json)

# Check if any records were found
RECORD_COUNT=$(echo "$RECORDS_JSON" | jq '.rows | length')

if [ "$RECORD_COUNT" -eq 0 ]; then
  echo "No matching records found for JobReference='$JOB_REFERENCE'."
  exit 0
fi

echo "Found $RECORD_COUNT matching records for JobReference='$JOB_REFERENCE':"
echo ""

# Print header for the table
printf "%-30s %-15s %-15s %s\n" "Model" "Status" "Device" "VLLM Log"
printf "%-30s %-15s %-15s %s\n" "------------------------------" "---------------" "---------------" "------------------------------------------------------------------------------------------------"

# Parse JSON and print each row
echo "$RECORDS_JSON" | jq -c '.rows[]' | while read -r row; do
  MODEL=$(echo "$row" | jq -r '.[0]')
  STATUS=$(echo "$row" | jq -r '.[1]')
  DEVICE=$(echo "$row" | jq -r '.[2]')
  RECORD_ID=$(echo "$row" | jq -r '.[3]') # Get RecordId

  # Construct VLLM Log URL
  VLLM_LOG_URL="https://storage.mtls.cloud.google.com/$GCS_BUCKET/job_logs/$RECORD_ID/static_vllm_log.txt"

  printf "%-30s %-15s %-15s %s\n" "$MODEL" "$STATUS" "$DEVICE" "$VLLM_LOG_URL"
done