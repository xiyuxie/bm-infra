#!/bin/bash
set -euo pipefail

if ! id -u bm-agent >/dev/null 2>&1; then
    echo "sudo useradd -m -s /bin/bash bm-agent"
    sudo useradd -m -s /bin/bash bm-agent
fi

echo "sudo usermod -aG docker bm-agent"
sudo usermod -aG docker bm-agent

echo "sudo apt-get update && sudo apt-get install -y jq gawk"
sudo apt-get update && sudo apt-get install -y jq gawk

# Get current Git branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Run as bm-agent
sudo -u bm-agent -i bash <<EOF
echo "Authenticating Docker with gcloud..."
gcloud auth configure-docker $GCP_REGION-docker.pkg.dev --quiet

echo "Cleaning up old bm-infra..."
rm -rf bm-infra

echo "Cloning branch '$CURRENT_BRANCH' from bm-infra..."
git clone --branch "$CURRENT_BRANCH" https://github.com/QiliangCui/bm-infra.git

EOF

if [[ "${LOCAL_RUN_BM:-}" == "1" ]]; then  
  echo "=================================================================="
  echo "LOCAL_RUN_BM is $LOCAL_RUN_BM: install Miniconda for bm-agent user"
  echo "=================================================================="
  echo "Installing Miniconda for bm-agent user..."

  sudo -u bm-agent -i bash <<'EOF'
  set -euo pipefail

  # Miniconda version and install directory
  MINICONDA_VERSION=latest  # adjust if needed
  MINICONDA_DIR="/mnt/disks/persist/bm-agent/miniconda3"
  MINICONDA_SCRIPT="Miniconda3-$MINICONDA_VERSION-Linux-x86_64.sh"
  MINICONDA_URL="https://repo.anaconda.com/miniconda/$MINICONDA_SCRIPT"

  # Download Miniconda installer if not exists
  if [ ! -f "$HOME/$MINICONDA_SCRIPT" ]; then
    echo "Downloading Miniconda installer..."
    curl -fsSL "$MINICONDA_URL" -o "$HOME/$MINICONDA_SCRIPT"
  fi

  # Install Miniconda silently if not installed
  if [ ! -d "$MINICONDA_DIR" ]; then
    echo "Installing Miniconda to $MINICONDA_DIR..."
    bash "$HOME/$MINICONDA_SCRIPT" -b -p "$MINICONDA_DIR"
  fi

  # Initialize conda for bash shell
  eval "$($MINICONDA_DIR/bin/conda shell.bash hook)" || true

  # Add conda init to .bashrc if not already there
  if ! grep -q "conda initialize" "$HOME/.bashrc"; then
    echo "Adding conda initialize to .bashrc..."
    "$MINICONDA_DIR/bin/conda" init bash
  fi

  # Accept Terms of Service for required channels
  "$MINICONDA_DIR/bin/conda" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
  "$MINICONDA_DIR/bin/conda" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

  echo "Miniconda installation complete."

EOF

elif [[ "${LOCAL_RUN_BM:-}" == "2" ]]; then
  echo "=================================================================="
  echo "LOCAL_RUN_BM is $LOCAL_RUN_BM: install uv for bm-agent user"
  echo "=================================================================="

  echo "install python3.12-dev"
  sudo apt install -y python3.12-dev

  echo "append extra env to /etc/environment"
  if ! grep -q '^GLOO_SOCKET_IFNAME=lo$' /etc/environment; then
    echo "Appending GLOO_SOCKET_IFNAME=lo to /etc/environment..."
    echo 'GLOO_SOCKET_IFNAME=lo' | sudo tee -a /etc/environment > /dev/null
  else
    echo "GLOO_SOCKET_IFNAME=lo already set in /etc/environment."
  fi

  echo "install on behalf of bm-agent user"

  sudo -u bm-agent -i bash <<'EOF'
  echo "install uv"  
  echo "curl -LsSf https://astral.sh/uv/install.sh | sh"
  curl -LsSf https://astral.sh/uv/install.sh | sh
  echo "uv venv --python 3.12 --seed"
  uv venv --python 3.12 --seed
EOF




  
  

  


else
  echo "Skip conda installation..."  
fi

# echo "sudo cp /home/bm-agent/bm-infra/service/bm-agent/bm-agent.service /etc/systemd/system/bm-agent.service"
# sudo cp /home/bm-agent/bm-infra/service/bm-agent/bm-agent.service /etc/systemd/system/bm-agent.service

# echo "sudo systemctl daemon-reload"
# sudo systemctl daemon-reload

# echo "sudo systemctl stop bm-agent.service"
# sudo systemctl stop bm-agent.service

# echo "sudo systemctl enable bm-agent.service"
# sudo systemctl enable bm-agent.service

# echo "sudo systemctl start bm-agent.service"
# sudo systemctl start bm-agent.service
