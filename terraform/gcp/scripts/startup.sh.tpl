#!/bin/bash     

# Set env vars system-wide
grep -q "^GCP_PROJECT_ID=" /etc/environment || echo "GCP_PROJECT_ID=${project_id}" | sudo tee -a /etc/environment
grep -q "^GCP_INSTANCE_ID=" /etc/environment || echo "GCP_INSTANCE_ID=${spanner_instance}" | sudo tee -a /etc/environment
grep -q "^GCP_DATABASE_ID=" /etc/environment || echo "GCP_DATABASE_ID=${spanner_db}" | sudo tee -a /etc/environment
grep -q "^GCP_REGION=" /etc/environment || echo "GCP_REGION=${region}" | sudo tee -a /etc/environment
grep -q "^GCP_INSTANCE_NAME=" /etc/environment || echo "GCP_INSTANCE_NAME=${instance_name}" | sudo tee -a /etc/environment
grep -q "^GCS_BUCKET=" /etc/environment || echo "GCS_BUCKET=${gcs_bucket}" | sudo tee -a /etc/environment
grep -q "^GCP_QUEUE=" /etc/environment || echo "GCP_QUEUE=vllm-${purpose}-queue-${accelerator_type}" | sudo tee -a /etc/environment
grep -q "^HF_TOKEN=" /etc/environment || echo "HF_TOKEN=${hf_token}" | sudo tee -a /etc/environment


apt-get update
apt-get install -y curl build-essential jq

curl -o- https://get.docker.com/ | bash -

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
/root/.cargo/bin/cargo install minijinja-cli
cp /root/.cargo/bin/minijinja-cli /usr/bin/minijinja-cli
chmod 777 /usr/bin/minijinja-cli

# Mount persistent disk
if ! blkid /dev/nvme0n2; then
  echo "Formatting /dev/nvme0n2 as ext4..."
  mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/nvme0n2
fi

echo "mkdir -p /mnt/disks/persist" 
mkdir -p /mnt/disks/persist

echo "chmod 777 -R /mnt/disks/persist"
chmod 777 -R /mnt/disks/persist

echo "mount -o discard,defaults /dev/nvme0n2 /mnt/disks/persist"
mount -o discard,defaults /dev/nvme0n2 /mnt/disks/persist
chmod 777 -R /mnt/disks/persist

jq ". + {\"data-root\": \"/mnt/disks/persist\"}" /etc/docker/daemon.json > /tmp/daemon.json.tmp && mv /tmp/daemon.json.tmp /etc/docker/daemon.json
systemctl stop docker
systemctl daemon-reload
systemctl start docker

useradd -m -s /bin/bash bm-agent
sudo usermod -aG docker bm-agent

# Run the commands below as bm-agent user:
sudo -u bm-agent -i bash << EOBM
gcloud auth configure-docker ${region}-docker.pkg.dev --quiet
rm -rf bm-infra
git clone https://github.com/QiliangCui/bm-infra.git
EOBM
cp /home/bm-agent/bm-infra/service/bm-agent/bm-agent.service /etc/systemd/system/bm-agent.service
systemctl stop bm-agent.service
systemctl daemon-reload
systemctl enable bm-agent.service
systemctl start bm-agent.service
