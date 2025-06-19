#!/bin/bash

set -euo pipefail

# === Usage ===
# ./script.sh [RUN_TYPES] [TRY_COUNT]
# RUN_TYPES: comma-separated (default: HOURLY,AUTOTUNE)
# TRY_COUNT: integer (default: 2)

RUN_TYPES="${1:-HOURLY,AUTOTUNE}"
TRY_COUNT="${2:-2}"

# Ensure these are exported:
# export GCP_PROJECT_ID
# export GCP_INSTANCE_ID
# export GCP_DATABASE_ID

# Fixed time window: between 3 days ago and 10 minutes ago
TIME_RANGE_START="TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 3 DAY)"
TIME_RANGE_END="TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 10 MINUTE)"

echo "Querying records with:"
echo "- Status = 'FAILED'"
echo "- RunType IN ($RUN_TYPES)"
echo "- LastUpdate BETWEEN $TIME_RANGE_START AND $TIME_RANGE_END"
echo "- TryCount < $TRY_COUNT"

# Format RunTypes for SQL IN clause
RUN_TYPES_SQL=$(echo "$RUN_TYPES" | awk -F',' '{for (i=1;i<=NF;++i) printf "\047%s\047%s", $i, (i==NF ? "" : ", ")}')

SQL="
SELECT RecordId, Device
FROM RunRecord
WHERE Status='FAILED'
  AND RunType IN ($RUN_TYPES_SQL)
  AND TryCount < $TRY_COUNT
  AND LastUpdate BETWEEN $TIME_RANGE_START AND $TIME_RANGE_END;
"

RECORDS_JSON=$(gcloud spanner databases execute-sql "$GCP_DATABASE_ID" \
  --instance="$GCP_INSTANCE_ID" \
  --project="$GCP_PROJECT_ID" \
  --sql="$SQL" \
  --format=json)

RECORD_COUNT=$(echo "$RECORDS_JSON" | jq '.rows | length')

if [ "$RECORD_COUNT" -eq 0 ]; then
  echo "No matching records found."
  exit 0
fi

echo "Found $RECORD_COUNT matching records."

echo "$RECORDS_JSON" | jq -c '.rows[]' | while read -r row; do
  RECORD_ID=$(echo "$row" | jq -r '.[0]')
  DEVICE=$(echo "$row" | jq -r '.[1]')
  QUEUE_TOPIC="vllm-bm-queue-$DEVICE"

  if ! gcloud pubsub topics describe "$QUEUE_TOPIC" --project="$GCP_PROJECT_ID" &>/dev/null; then
    echo "Topic '$QUEUE_TOPIC' does not exist. Skipping RecordId=$RECORD_ID."
    continue
  fi

  echo "Updating RecordId=$RECORD_ID to RECREATED..."

  gcloud spanner databases execute-sql "$GCP_DATABASE_ID" \
    --instance="$GCP_INSTANCE_ID" \
    --project="$GCP_PROJECT_ID" \
    --sql="UPDATE RunRecord SET Status='RECREATED', LastUpdate=PENDING_COMMIT_TIMESTAMP() WHERE RecordId='$RECORD_ID';"

  echo "Publishing RecordId=$RECORD_ID to $QUEUE_TOPIC..."

  gcloud pubsub topics publish "$QUEUE_TOPIC" \
    --project="$GCP_PROJECT_ID" \
    --message="RecordId=$RECORD_ID"
done
