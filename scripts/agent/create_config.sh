#!/bin/bash

# === Usage check ===
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <RECORD_ID>"
  exit 1
fi

# === Config ===

RECORD_ID="$1"
mkdir -p ./artifacts

ENV_FILE="artifacts/${RECORD_ID}.env"

# The script below generates the result in this format:
# MODEL=meta-llama/Llama-3.1-8B-Instruct
# MAX_NUM_SEQS=128
# MAX_NUM_BATCHED_TOKENS=4096
# TENSOR_PARALLEL_SIZE=1
# MAX_MODEL_LEN=2048
# INPUT_LEN=1800
# OUTPUT_LEN=128
gcloud spanner databases execute-sql "$GCP_DATABASE_ID" \
  --instance="$GCP_INSTANCE_ID" \
  --project="$GCP_PROJECT_ID" \
  --sql="SELECT RecordId, Model, CodeHash, MaxNumSeqs, MaxNumBatchedTokens, TensorParallelSize, MaxModelLen, Dataset, InputLen, OutputLen, ExpectedETEL FROM RunRecord WHERE RecordId = '$RECORD_ID';" | \
  gawk 'NR==1 {
    for (i=1; i<=NF; i++) {
      # Insert underscore before uppercase letters preceded by a lowercase letter
      # Then convert to uppercase
      header[i] = toupper(gensub(/([a-z0-9])([A-Z])/, "\\1_\\2", "g", $i))
    }
  }
  NR==2 {
    for (i=1; i<=NF; i++) {
      print header[i] "=" $i
    }
  }'> $ENV_FILE

# Insert static field
echo "TEST_NAME=static" >> $ENV_FILE
echo "CONTAINER_NAME=vllm-tpu" >> $ENV_FILE
echo "DOWNLOAD_DIR=/mnt/disks/persist" >> $ENV_FILE
