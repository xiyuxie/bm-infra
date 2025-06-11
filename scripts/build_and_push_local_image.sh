#!/bin/bash
set -e

# Check if we're inside a Git repository
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "Error: Not a git repository."
  exit 1
fi

# Check for uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Error: You have uncommitted changes."
  git status --short
  exit 1
fi

CODE_HASH=$(git rev-parse HEAD)
image_tag="$GCP_REGION-docker.pkg.dev/$GCP_PROJECT_ID/vllm-tpu-bm/vllm-tpu:$CODE_HASH"

echo "Building and pushing new image: $image_tag"
VLLM_TARGET_DEVICE=tpu DOCKER_BUILDKIT=1 docker build \
 --build-arg max_jobs=16 \
 --build-arg USE_SCCACHE=1 \
 --build-arg GIT_REPO_CHECK=0 \
 --tag "$image_tag" \
 --progress plain \
 -f docker/Dockerfile.tpu .

echo docker push "$image_tag"
docker push "$image_tag"

echo "code hash: $CODE_HASH"