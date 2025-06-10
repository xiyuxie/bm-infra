#!/bin/bash

# 10 seconds
QUEUE_WAITING=5

SUBSCRIPTION_NAME="$GCP_QUEUE-agent"

echo "git pull"
git pull

while true; do
  echo "Polling for message..."

  MESSAGE=$(gcloud pubsub subscriptions pull "$SUBSCRIPTION_NAME" \
    --project="$GCP_PROJECT_ID" \
    --limit=1 \
    --format="json")

  if [ -z "$MESSAGE" ] || [[ "$MESSAGE" == "[]" ]]; then
    echo "No messages found."
    sleep $QUEUE_WAITING
    continue
  fi

  # Extract ackId and base64-encoded message body
  ACK_ID=$(echo "$MESSAGE" | jq -r '.[0].ackId')
  BASE64_DATA=$(echo "$MESSAGE" | jq -r '.[0].message.data')

  # Decode base64 to string
  MESSAGE_BODY=$(echo "$BASE64_DATA" | base64 --decode)

  echo "Received message: $MESSAGE_BODY"

  # Parse key-value pairs
  declare -A kv
  IFS=';' read -ra PAIRS <<< "$MESSAGE_BODY"
  for pair in "${PAIRS[@]}"; do
    KEY="${pair%%=*}"
    VALUE="${pair#*=}"
    kv[$KEY]="$VALUE"
  done

  RECORD_ID="${kv[RecordId]}"  

  echo "Parsed RecordId: $RECORD_ID"  

  if [ -z "$RECORD_ID" ] || [ "$RECORD_ID" == "null" ]; then
    echo "Invalid or missing record_id. Skipping message without ack."
    continue
  fi
  
  # Update status to RUNNING
  echo "Setting record $RECORD_ID status to RUNNING..."
  gcloud spanner databases execute-sql "$GCP_DATABASE_ID" \
    --project="$GCP_PROJECT_ID" \
    --instance="$GCP_INSTANCE_ID" \
    --sql="UPDATE RunRecord SET Status='RUNNING', LastUpdate=CURRENT_TIMESTAMP() WHERE RecordId='$RECORD_ID'"

  gcloud pubsub subscriptions ack "$SUBSCRIPTION_NAME" \
    --project="$GCP_PROJECT_ID" \
    --ack-ids="$ACK_ID"
  echo "Message acknowledged."  
  
  # do the work
  echo "./scripts/agent/run_job.sh $RECORD_ID"
  ./scripts/agent/run_job.sh "$RECORD_ID"
  
done