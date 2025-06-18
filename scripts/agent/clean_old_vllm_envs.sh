#!/bin/bash

# Threshold in seconds (1 day)
THRESHOLD_SECONDS=$((60 * 60 * 24))
NOW=$(date +%s)

# Get conda base envs directory
ENV_BASE="$(conda info --base)/envs"

echo "Scanning for old 'vllm-bm-*' environments older than 1 day..."

for env_path in "$ENV_BASE"/vllm-bm-*; do
  [ -d "$env_path" ] || continue
  env_name=$(basename "$env_path")

  # Get last modification time
  mtime=$(stat -c "%Y" "$env_path")
  age=$((NOW - mtime))

  if [ "$age" -gt "$THRESHOLD_SECONDS" ]; then
    echo "Deleting old env: $env_name (age: $((age/3600)) hours)"
    conda remove -n "$env_name" --all -y
  else
    echo "Keeping env: $env_name (recently modified)"
  fi
done
