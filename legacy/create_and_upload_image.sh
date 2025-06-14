#!/bin/bash
if [ ! -f "$1" ]; then
  echo "Error: The env file '$1' does not exist."
  echo "Error: The env file '$1' does not exist." >> $RESULT
  exit 1  # Exit the script with a non-zero status to indicate an error
fi

ENV_FILE=$1

set -a
source $ENV_FILE
set +a

if [ -d "$HOME/miniconda3" ]; then
  CONDA="$HOME/miniconda3"
elif [ -d "/opt/conda" ]; then
  CONDA="/opt/conda"
else
  echo "Error: Conda installation not found." >&2
  exit 1
fi

echo "source $CONDA/bin/activate vllm"
echo
source $CONDA/bin/activate vllm

echo "pip install google-cloud-spanner"
echo
pip install google-cloud-spanner

echo "pip install pandas"
echo
pip install pandas

echo "pip install pytz"
echo
pip install pytz

echo "pip install matplotlib"
echo
pip install matplotlib

# python draw.py nightly $HOME/daily.png llama-8b qwen-2b
# echo gsutil cp daily.png* gs://$GCS_BUCKET
# gsutil cp daily.png* gs://$GCS_BUCKET
echo "create source and image"
echo

python draw.py hourly $HOME/hourly.png llama-8b qwen-2b llama-70b llama-70b-vm llama-8b-vm qwen-2b-vm llama3-8b-w8a8 llama3-8b-w8a8vm llama-8b-a100-vm llama3-70b-w8a8 llama370bw8a8vm gemma3-27b gemma3-27b-vm
echo gsutil cp hourly.png* gs://$GCS_BUCKET
gsutil cp hourly.png* gs://$GCS_BUCKET
echo gsutil cp hourly.png* gs://$GCS_BUCKET2
gsutil cp hourly.png* gs://$GCS_BUCKET2
