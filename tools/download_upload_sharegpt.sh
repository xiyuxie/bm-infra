#!/bin/bash

set -euo pipefail

mkdir -p artifacts

rm artifacts/ShareGPT_V3_unfiltered_cleaned_split.json

wget -P artifacts https://huggingface.co/datasets/anon8231489123/ShareGPT_Vicuna_unfiltered/resolve/main/ShareGPT_V3_unfiltered_cleaned_split.json

gsutil cp artifacts/ShareGPT_V3_unfiltered_cleaned_split.json gs://$GCS_BUCKET/dataset/sharegpt/ShareGPT_V3_unfiltered_cleaned_split.json
