module "bm_v6e_1" {
  source = "./modules/v6e_1"
  providers = {
    google-beta = google-beta
  }

  tpu_zone = var.zone  
}
