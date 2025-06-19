variable "tpu_count" {
  type        = number
  description = "Number of TPU VMs to create"  
}

variable "tpu_zone" {
  type        = string
  description = "Zone to deploy TPU VMs and disks"
}

variable "region" {
    type        = string
}

variable "project_id" {
  type        = string
}

variable "spanner_instance" {
  type        = string
}

variable "spanner_db" {
  type        = string
}

variable "gcs_bucket" {
  type        = string
}

variable "startup_script_path" {
  type        = string
  description = "Path to shared startup script template"
}

variable "accelerator_type" {
  type        = string
  description = "Path to shared startup script template"
}

variable "purpose" {
  type        = string
  description = "Path to shared startup script template"
}

variable "mnt_disk_gb" {
  type        = number
  default     = 512
}

variable "purpose" {
  type        = string
  description = "Path to shared startup script template"
}

variable "branch_hash" {
  type        = string
  description = "commit hash of bm-infra branch."
}
