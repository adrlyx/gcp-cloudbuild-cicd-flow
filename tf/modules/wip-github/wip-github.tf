resource "google_service_account" "github_identity" {
  account_id   = "github-identity"
  display_name = "Workload identity for github"
  project      = var.project_id
}

resource "google_iam_workload_identity_pool" "github_identity" {
  provider                  = google-beta
  workload_identity_pool_id = "github-identity-pool"
  project                   = var.project_id
}

resource "google_iam_workload_identity_pool_provider" "github_identity" {
  provider                           = google-beta
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_identity.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-identity-provider"
  project                            = var.project_id
  attribute_mapping                  = var.attribute_mapping

  oidc {
    issuer_uri = var.issuer_uri
  }
}

resource "google_service_account_iam_binding" "github_identity_user" {
  service_account_id = google_service_account.github_identity.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_identity.name}/attribute.repository/${var.repo}",
  ]
}

resource "google_project_iam_binding" "serviceaccount_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"

  members = [
    "serviceAccount:${google_service_account.github_identity.email}",
  ]
}

output "provider_id" {
  value = google_iam_workload_identity_pool_provider.github_identity.name
}

output "service_account" {
  value = google_service_account.github_identity.email
}