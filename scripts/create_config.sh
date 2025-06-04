#!/bin/bash

# === Usage check ===
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <RECORD_ID>"
  exit 1
fi

# === Config ===

RECORD_ID="$1"
ENV_FILE="${RECORD_ID}.env"

# === Query and extract fields ===
gcloud spanner databases execute-sql "$GCP_DATABASE_ID" \
  --instance="$GCP_INSTANCE_ID" \
  --project="$GCP_PROJECT_ID" \
  --sql="SELECT MaxNumSeqs, MaxNumBatchedTokens, InputLen, OutputLen FROM RunRecord WHERE RecordId = '$RECORD_ID';" \
  --format="csv[no-heading]" > tmp.csv

# === Parse CSV and write to .env file ===
if [ -s tmp.csv ]; then
  IFS=',' read -r MaxNumSeqs MaxNumBatchedTokens InputLen OutputLen < tmp.csv

  cat <<EOF > "$ENV_FILE"
MaxNumSeqs=${MaxNumSeqs}
MaxNumBatchedTokens=${MaxNumBatchedTokens}
InputLen=${InputLen}
OutputLen=${OutputLen}
EOF

  echo "Saved variables to $ENV_FILE"
  rm tmp.csv
else
  echo "No record found for RecordId = $RECORD_ID"
  rm -f tmp.csv
  exit 1
fi