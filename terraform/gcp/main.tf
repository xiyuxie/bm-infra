module "bm_v6e_1" {
  source = "./modules/v6e_1"
  providers = {
    google-beta = google-beta
  }
  startup_script_path="${path.module}/scripts/startup.sh.tpl"
  tpu_zone = var.zone  
}
