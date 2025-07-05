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
  default     = 0
}

variable "v6e_8_count" {
  default     = 12
}

variable "branch_hash" {
  default     = "92c05d4fdeb92661b4ffc3ff0b4a01e358b0a4e7"
  description = "commit hash of bm-infra branch."
}
