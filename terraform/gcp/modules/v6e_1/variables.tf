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