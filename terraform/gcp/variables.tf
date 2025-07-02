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
  default     = 16
}

variable "v6e_4_count" {
  default     = 1
}

variable "v6e_8_count" {
  default     = 12
}

variable "branch_hash" {
  default     = "9c279c3b7862fcee7540cea9be2678cf729c2ac1"
  description = "commit hash of bm-infra branch."
}
