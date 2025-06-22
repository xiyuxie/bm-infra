#!/bin/bash
set -euo pipefail

if [ ! -f "$1" ]; then
  echo "Error: The env file '$1' does not exist."
  exit 1
fi

ENV_FILE=$1
PYTHON_VERSION="3.12"
VLLM_FOLDER="../vllm"
VLLM_REPO="https://github.com/vllm-project/vllm"
CONDA="/mnt/disks/persist/bm-agent/miniconda3/bin/conda"

# Load environment
source /etc/environment
set -a
source "$ENV_FILE"
set +a

ENV_NAME="vllm-bm-$CODE_HASH"

# Clone or update vllm repo
if [ ! -d "$VLLM_FOLDER" ] || [ -z "$(ls -A "$VLLM_FOLDER")" ]; then
  echo "Cloning VLLM repo..."
  git clone "$VLLM_REPO" "$VLLM_FOLDER"
fi

pushd "$VLLM_FOLDER"
git fetch origin
git reset --hard "$CODE_HASH"
popd

# Check and create conda env
if ! $CONDA env list | grep -Fq "$ENV_NAME"; then
  echo "Creating conda environment '$ENV_NAME'..."
  $CONDA create -y -n "$ENV_NAME" python="$PYTHON_VERSION"
  
  echo "Installing vllm and dependencies..."
  $CONDA run -n "$ENV_NAME" pip install --upgrade pip
  $CONDA run -n "$ENV_NAME" pip install pandas datasets
  $CONDA run -n "$ENV_NAME" bash -c "cd '$VLLM_FOLDER' && VLLM_USE_PRECOMPILED=1 pip install --editable ."
fi

# Safety cleanup on exit
clean_up() { 
   pkill -f vllm || true
   ./scripts/agent/clean_old_vllm_envs.sh || true
}
trap clean_up EXIT

# Prepare working dirs
TMP_WORKSPACE="/tmp/workspace"
LOG_ROOT=$(mktemp -d)
REMOTE_LOG_ROOT="gs://$GCS_BUCKET/job_logs/$RECORD_ID/"

rm -rf "$TMP_WORKSPACE"
mkdir -p "$TMP_WORKSPACE"

echo "Results will be stored in: $LOG_ROOT"

# Sanity checks
if [ -z "${HF_TOKEN:-}" ]; then
  echo "Error: HF_TOKEN is not set."
  exit 1
fi

if [ ! -d "$DOWNLOAD_DIR" ]; then
  echo "Error: Folder $DOWNLOAD_DIR does not exist."
  exit 1
fi

if ! mountpoint -q "$DOWNLOAD_DIR"; then
    echo "Error: $DOWNLOAD_DIR exists but is not a mounted directory."
    exit 1
fi
# Prepare script
echo "Copying and chmod-ing run_bm.sh..."
cp scripts/agent/run_bm.sh "$VLLM_FOLDER/run_bm.sh"
chmod +x "$VLLM_FOLDER/run_bm.sh"

# Run benchmark
echo "Running model benchmark..."
$CONDA run -n "$ENV_NAME" bash -c "
  set -e
  cd '$VLLM_FOLDER'
  WORKSPACE='$TMP_WORKSPACE' \
  HF_TOKEN='$HF_TOKEN' \
  TARGET_COMMIT='$CODE_HASH' \
  MODEL='$MODEL' \
  ./run_bm.sh
"

# Copy results
VLLM_LOG="$LOG_ROOT/${TEST_NAME}_vllm_log.txt"
BM_LOG="$LOG_ROOT/${TEST_NAME}_bm_log.txt"
cp "$TMP_WORKSPACE/vllm_log.txt" "$VLLM_LOG"
cp "$TMP_WORKSPACE/bm_log.txt" "$BM_LOG"

# Parse throughput
throughput=$(grep 'Request throughput (req/s):' "$BM_LOG" | sed 's/[^0-9.]//g')
echo "Throughput: $throughput"

# Upload to GCS
gsutil cp "$LOG_ROOT"/* "$REMOTE_LOG_ROOT"

# Check throughput
if [[ -z "$throughput" || ! "$throughput" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "Failed to parse throughput"
  exit 0
fi

if [[ -n "${EXPECTED_THROUGHPUT:-}" ]]; then
  if (( $(echo "$throughput < $EXPECTED_THROUGHPUT" | bc -l) )); then
    echo "Error: Throughput ($throughput) < Expected ($EXPECTED_THROUGHPUT)"
    exit 0
  fi
else
  echo "No EXPECTED_THROUGHPUT set, skipping threshold check."
fi

# Write result file
echo "Throughput=$throughput" > "artifacts/$RECORD_ID.result"
