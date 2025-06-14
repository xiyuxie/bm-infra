variable "project_id" {
  default = "cloud-tpu-inference-test"
}

variable "region" {
    default = "southamerica-west1"
}

variable "zone" {
    default = "southamerica-west1-a"
}

variable "purpose" {
  default = "bm"
}

variable "spanner_instance" {
  default = "vllm-bm-inst"
}

variable "spanner_db" {
  default = "vllm-bm-runs"
}

variable "gcs_bucket" {
  default = "vllm-cb-storage2"
}
