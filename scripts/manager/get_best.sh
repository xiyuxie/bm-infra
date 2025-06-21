#!/bin/bash

# === Usage ===
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 JOB_REFERENCE"
  exit 1
fi

JOB_REFERENCE="$1"
OUTFILE="/tmp/best_${JOB_REFERENCE}.csv"

echo "Querying AutoTuneBestResult for JobReference = '$JOB_REFERENCE'..."

# Query Spanner and capture full JSON response
QUERY_JSON=$(gcloud spanner databases execute-sql "$GCP_DATABASE_ID" \
  --instance="$GCP_INSTANCE_ID" \
  --project="$GCP_PROJECT_ID" \
  --format=json \
  --sql="
    SELECT Device, Model, Throughput, MaxNumSeqs, MaxNumBatchedTokens,
           TensorParallelSize, MaxModelLen, Dataset, InputLen, OutputLen
    FROM AutoTuneBestResult
    WHERE JobReference = '$JOB_REFERENCE'
    ORDER BY Device, Model;")

# === Print results to screen (with Throughput) ===
echo "$QUERY_JSON" | jq -r '
  ["Device", "Model", "Throughput", "MaxNumSeqs", "MaxNumBatchedTokens",
   "TensorParallelSize", "MaxModelLen", "Dataset", "InputLen", "OutputLen"],
  (.rows[] | [
    .[0], .[1], .[2], .[3], .[4], .[5], .[6], .[7], .[8], .[9]
  ]) | @tsv' | column -t

# === Write CSV file (without Throughput) ===
echo "$QUERY_JSON" | jq -r '
  ["Device", "Model", "MaxNumSeqs", "MaxNumBatchedTokens",
   "TensorParallelSize", "MaxModelLen", "Dataset", "InputLen", "OutputLen"],
  (.rows[] | [
    .[0], .[1], .[3], .[4], .[5], .[6], .[7], .[8], .[9]
  ]) | @tsv' | tr '\t' ',' > "$OUTFILE"

echo "Test cases stored in $OUTFILE"
