#!/bin/bash
set -euo pipefail

if ! id -u bm-monitor >/dev/null 2>&1; then
    echo "sudo useradd -m -s /bin/bash bm-monitor"
    sudo useradd -m -s /bin/bash bm-monitor
fi

echo "sudo usermod -aG docker bm-monitor"
sudo usermod -aG docker bm-monitor

echo "sudo apt-get update && sudo apt-get install -y jq"
sudo apt-get update && sudo apt-get install -y jq

echo "sudo -u bm-monitor -i..."
sudo -u bm-monitor -i bash <<EOF
echo "gcloud auth configure-docker $GCP_REGION-docker.pkg.dev --quiet"
gcloud auth configure-docker $GCP_REGION-docker.pkg.dev --quiet

echo "rm -rf bm-infra"
rm -rf bm-infra

echo "git clone https://github.com/QiliangCui/bm-infra.git"
git clone https://github.com/QiliangCui/bm-infra.git

EOF

echo "sudo cp /home/bm-monitor/bm-infra/service/bm-monitor/bm-monitor.service /etc/systemd/system/bm-monitor.service"
sudo cp /home/bm-monitor/bm-infra/service/bm-monitor/bm-monitor.service /etc/systemd/system/bm-monitor.service

echo "sudo systemctl daemon-reload"
sudo systemctl daemon-reload

echo "sudo systemctl stop bm-monitor.service"
sudo systemctl stop bm-monitor.service

# add to crontab
(crontab -l 2>/dev/null | grep -v 'bm-monitor.service'; echo "3-59/10 * * * * sudo /bin/systemctl restart bm-monitor.service") | crontab -

