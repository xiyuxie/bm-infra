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
    EOF
  }
}
