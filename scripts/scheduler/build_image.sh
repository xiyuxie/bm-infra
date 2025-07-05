#!/bin/bash
set -euo pipefail

CODE_HASH=$1

pushd artifacts/vllm

image_tag="$GCP_REGION-docker.pkg.dev/$GCP_PROJECT_ID/vllm-tpu-bm/vllm-tpu:$CODE_HASH"

echo "Image tag: $image_tag"

# 1. Check if image exists remotely
# 1. Check if image exists remotely
if ! TAGS=$(gcloud artifacts docker tags list "$GCP_REGION-docker.pkg.dev/$GCP_PROJECT_ID/vllm-tpu-bm/vllm-tpu" \
    --project="$GCP_PROJECT_ID" \
    --format="value(tag)"); then
  echo "Failed to list tags from Artifact Registry. Exiting." >&2
  popd
  exit 1
fi

if echo "$TAGS" | grep -Fxq "$CODE_HASH"; then
  echo "Remote image $image_tag already exists. Skipping build and push."
  popd
  exit 0
fi

# 2. Check if image exists locally
if docker image inspect "$image_tag" &>/dev/null; then
    echo "Local image exists. Skipping build. Pushing..."
    docker push "$image_tag"
    popd
    exit 0
fi

# 3. Build and push if image doesn't exist at all
echo "Building and pushing new image: $image_tag"
VLLM_TARGET_DEVICE=tpu DOCKER_BUILDKIT=1 docker build \
 --build-arg max_jobs=16 \
 --build-arg USE_SCCACHE=1 \
 --build-arg GIT_REPO_CHECK=0 \
 --tag "$image_tag" \
 --progress plain \
 -f docker/Dockerfile.tpu .

docker push "$image_tag"

popd
