#!/bin/bash
set -euo pipefail

#
# Check input argument
#
if [ $# -ne 1 ]; then
  echo "Usage: $0 <RECORD_ID>"
  exit 1
fi

RECORD_ID="$1"
echo "Record ID: $RECORD_ID"

echo "deleting artifacts".
rm -rf artifacts

#
# Create running config
#
echo "Creating running config..."
./scripts/agent/create_config.sh "$RECORD_ID"
if [ $? -ne 0 ]; then
  echo "Error creating running config."
  exit 1
fi

#
# Run job in docker
#
echo "Running job in docker..."
./scripts/agent/docker_run_bm.sh "artifacts/${RECORD_ID}.env"
if [ $? -ne 0 ]; then
  echo "Error running job in docker."
  exit 1
fi

#
# Report result
#
echo "Reporting result..."
./scripts/agent/report_result.sh "$RECORD_ID"