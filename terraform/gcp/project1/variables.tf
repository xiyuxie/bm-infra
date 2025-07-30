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

variable "v6e_1_count" {
  default     = 4
}

variable "v6e_4_count" {
  default     = 0
}

variable "v6e_8_count" {
  default     = 4
}

variable "branch_hash" {
  default     = "83ede206090be6a442c0d8037b8edfd170b6d653"
  description = "commit hash of bm-infra branch."
}
