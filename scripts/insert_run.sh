#!/bin/bash

# === Usage ===
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 input.csv CODEHASH"
  exit 1
fi

CSV_FILE="$1"
CODEHASH="$2"

if [ ! -f "$CSV_FILE" ]; then
  echo "CSV file not found: $CSV_FILE"
  exit 1
fi

# === Config ===
# Make sure these environment variables are set or export here
# export GCP_PROJECT_ID="your-project"
# export GCP_INSTANCE_ID="your-instance"
# export GCP_DATABASE_ID="your-database"

# === Read CSV and skip header ===
tail -n +2 "$CSV_FILE" | while IFS=',' read -r DEVICE MODEL RUNTYPE MAX_NUM_SEQS MAX_NUM_BATCHED_TOKENS TENSOR_PARALLEL_SIZE MAX_MODEL_LEN DATASET INPUT_LEN OUTPUT_LEN
do
  RECORD_ID=$(uuidgen | tr 'A-Z' 'a-z' | cut -c1-16)

  gcloud spanner databases execute-sql "$GCP_DATABASE_ID" \
    --instance="$GCP_INSTANCE_ID" \
    --project="$GCP_PROJECT_ID" \
    --sql="INSERT INTO RunRecord (
      RecordId, Status, CreatedTime, Device, Model, RunType, CodeHash,
      MaxNumSeqs, MaxNumBatchedTokens, TensorParallelSize, MaxModelLen,
      Dataset, InputLen, OutputLen, LastUpdate
    ) VALUES (
      '$RECORD_ID', 'CREATED', PENDING_COMMIT_TIMESTAMP(), '$DEVICE', '$MODEL', '$RUNTYPE', '$CODEHASH',
      $MAX_NUM_SEQS, $MAX_NUM_BATCHED_TOKENS, $TENSOR_PARALLEL_SIZE, $MAX_MODEL_LEN,
      '$DATASET', $INPUT_LEN, $OUTPUT_LEN, PENDING_COMMIT_TIMESTAMP()
    );"

  echo "Inserted RecordId: $RECORD_ID"
done