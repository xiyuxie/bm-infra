module "bm_v6e_1" {
  source = "./modules/v6e_1"
  providers = {
    google-beta = google-beta
  }
  tpu_count            = 1
  tpu_zone             = var.zone
  region               = var.region
  project_id           = var.project_id
  spanner_instance     = var.spanner_instance
  spanner_db           = var.spanner_db
  gcs_bucket           = var.gcs_bucket
  hf_token             = var.hf_token  
  startup_script_path = "${path.module}/scripts/startup.sh.tpl"
}
