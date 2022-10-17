# Create a Artifact Registry for container images
resource "google_artifact_registry_repository" "my-repo" {
  project       = var.project_id
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
  name          = "${var.project_id}_cloudbuild"
  location      = var.location
  project       = var.project_id
  force_destroy = true
}

# To be able to view logs from the Cloud Build Service Account
# we need to specify a cloud bucket from build logs.
resource "google_storage_bucket" "cloud_build_logs" {
  name          = "${var.project_id}_cloudbuild_logs"
  location      = var.location
  project       = var.project_id
  force_destroy = true
}

### IAM Policies ###
resource "google_project_iam_binding" "cloudrun_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  members = [
    "serviceAccount:${var.service_account}",
    "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
  ]
}

resource "google_project_iam_binding" "artifactory_admin" {
  project = var.project_id
  role    = "roles/artifactregistry.admin"
  members = [
    "serviceAccount:${var.service_account}",
    "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com",
  ]
}

# Needs to be Storage Admin to be able to reach temporary buckets
resource "google_project_iam_binding" "storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  members = [
    "serviceAccount:${var.service_account}",
    "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com",
    "serviceAccount:service-${var.project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
  ]
}

resource "google_project_iam_binding" "cloudbuild_admin" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.builder"
  members = [
    "serviceAccount:${var.service_account}",
  ]
}

# #Needs to be Storage Admin to be able to reach temporary buckets
# resource "google_project_iam_binding" "account_user" {
#   project = var.project_id
#   role    = "roles/iam.serviceAccountUser"
#   members = [
#     "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
#   ]
# }
