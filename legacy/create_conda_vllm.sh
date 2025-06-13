# conda create -n vllm python=3.11 -y
# conda activate vllm
git clone https://github.com/vllm-project/vllm.git && cd vllm
pip uninstall torch torch-xla -y

pip install -r requirements/tpu.txt
VLLM_TARGET_DEVICE="tpu" python -m pip install --editable .

sudo apt-get update
sudo apt-get install libopenblas-base libopenmpi-dev libomp-dev
