#!/bin/bash

rm -rf artifacts/
mkdir -p artifacts/

# enlist code
git clone https://github.com/vllm-project/vllm.git artifacts/vllm

# into
pushd artifacts/vllm

if [[ -n "$TARGET_COMMIT" ]]; then
    git reset --hard "$TARGET_COMMIT"
fi

commit_hash=$(git rev-parse HEAD)

yes | docker system prune -a

image_tag=$GCP_REGION-docker.pkg.dev/$GCP_PROJECT_ID/vllm-tpu-bm/vllm-tpu:$commit_hash

echo "image tag: $image_tag"

VLLM_TARGET_DEVICE=tpu DOCKER_BUILDKIT=1 docker build \
 --build-arg max_jobs=16 \
 --build-arg USE_SCCACHE=1 \
 --build-arg GIT_REPO_CHECK=0 \
 --tag $image_tag \
 --progress plain \
 -f docker/Dockerfile.tpu .

docker push $image_tag

# get back
popd

