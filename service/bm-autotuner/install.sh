#!/bin/bash
set -euo pipefail

if ! id -u bm-autotuner >/dev/null 2>&1; then
    echo "sudo useradd -m -s /bin/bash bm-autotuner"
    sudo useradd -m -s /bin/bash bm-autotuner
fi

echo "sudo usermod -aG docker bm-autotuner"
sudo usermod -aG docker bm-autotuner

echo "sudo apt-get update && sudo apt-get install -y jq"
sudo apt-get update && sudo apt-get install -y jq

echo "sudo -u bm-autotuner -i..."
sudo -u bm-autotuner -i bash <<EOF
echo "gcloud auth configure-docker $GCP_REGION-docker.pkg.dev --quiet"
gcloud auth configure-docker $GCP_REGION-docker.pkg.dev --quiet

echo "rm -rf bm-infra"
rm -rf bm-infra

echo "git clone https://github.com/QiliangCui/bm-infra.git"
git clone https://github.com/QiliangCui/bm-infra.git

EOF

echo "sudo cp /home/bm-autotuner/bm-infra/service/bm-autotuner/bm-autotuner.service /etc/systemd/system/bm-autotuner.service"
sudo cp /home/bm-autotuner/bm-infra/service/bm-autotuner/bm-autotuner.service /etc/systemd/system/bm-autotuner.service

echo "sudo systemctl daemon-reload"
sudo systemctl daemon-reload

echo "sudo systemctl stop bm-autotuner.service"
sudo systemctl stop bm-autotuner.service

# add to crontab
# (crontab -l 2>/dev/null | grep -v 'bm-autotuner.service'; echo "0 * * * * sudo /bin/systemctl restart bm-autotuner.service") | crontab -
