variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "instance_name" {
  description = "Name of the Compute Engine instance"
  type        = string
  default     = "dify-server"
}

variable "machine_type" {
  description = "Machine type for the instance"
  type        = string
  default     = "e2-medium"
}

variable "boot_disk_image" {
  description = "Boot disk image"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "boot_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "boot_disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-standard"
}

variable "data_disk_size" {
  description = "Data disk size in GB for persistent storage"
  type        = number
  default     = 100
}

variable "ssh_user" {
  description = "SSH user name"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
  default     = ""
}

variable "service_account_email" {
  description = "Service account email for the instance"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment tag (e.g., production, staging)"
  type        = string
  default     = "production"
}

variable "domain_name" {
  description = "Domain name for Dify (e.g., dify.example.com)"
  type        = string
}

variable "email" {
  description = "Email address for SSL certificate (Let's Encrypt)"
  type        = string
}
