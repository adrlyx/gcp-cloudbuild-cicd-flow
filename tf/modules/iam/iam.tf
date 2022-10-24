/*
IAM Walkthrough

Relevant Accounts:
* <project number>@@cloudbuild.gserviceaccount.com
    This account is a default account for each Google Cloud Project.
    It is used by GCP with Cloud Build to pull/push/deploy container images.
* Cloud Run Service Account
    This SA is created in the terraform module "cloudrun" and is
    only created to handle Cloud Run Services. I do this to
    separate SAs different permissions.
* Github Identity Service Account
    This SA is created in the terraform module "wip-github" and is
    created to be the SA that github actions will use.
    This SA is allowed to impersonate other service accounts to be
    able to run Cloud Build and deploy Cloud Run Services.


google_project_iam_binding.cloudrun_admin:
    Give the Cloud Run SA run.admin role to be able to update
    Cloud Run Services.
google_project_iam_binding.cloudrun_viewer:
    The default Google SA '@cloudbuild' is used by github integration
    and needs permissions to handle Cloud Run instanses on deploy.
google_project_iam_custom_role.bucket_viewer:
    Creates a custom role that has the permission to list buckets
    (storage.buckets.list). There is no default role in GCP that
    only allows a SA to list buckets.
google_project_iam_binding.viewer:
    Gives the github identity SA and Cloudbuild SA the role bucket_viewer.
google_project_iam_binding.storage_admin:
    Gives the github identity SA and Cloudbuild SA storage admin role
    but with a condition to two specific buckets that are created by
    the module "cloudrun_build". This combined with the permission
    above gives these accounts only the nessasary permissions to
    the buckets.
google_service_account_iam_member.act_as_compute_sa:
    Gives the default Cloudbuild SA permissions to impersonate
    the Cloud Run SA that are created by the module "cloudrun".
google_project_iam_binding.serviceaccount_user:
    Allows the github identity SA to impersonate other service accounts.
google_project_iam_binding.artifactory_admin:
    Give the default Cloudbuild SA the role artifactregistry.admin.
    This is needed to pull/push docker images to Artifact Registry.
google_project_iam_binding.cloudbuild_admin:
    Give the github identity SA the role cloudbuild.builds.builder
    to be able to submit cloudbuilds.
google_project_iam_member.secrets_manager:
    Assign the secretAccessor role to the Cloud Run SA.

*/

# Give the Cloud Run SA run.admin role to be able to update
# Cloud Run Services.
resource "google_project_iam_binding" "cloudrun_admin" {
  project = var.google_project.project_id
  role    = "roles/run.admin"
  members = [
    "serviceAccount:${var.cloud_run_sa.email}"
  ]
}

# The default Google SA '@cloudbuild' is used by github integration
# and needs permissions to handle Cloud Run instanses on deploy.
resource "google_project_iam_binding" "cloudrun_viewer" {
  project = var.google_project.project_id
  role    = "roles/run.developer"
  members = [
    "serviceAccount:${var.google_project.number}@cloudbuild.gserviceaccount.com",
  ]
}

# Creates a custom role that has the permission to list buckets
# (storage.buckets.list). There is no default role in GCP that
# only allows a SA to list buckets.
resource "google_project_iam_custom_role" "bucket_viewer" {
  project = var.google_project.project_id
  role_id     = "bucket_viewer"
  title       = "Bucket Viewer"
  description = "Role for sa to list buckets. Required for cloudbuild to read logs"
  permissions = ["storage.buckets.list"]
}

# Gives the github identity SA and Cloudbuild SA the role bucket_viewer.
resource "google_project_iam_binding" "viewer" {
  project = var.google_project.project_id
  role    = "projects/${var.google_project.project_id}/roles/bucket_viewer"
  members = [
    "serviceAccount:${var.github_sa.email}",
    "serviceAccount:${var.google_project.number}@cloudbuild.gserviceaccount.com"
  ]
}

# Gives the github identity SA and Cloudbuild SA storage admin role
# but with a condition to two specific buckets that are created by
# the module "cloudrun_build". This combined with the permission
# above gives these accounts only the nessasary permissions to
# the buckets.
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

# Gives the default Cloudbuild SA permissions to impersonate
# the Cloud Run SA that are created by the module "cloudrun".
resource "google_service_account_iam_member" "act_as_compute_sa" {
  service_account_id = "projects/${var.google_project.project_id}/serviceAccounts/${var.cloud_run_sa.email}"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.google_project.number}@cloudbuild.gserviceaccount.com"
}

# Allows the github identity SA to impersonate other service accounts.
resource "google_project_iam_binding" "serviceaccount_user" {
  project = var.google_project.project_id
  role    = "roles/iam.serviceAccountUser"

  members = [
    "serviceAccount:${var.github_sa.email}",
  ]
}

# Give the default Cloudbuild SA the role artifactregistry.admin.
# This is needed to pull/push docker images to Artifact Registry.
resource "google_project_iam_binding" "artifactory_admin" {
  project = var.google_project.project_id
  role    = "roles/artifactregistry.admin"
  members = [
    "serviceAccount:${var.google_project.number}@cloudbuild.gserviceaccount.com",
  ]
}

# Give the github identity SA the role cloudbuild.builds.builder
# to be able to submit cloudbuilds.
resource "google_project_iam_binding" "cloudbuild_admin" {
  project = var.google_project.project_id
  role    = "roles/cloudbuild.builds.builder"
  members = [
    "serviceAccount:${var.github_sa.email}"
  ]
}

# Assign the secretAccessor role to the Cloud Run SA.
resource "google_project_iam_member" "secrets_manager" {
  project = var.google_project.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${var.cloud_run_sa.email}"
}
