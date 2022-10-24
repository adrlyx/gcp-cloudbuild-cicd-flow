variable "app_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "google_project" {
  type = any
}

variable "cloud_run_sa" {
  type = any
}

variable "container_port" {
  type = string
}
