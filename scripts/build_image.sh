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

image_tag=southamerica-west1-docker.pkg.dev/cloud-tpu-inference-test/vllm-tpu-bm/vllm-tpu:$commit_hash

DOCKER_BUILDKIT=1 docker build \
 --build-arg max_jobs=16 \
 --build-arg USE_SCCACHE=1 \
 --build-arg GIT_REPO_CHECK=0 \
 --tag image_tag \
 --progress plain \
 -f docker/Dockerfile.tpu .

docker push image_tag

# get back
popd

