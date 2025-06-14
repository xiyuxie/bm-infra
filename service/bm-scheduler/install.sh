#!/bin/bash
set -euo pipefail

if ! id -u bm-agent >/dev/null 2>&1; then
    echo "sudo useradd -m -s /bin/bash bm-agent"
    sudo useradd -m -s /bin/bash bm-agent
fi

echo "sudo usermod -aG docker bm-agent"
sudo usermod -aG docker bm-agent

echo "sudo apt-get update && sudo apt-get install -y jq"
sudo apt-get update && sudo apt-get install -y jq

echo "sudo -u bm-agent -i..."
sudo -u bm-agent -i bash <<EOF
echo "gcloud auth configure-docker $GCP_REGION-docker.pkg.dev --quiet"
gcloud auth configure-docker $GCP_REGION-docker.pkg.dev --quiet

echo "rm -rf bm-infra"
rm -rf bm-infra

echo "git clone https://github.com/QiliangCui/bm-infra.git"
git clone https://github.com/QiliangCui/bm-infra.git

EOF

echo "sudo cp /home/bm-agent/bm-infra/service/bm-agent/bm-agent.service /etc/systemd/system/bm-agent.service"
sudo cp /home/bm-agent/bm-infra/service/bm-agent/bm-agent.service /etc/systemd/system/bm-agent.service

echo "sudo systemctl daemon-reload"
sudo systemctl daemon-reload

echo "sudo systemctl stop bm-agent.service"
sudo systemctl stop bm-agent.service

echo "sudo systemctl enable bm-agent.service"
sudo systemctl enable bm-agent.service

echo "sudo systemctl start bm-agent.service"
sudo systemctl start bm-agent.service
