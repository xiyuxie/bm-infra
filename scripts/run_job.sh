#!/bin/bash

#
# Get job to run
#
echo "Retrieving job to run..."
record_id="aa6d5d32-676d-4c"

#
# Create running config
#
echo "Creating running config..."
./scripts/create_config.sh "$record_id"
if [ $? -ne 0 ]; then
  echo "Error creating running config."
  exit 1
fi

#
# Run job in docker
#
echo "Running job in docker..."
./scripts/docker_run_bm.sh "artifacts/$record_id.env"
if [ $? -ne 0 ]; then
  echo "Error running job in docker."
  exit 1
fi

#
# Report result
#
echo "Reporting result..."
./scripts/report_result.sh "$record_id"