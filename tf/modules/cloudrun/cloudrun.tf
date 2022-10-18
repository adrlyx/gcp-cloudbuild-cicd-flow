# Create the Cloud Run service.
resource "google_cloud_run_service" "application" {
  provider = google-beta
  name     = "${var.app_name}-${var.environment}"
  location = var.location
  project  = var.project_id

  template {
    spec {
      containers {
        env {
          name  = "NODE_ENV"
          value = var.environment
        }
        ports {
          container_port = "${var.container_port}"
        }
        # The image field is required when creating a Cloud Run service.
        # However, we don't want to use Terraform to control which image
        # is running. Therefor we add a dummy value and make sure that it
        # is ignored when updateing (see the lifecycle block below).
        image = "gcr.io/google-samples/hello-app:1.0"
      }
      service_account_name = var.cloud_run_sa
    }
  }
  metadata {
    annotations = {
      "run.googleapis.com/ingress"      = "all",
      "run.googleapis.com/client-name"    = "gcloud", 
      "run.googleapis.com/client-version" = "405.0.1"
    }
  }
  autogenerate_revision_name = true

  # As we don't use Terraform to control which image is deployed we
  # don't want the `image` field to be applied when we make updates.
  lifecycle {
    ignore_changes = [
      template[0].spec[0].containers[0].image,
    ]
  }
}

# Create a policy for allowing everyone to invoke Cloud Run. This is needed
# for apps which should be publicly available.
data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

# Bind the above policy to our Cloud Run service.
resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_service.application.location
  project  = google_cloud_run_service.application.project
  service  = google_cloud_run_service.application.name

  policy_data = data.google_iam_policy.noauth.policy_data
}