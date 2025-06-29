#!/bin/bash

set -euo pipefail

# Usage message
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <INPUT_CSV> [CODE_HASH] [JOB_REFERENCE]"
  exit 1
fi

# Input arguments
INPUT_CSV="$1"
CODE_HASH="${2:-}"
JOB_REFERENCE="${3:-}"
RUN_TYPE="${4:-}"
REPO="${5:-}"

# Step 1: Generate sweep parameter CSV
# Get the base file name
BASENAME="$(basename "$INPUT_CSV")"

# Determine sweep CSV path in /tmp
if [[ "$BASENAME" == *.csv ]]; then
  SWEEP_CSV="/tmp/${BASENAME%.csv}.sweep_parameter.csv"
else
  SWEEP_CSV="/tmp/${BASENAME}.sweep_parameter.csv"
fi

echo "Generating sweep parameter file from $INPUT_CSV to $SWEEP_CSV"

python3 tools/sweep_parameter.py "$INPUT_CSV" "$SWEEP_CSV"

# Step 2: Create job
echo "Creating job using $SWEEP_CSV..."
echo ./scripts/scheduler/create_job.sh "$SWEEP_CSV" "$CODE_HASH" "$JOB_REFERENCE"
./scripts/scheduler/create_job.sh "$SWEEP_CSV" "$CODE_HASH" "$JOB_REFERENCE"
