#!/bin/bash

# === Usage check ===
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <RECORD_ID>"
  exit 1
fi

RECORD_ID="$1"

set -a
source /etc/environment
set +a

#
# do the work
# 
echo "./scripts/agent/run_job.sh $RECORD_ID"
./scripts/agent/run_job.sh "$RECORD_ID"

#
# Report result
#
echo "Reporting result..."
./scripts/agent/report_result.sh "$RECORD_ID"
