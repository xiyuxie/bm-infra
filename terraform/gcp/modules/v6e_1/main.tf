resource "google_compute_disk" "disk_v6_1_bm" {
  provider = google-beta
  count    = var.tpu_count

  name  = "tpu-disk-v6e-1-${var.tpu_zone}-${count.index}"
  size  = 512
  type  = "hyperdisk-balanced"
  zone  = var.tpu_zone
}

resource "google_tpu_v2_vm" "tpu_v6_1_bm" {
  provider = google-beta
  count    = var.tpu_count

  name     = "vllm-tpu-v6-1-bm-${count.index}"
  zone     = var.tpu_zone

  runtime_version  = "v2-alpha-tpuv6e"
  accelerator_type = "v6e-1"

  network_config {
    network              = "default"
    enable_external_ips  = true
  }

  data_disks {
    source_disk = google_compute_disk.disk_v6_1_bm[count.index].id
    mode        = "READ_WRITE"
  }

  metadata = {
    "startup-script" = <<-EOF
      #!/bin/bash
      GCP_REGION="${var.region}"

      # Set env vars system-wide #### TODO, not done yet
      echo "GCP_PROJECT_ID=${var.project_id}" >> /etc/environment
      echo "GCP_REGION=${var.region}" >> /etc/environment
      echo "GCS_BUCKET=${var.gcs_bucket}" >> /etc/environment

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
      gcloud auth configure-docker ${GCP_REGION}-docker.pkg.dev --quiet
      rm -rf bm-infra
      git clone https://github.com/QiliangCui/bm-infra.git
      EOBM
      cp /home/bm-agent/bm-infra/service/bm-agent/bm-agent.service /etc/systemd/system/bm-agent.service
      systemctl stop bm-agent.service
      systemctl daemon-reload
      systemctl enable bm-agent.service
      systemctl start bm-agent.service
    EOF
  }
}
