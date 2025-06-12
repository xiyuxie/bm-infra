#!/bin/bash
set -euo pipefail

# --- Arguments ---
INPUT_CSV="$1"
HASH_RANGE="$2"
JOB_REFERENCE="${3:-}"
RUN_TYPE="${4:-}"

# --- Parse START and END hashes ---
IFS='-' read -r START_HASH END_HASH <<< "$HASH_RANGE"
END_HASH="${END_HASH:-HEAD}"

if [ -z "$START_HASH" ]; then
  echo "Usage: $0 <INPUT_CSV> <START_HASH[-END_HASH]> [JOB_REFERENCE] [RUN_TYPE]"
  exit 1
fi

echo "INPUT_CSV: $INPUT_CSV"
echo "START_HASH: $START_HASH"
echo "END_HASH: $END_HASH"
echo "JOB_REFERENCE: $JOB_REFERENCE"
echo "RUN_TYPE: $RUN_TYPE"

echo "Recreating artifacts directory"
rm -rf artifacts/
mkdir -p artifacts/

# Clone vllm repo
git clone https://github.com/vllm-project/vllm.git artifacts/vllm

pushd artifacts/vllm

echo "Getting commit hashes between $START_HASH and $END_HASH (inclusive)..."
HASH_LIST=$(git rev-list --reverse "${START_HASH}^..${END_HASH}")

popd

i=0
for HASH in $HASH_LIST; do
  echo "Processing hash #$i: $HASH"
  ./scripts/scheduler/create_job.sh "$INPUT_CSV" "$HASH" "${JOB_REFERENCE}_${i}" "$RUN_TYPE"
  let i=i+1
done
