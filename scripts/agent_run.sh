#!/bin/bash

# 10 seconds
QUEUE_WAITING=5

SUBSCRIPTION_NAME="$GCP_QUEUE-agent"
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

  # Simulate processing success
  if [ -n "$RECORD_ID" ]; then
    gcloud pubsub subscriptions ack "$SUBSCRIPTION_NAME" \
      --project="$GCP_PROJECT_ID" \
      --ack-ids="$ACK_ID"
    echo "Message acknowledged."
  else
    echo "Invalid message. Skipping ack."
  fi  
done