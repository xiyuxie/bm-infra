#!/bin/bash

if [ ! -f "$1" ]; then
  echo "Error: The env file '$1' does not exist."
  exit 1  # Exit the script with a non-zero status to indicate an error
fi

ENV_FILE=$1

# For testing on local vm, use `set -a` to export all variables
source /etc/environment
source $ENV_FILE

remove_docker_container() { 
    docker rm -f tpu-test || true; 
    docker rm -f vllm-tpu || true;
    docker rm -f $CONTAINER_NAME || true;
}

trap remove_docker_container EXIT

# Remove the container that might not be cleaned up in the previous run.
remove_docker_container

image_tag=$GCP_REGION-docker.pkg.dev/$GCP_PROJECT_ID/vllm-tpu-bm/vllm-tpu:$CODE_HASH

IFS='-' read -r VLLM_HASH TPU_COMMON_HASH TORCHAX_HASH _ <<< "$CODE_HASH"

echo "image tag: $image_tag"

docker pull $image_tag

if [ $? -ne 0 ]; then
  echo "Failed to pull the Docker image: $image_tag"
  exit 1
fi

LOG_ROOT=$(mktemp -d)
REMOTE_LOG_ROOT="gs://$GCS_BUCKET/job_logs/$RECORD_ID/"

# If mktemp fails, set -e will cause the script to exit.
echo "Results will be stored in: $LOG_ROOT"

if [ -z "$HF_TOKEN" ]; then
  echo "Error: HF_TOKEN is not set or is empty."  
  exit 1
fi

# Make sure mounted disk or dir exists
if [ ! -d "$DOWNLOAD_DIR" ]; then
    echo "Error: Folder $DOWNLOAD_DIR does not exist. This is useually a mounted drive. If no mounted drive, just create a folder."
    exit 1
fi

if ! mountpoint -q "$DOWNLOAD_DIR"; then
    echo "Error: $DOWNLOAD_DIR exists but is not a mounted directory."
    exit 1
fi

echo "Run model $MODEL"
echo

echo "starting docker...$CONTAINER_NAME"
echo    
docker run \
 -v $DOWNLOAD_DIR:$DOWNLOAD_DIR \
 --env-file $ENV_FILE \
 -e HF_TOKEN="$HF_TOKEN" \
 -e TARGET_COMMIT=$VLLM_HASH \
 -e MODEL=$MODEL \
 -e WORKSPACE=/workspace \
 --name $CONTAINER_NAME \
 -d \
 --privileged \
 --network host \
 -v /dev/shm:/dev/shm \
 $image_tag tail -f /dev/null

echo "copy script run_bm.sh to container..."
docker cp scripts/agent/run_bm.sh "$CONTAINER_NAME:/workspace/vllm/run_bm.sh"

echo "grant chmod +x"
echo
docker exec "$CONTAINER_NAME" chmod +x "/workspace/vllm/run_bm.sh"

echo "run script..."
echo
docker exec "$CONTAINER_NAME" /bin/bash -c "./run_bm.sh"

echo "copy result back..."
VLLM_LOG="$LOG_ROOT/$TEST_NAME"_vllm_log.txt
BM_LOG="$LOG_ROOT/$TEST_NAME"_bm_log.txt
docker cp "$CONTAINER_NAME:/workspace/vllm_log.txt" "$VLLM_LOG" 
docker cp "$CONTAINER_NAME:/workspace/bm_log.txt" "$BM_LOG"

throughput=$(grep "Request throughput (req/s):" "$BM_LOG" | sed 's/[^0-9.]//g')
echo "throughput for $TEST_NAME at $VLLM_HASH: $throughput"


echo "gsutil cp $LOG_ROOT/* $REMOTE_LOG_ROOT"
gsutil cp $LOG_ROOT/* $REMOTE_LOG_ROOT

#
# compare the throughput with EXPECTED_THROUGHPUT 
# and assert meeting the expectation
# Even if failed to get throughput, we still consider the docker run is good.
# The following script will report failure if the result out is not created.
# 
if [[ -z "$throughput" || ! "$throughput" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "Failed to get the throughput"
  exit 0
fi

if (( $(echo "$throughput < $EXPECTED_THROUGHPUT" | bc -l) )); then
  echo "Error: throughput($throughput) is less than expected($EXPECTED_THROUGHPUT)"
  exit 0
fi

# write output
echo "Throughput=$throughput" > "artifacts/$RECORD_ID.result"