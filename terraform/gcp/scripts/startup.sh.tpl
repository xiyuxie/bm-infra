#!/bin/bash     

# Set env vars system-wide
echo "GCP_PROJECT_ID=${project_id}" >> /etc/environment
echo "GCP_INSTANCE_ID=${spanner_instance}" >> /etc/environment
echo "GCP_DATABASE_ID=${spanner_db}" >> /etc/environment
echo "GCP_REGION=${region}" >> /etc/environment
echo "GCP_INSTANCE_NAME=${instance_name}" >> /etc/environment
echo "GCS_BUCKET=${gcs_bucket}" >> /etc/environment      
echo "GCP_QUEUE=vllm-bm-queue-${accelerator_type}" >> /etc/environment
echo "HF_TOKEN=${hf_token}" >> /etc/environment

apt-get update
apt-get install -y curl build-essential jq

curl -o- https://get.docker.com/ | bash -

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
/root/.cargo/bin/cargo install minijinja-cli
cp /root/.cargo/bin/minijinja-cli /usr/bin/minijinja-cli
chmod 777 /usr/bin/minijinja-cli

sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb
sudo mkdir -p /mnt/disks/persist
sudo mount -o discard,defaults /dev/sdb /mnt/disks/persist

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
