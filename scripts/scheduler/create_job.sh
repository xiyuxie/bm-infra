#!/bin/bash
set -euo pipefail

# Check at least 1 argument is provided
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <INPUT_CSV> [CODE_HASH] [JOB_REFERENCE] [RUN_TYPE]"
    exit 1
fi

INPUT_CSV="$1"
CODE_HASH="${2:-}"  # optional
JOB_REFERENCE="${3:-}"
RUN_TYPE="${4:-"MANUAL"}"

echo "Recreating artifacts directory"
rm -rf artifacts/
mkdir -p artifacts/

# Clone vllm repo
git clone https://github.com/vllm-project/vllm.git artifacts/vllm

pushd artifacts/vllm

if [[ -n "$CODE_HASH" ]]; then
    echo "git reset --hard $CODE_HASH"
    git reset --hard "$CODE_HASH"
fi

# Always get the actual commit hash after clone/reset
CODE_HASH=$(git rev-parse HEAD)
popd

echo "./scripts/scheduler/build_image.sh $CODE_HASH"
./scripts/scheduler/build_image.sh "$CODE_HASH"

echo "./scripts/scheduler/schedule_run.sh $INPUT_CSV $CODE_HASH"
./scripts/scheduler/schedule_run.sh "$INPUT_CSV" "$CODE_HASH" "$JOB_REFERENCE" "$RUN_TYPE"
