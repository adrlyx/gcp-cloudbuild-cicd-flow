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
  project_id          = module.project.project_id
  repo = local.repo
  source                = "./modules/wip-github"
    depends_on = [
    module.project
  ]
}

module "cloudrun_build" {
  project_id                = module.project.project_id
  project_number            = module.project.project_number
  app_name                  = local.app_name
  location                  = local.location
  registry_repository_name  = local.registry_name
  cloud_run_sa              = module.project.cloud_run_sa
  service_account           = module.wip-github.service_account
  source                    = "./modules/cloudrun_build"
    depends_on = [
    module.project,
    module.wip-github
  ]
}

module "cloudrun_prod" {
  project_id                = module.project.project_id
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
  project_id                = module.project.project_id
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

# outputs
output "project_number" {
  value = module.project.project_number
}

output "project_id" {
  value = module.project.project_id
}

output "provider_id" {
  value = module.wip-github.provider_id
}

output "service_account" {
  value = module.wip-github.service_account
}
