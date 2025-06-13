resource "google_compute_disk" "disk_v6_1_bm" {
  provider = google-beta
  count    = var.tpu_count

  name = "tpu-disk-v6e-1-${var.tpu_zone}-${count.index}"
  size = 512
  type = "hyperdisk-balanced"
  zone = var.tpu_zone
}

resource "google_tpu_v2_vm" "tpu_v6_1_bm" {
  provider = google-beta
  count    = var.tpu_count

  name             = "vllm-tpu-v6-1-bm-${count.index}"
  zone             = var.tpu_zone
  runtime_version  = "v2-alpha-tpuv6e"
  accelerator_type = "v6e-1"

  network_config {
    network           = "default"
    enable_external_ips = true
  }

  data_disks {
    source_disk = google_compute_disk.disk_v6_1_bm[count.index].id
    mode        = "READ_WRITE"
  }

  metadata = {
    "startup-script" = templatefile(var.startup_script_path, {
      project_id       = var.project_id
      spanner_instance = var.spanner_instance
      spanner_db       = var.spanner_db
      region           = var.region
      instance_name    = "vllm-tpu-v6-1-bm-${count.index}"
      accelerator_type = "v6e-1"
      gcs_bucket       = var.gcs_bucket
      hf_token         = var.hf_token
    })
  }

}