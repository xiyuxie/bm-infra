variable "project_id" {
  default = "cloud-tpu-inference-test"
}

variable "region" {
    default = "southamerica-west1"
}

variable "tpu_zone" {
    default = "asia-east1-c"
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
  default     = 8
}

variable "v6e_4_count" {
  default     = 2
}

variable "v6e_8_count" {
  default     = 12
}

variable "instance_name_offset" {
  type        = number
  default     = 100
  description = "instance name offset so that we can distinguish machines from different project or region."
}

variable "branch_hash" {
  default     = "33d7a95ccac00f3e76d60c39e62d50d538f8fe40"
  description = "commit hash of bm-infra branch."
}
