/*

IAM Walkthrough

Check - Assign the secretAccessor role to that service account
Check - Give the cloud run SA run.admin role
Check - Default google SA @cloudbuild is used by github integration and needs permissions to handle cloudrun instances on deploy
Check - Role for sa to list buckets. Required for cloudbuild to read logs
Check - Give github identity SA & cloudbuild SA the role bucket_viewer
Check - Give github identity SA & cloudbuild SA storage admin role with access to specific buckets
Check - Make the default cloudbuild SA able to act as serviceAccountUser cloudbuild SA
Check - serviceaccount_user roles/iam.serviceAccountUser
Check - cloudbuild SA account the artifactregistry.admin
Check - Give the github identity SA the cloudbuild.builds.builder role

*/

# Assign the secretAccessor role to that service account
resource "google_project_iam_member" "app" {
  project = var.google_project.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${var.cloud_run_sa.email}"
}

# Give the cloud run SA run.admin role
resource "google_project_iam_binding" "cloudrun_admin" {
  project = var.google_project.project_id
  role    = "roles/run.admin"
  members = [
    "serviceAccount:${var.cloud_run_sa.email}"
  ]
}

# Default google SA @cloudbuild is used by github integration and 
# needs permissions to handle cloudrun instanses on deploy
resource "google_project_iam_binding" "cloudrun_viewer" {
  project = var.google_project.project_id
  role    = "roles/run.developer"
  members = [
    "serviceAccount:${var.google_project.number}@cloudbuild.gserviceaccount.com",
  ]
}

# Role for SA to list buckets. Required for cloudbuild to read logs
resource "google_project_iam_custom_role" "bucket_viewer" {
  project = var.google_project.project_id
  role_id     = "bucket_viewer"
  title       = "Bucket Viewer"
  description = "Role for sa to list buckets. Required for cloudbuild to read logs"
  permissions = ["storage.buckets.list"]
}

# Give github identity SA & cloudbuild SA the role bucket_viewer
resource "google_project_iam_binding" "viewer" {
  project = var.google_project.project_id
  role    = "projects/${var.google_project.project_id}/roles/bucket_viewer"
  members = [
    "serviceAccount:${var.github_sa.email}",
    "serviceAccount:${var.google_project.number}@cloudbuild.gserviceaccount.com"
  ]
}

# Give github identity SA & cloudbuild SA storage admin role with
# condition to a specific bucket
resource "google_project_iam_binding" "storage_admin" {
  project = var.google_project.project_id
  role    = "roles/storage.admin"
  members = [
    "serviceAccount:${var.github_sa.email}",
    "serviceAccount:${var.google_project.number}@cloudbuild.gserviceaccount.com"
  ]
  condition {
    title       = "Cloudbuild bucket admin"
    description = "Enable github build user to store temporary artifacts and logs."
    expression  = "resource.name.startsWith(\"projects/_/buckets/${var.google_project.project_id}_cloudbuild\")"
  }
}

# Make the default cloudbuild SA able to act as serviceAccountUser compute SA
resource "google_service_account_iam_member" "act_as_compute_sa" {
  service_account_id = "projects/${var.google_project.project_id}/serviceAccounts/${var.cloud_run_sa.email}"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.google_project.number}@cloudbuild.gserviceaccount.com"
}

# Allow github identity to iam.serviceAccountUser
resource "google_project_iam_binding" "serviceaccount_user" {
  project = var.google_project.project_id
  role    = "roles/iam.serviceAccountUser"

  members = [
    "serviceAccount:${var.github_sa.email}",
  ]
}

# cloudbuild SA account the artifactregistry.admin
resource "google_project_iam_binding" "artifactory_admin" {
  project = var.google_project.project_id
  role    = "roles/artifactregistry.admin"
  members = [
    "serviceAccount:${var.google_project.number}@cloudbuild.gserviceaccount.com",
  ]
}

# Stannar - # Give the github identity SA the cloudbuild.builds.builder role
resource "google_project_iam_binding" "cloudbuild_admin" {
  project = var.google_project.project_id
  role    = "roles/cloudbuild.builds.builder"
  members = [
    "serviceAccount:${var.github_sa.email}"
  ]
}