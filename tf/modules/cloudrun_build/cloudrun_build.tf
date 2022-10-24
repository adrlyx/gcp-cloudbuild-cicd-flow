# Create a Artifact Registry for container images
resource "google_artifact_registry_repository" "my-repo" {
  project       = var.google_project.project_id
  location      = var.location
  repository_id = var.registry_repository_name
  description   = "example docker repository"
  format        = "DOCKER"
}

# When building containers using Cloud Build it will automatically
# create a storage bucket for it self. However, that bucket is
# created in a region that our organisation policy doesn't allow.
# Therefor we create a bucket whose name matches what Cloud Build
# expects in the correct region.
resource "google_storage_bucket" "cloud_build_bucket" {
  name          = "${var.google_project.project_id}_cloudbuild"
  location      = var.location
  project       = var.google_project.project_id
  force_destroy = true
}

# To be able to view logs from the Cloud Build Service Account
# we need to specify a cloud bucket from build logs.
resource "google_storage_bucket" "cloud_build_logs" {
  name          = "${var.google_project.project_id}_cloudbuild_logs"
  location      = var.location
  project       = var.google_project.project_id
  force_destroy = true
}
