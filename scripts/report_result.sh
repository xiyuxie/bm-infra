#!/bin/bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <RECORD_ID>"
  exit 1
fi

RECORD_ID="$1"
RESULT_FILE="artifacts/${RECORD_ID}.result"

# Default to just updating status if file is missing
if [ ! -f "$RESULT_FILE" ]; then
  echo "Result file not found: $RESULT_FILE. Marking status as FAILED."

  SQL="UPDATE RunRecord SET Status='FAILED', LastUpdate=CURRENT_TIMESTAMP() WHERE RecordId = '${RECORD_ID}';"

  echo "Executing SQL:"
  echo "$SQL"

  gcloud spanner databases execute-sql "$GCP_DATABASE_ID" \
    --project="$GCP_PROJECT_ID" \
    --instance="$GCP_INSTANCE_ID" \
    --sql="$SQL"

  exit 0
fi

# Parse result file
assignments=""
while IFS='=' read -r key value; do
  if [[ -n "$key" && -n "$value" ]]; then
    if [[ "$value" =~ ^[0-9.]+$ ]]; then
      assignments+="${key}=${value}, "
    else
      assignments+="${key}='${value}', "
    fi
  fi
done < "$RESULT_FILE"

# Clean trailing comma
assignments="${assignments%, }"

# Add status + timestamp
assignments="${assignments}, Status='COMPLETED', LastUpdate=CURRENT_TIMESTAMP()"

# Final SQL
SQL="UPDATE RunRecord SET ${assignments} WHERE RecordId = '${RECORD_ID}';"

echo "Executing SQL:"
echo "$SQL"

# Execute
gcloud spanner databases execute-sql "$GCP_DATABASE_ID" \
  --project="$GCP_PROJECT_ID" \
  --instance="$GCP_INSTANCE_ID" \
  --sql="$SQL"
