variable "tpu_count" {
  type        = number
  description = "Number of TPU VMs to create"
  default     = 1
}

variable "tpu_zone" {
  type        = string
  description = "Zone to deploy TPU VMs and disks"
  default     = "southamerica-west1-a"
}

variable "region" {
    default = "southamerica-west1"
}

variable "project_id" {
  default = "cloud-tpu-inference-test"
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

variable "hf_token" {
  description = "Hugging Face API token"
  type        = string
  sensitive   = true
}
