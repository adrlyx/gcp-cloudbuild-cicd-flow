terraform {
  required_version = ">= 1.0.0"
}

# Default configuration for the google provider.
provider "google" {
  region = local.location
}

# Local variables
locals {
    project_name        = ""        # TODO: Name your project Max 25 ccrs
    location            = ""        # TODO: Example: europe-west1
    zone                = ""        # TODO: Example: europe-west1-b
    repo                = ""        # TODO: Name of Github repo, <org/repo> or <username/repo>
    billing_account     = ""        # TODO: Billing account for the GCP Project
    app_name            = ""        # TODO: App name for Cloud Run services
    registry_name       = ""        # TODO: Name your artifact registry where you images will be pushed
    folder_id           = ""        # TODO: Folder ID from GCP. Format: 'folders/<folder-id>'
    container_port      = ""        # TODO: Container port that your app uses
}

module "project" {
  project_name          = local.project_name
  billing_account       = local.billing_account
  folder_id             = local.folder_id
  source                = "./modules/project"
  app_name              = local.app_name
}

module "wip-github" {
  google_project          = module.project.google_project
  repo = local.repo
  source                = "./modules/wip-github"
    depends_on = [
    module.project
  ]
}

module "cloudrun_build" {
  google_project            = module.project.google_project
  location                  = local.location
  registry_repository_name  = local.registry_name
  source                    = "./modules/cloudrun_build"
    depends_on = [
    module.project,
    module.wip-github
  ]
}

module "cloudrun_prod" {
  google_project            = module.project.google_project
  app_name                  = local.app_name
  environment               = "prod"
  location                  = local.location
  cloud_run_sa              = module.project.cloud_run_sa
  container_port            = local.container_port
  source                    = "./modules/cloudrun"
    depends_on = [
      module.wip-github,
      module.project,
      module.cloudrun_build
  ]
}

module "cloudrun_latest" {
  google_project            = module.project.google_project
  app_name                  = local.app_name
  environment               = "latest"
  location                  = local.location
  container_port            = local.container_port
  cloud_run_sa              = module.project.cloud_run_sa
  source                    = "./modules/cloudrun"
    depends_on = [
      module.wip-github,
      module.project,
      module.cloudrun_build
  ]
}

module "iam" {
  google_project            = module.project.google_project
  cloud_run_sa              = module.project.cloud_run_sa
  github_sa                 = module.wip-github.github_sa
  source                    = "./modules/iam"
    depends_on = [
      module.wip-github,
      module.project,
      module.cloudrun_build,
      module.cloudrun_prod,
      module.cloudrun_latest
  ]
}

# outputs
output "project_number" {
  value = module.project.google_project.number
}

output "project_id" {
  value = module.project.google_project.project_id
}

output "provider_id" {
  value = module.wip-github.provider_id
}

output "github_service_account" {
  value = module.wip-github.github_sa.email
}
