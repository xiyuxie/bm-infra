#!/bin/bash

# Usage: ./check_conda_env.sh env_name
if [ ! -f "$1" ]; then
  echo "Error: The env file '$1' does not exist."
  exit 1  # Exit the script with a non-zero status to indicate an error
fi

ENV_FILE=$1
PYTHON_VERSION="3.12"
VLLM_FOLDER="../vllm"
VLLM_REPO="https://github.com/vllm-project/vllm"

# For testing on local vm, use `set -a` to export all variables
source /etc/environment

set -a
source $ENV_FILE
set +a

ENV_NAME="vllm-bm-$CODE_HASH"

# Clone or reuse VLLM folder
if [ ! -d "$VLLM_FOLDER" ] || [ -z "$(ls -A "$VLLM_FOLDER")" ]; then
  echo "Cloning VLLM repo into $VLLM_FOLDER..."
  git clone "$VLLM_REPO" "$VLLM_FOLDER"
fi

pushd "$VLLM_FOLDER"
git fetch origin
git reset --hard "$CODE_HASH"
popd

# Check if conda env exists
if ! conda info --envs | awk '{print $1}' | grep -Fxq "$ENV_NAME"; then
  echo "Creating conda environment '$ENV_NAME'..."
  conda create -y -n "$ENV_NAME" python="$PYTHON_VERSION"

  # Activate and install dependencies
  echo "Activating and installing vllm + dependencies..."
  eval "$(conda shell.bash hook)"
  conda activate "$ENV_NAME"
  pushd "$VLLM_FOLDER"
  VLLM_USE_PRECOMPILED=1 pip install --editable .
  pip install pandas datasets
  popd
else
  echo "Conda environment '$ENV_NAME' exists. Activating..."
  eval "$(conda shell.bash hook)"
  conda activate "$ENV_NAME"
fi

clean_up() { 
   pkill -f vllm
   ./scripts/agent/clean_old_vllm_envs.sh
}

trap remove_docker_container EXIT

# Actual run scripts
TMP_WORKSPACE=/tmp/workspace

rm -rf $TMP_WORKSPACE
mkdir -p $TMP_WORKSPACE

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

# skip the checking now
# if ! mountpoint -q "$DOWNLOAD_DIR"; then
#     echo "Error: $DOWNLOAD_DIR exists but is not a mounted directory."
#     exit 1
# fi

echo "Run model $MODEL"
echo

echo "copy script run_bm.sh to container..."
cp scripts/agent/run_bm.sh "$VLLM_FOLDER/run_bm.sh"

echo "grant chmod +x"
echo
chmod +x $VLLM_FOLDER/run_bm.sh

pushd $VLLM_FOLDER
echo "run script..."
echo
WORKSPACE=$TMP_WORKSPACE \
 HF_TOKEN="$HF_TOKEN" \
 TARGET_COMMIT=$CODE_HASH \
 MODEL=$MODEL \
 ./run_bm.sh
popd

echo "copy result back..."
VLLM_LOG="$LOG_ROOT/$TEST_NAME"_vllm_log.txt
BM_LOG="$LOG_ROOT/$TEST_NAME"_bm_log.txt
cp "$TMP_WORKSPACE/vllm_log.txt" "$VLLM_LOG" 
cp "$TMP_WORKSPACE/bm_log.txt" "$BM_LOG"

throughput=$(grep "Request throughput (req/s):" "$BM_LOG" | sed 's/[^0-9.]//g')
echo "throughput for $TEST_NAME at $CODE_HASH: $throughput"


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