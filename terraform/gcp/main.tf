module "v6e-1-queue" {
  source = "./modules/queue"
  providers = {
    google = google
  }

  purpose              = var.purpose
  accelerator_type     = "v6e-1"
}

module "v6e-4-queue" {
  source = "./modules/queue"
  providers = {
    google = google
  }

  purpose              = var.purpose
  accelerator_type     = "v6e-4"
}

module "v6e-8-queue" {
  source = "./modules/queue"
  providers = {
    google = google
  }

  purpose              = var.purpose
  accelerator_type     = "v6e-8"
}

module "h100-8-queue" {
  source = "./modules/queue"
  providers = {
    google = google
  }

  purpose              = var.purpose
  accelerator_type     = "h100-8"
}

module "v6e-1" {
  source = "./modules/v6e"
  providers = {
    google-beta = google-beta
  }
  purpose              = var.purpose
  accelerator_type     = "v6e-1"
  tpu_count            = 2
  tpu_zone             = var.zone
  region               = var.region
  project_id           = var.project_id
  spanner_instance     = var.spanner_instance
  spanner_db           = var.spanner_db
  gcs_bucket           = var.gcs_bucket
  startup_script_path = "${path.module}/scripts/startup.sh.tpl"
}

module "v6e-4" {
  source = "./modules/v6e"
  providers = {
    google-beta = google-beta
  }
  purpose              = var.purpose
  accelerator_type     = "v6e-4"
  tpu_count            = 1
  tpu_zone             = var.zone
  region               = var.region
  project_id           = var.project_id
  spanner_instance     = var.spanner_instance
  spanner_db           = var.spanner_db
  gcs_bucket           = var.gcs_bucket
  startup_script_path = "${path.module}/scripts/startup.sh.tpl"
}

module "v6e-8" {
  source = "./modules/v6e"
  providers = {
    google-beta = google-beta
  }
  purpose              = var.purpose
  accelerator_type     = "v6e-8"
  tpu_count            = 4
  tpu_zone             = var.zone
  region               = var.region
  project_id           = var.project_id
  spanner_instance     = var.spanner_instance
  spanner_db           = var.spanner_db
  gcs_bucket           = var.gcs_bucket
  mnt_disk_gb          = 2048
  startup_script_path = "${path.module}/scripts/startup.sh.tpl"
}
