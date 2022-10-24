# gcp-cloudbuild-cicd-flow

> **Note**<br><br>
> * You need to have a billing account in GCP to use this repo.
> * You need to have gcloud installed
> * You need to be authenticated with your Google account and have sufficient privileges in GCP to run Terraform

## What is this?
This is a repo that contains the nessasary code to build and deploy an example website to Google Cloud Run in a multi-env fashion. With the help of the terraform code in './tf' you can set up all infrastructure that is needed in Google Cloud to build and deploy images for the pre-defined environments 'prod' and 'latest'. Terraform will also setup Workload Identity Federation to your repo for Github Actions authentication to be able to run 'gcloud' commands. In '.github/workflows' there are two CI/CD processes prepared for pushes towards branches 'prod' and 'latest'. When push on one of those branches, Github Actions will trigger and do the following:

    1. Checkout repo.
    2. Read json config file.
    3. Change variables in cloudbuild.yaml that will be used when running gcloud.
        The cloudbuild.yaml have 3 steps.
        #1: Build docker image remote
        #2: Push docker image to Artifact Registry
        #3: Publish image as a Cloud Run Service
    4. Authenticate to Google Cloud Platform with Workload Identity Federation.
    5. Run 'gcloud build' with the cloudbuild.yaml file as input config.

Gcloud will build what is instructed by the 'Dockerfile' located at top level folder.
In this example it will build a static nginx website based on the code in './app'.
<br />

## Prerequisites

1. Change all TODOs in the following files:

```
    tf/main.tf
```

2. You need to be authenticated with your GCP account to be able to run Terraform.

3. In conf/github_actions_config_latest.json and github_actions_config_prod.json set the APP_NAME and REGISTRY_NAME same as in main.tf.

```
"APP_NAME": ""
"REGISTRY_NAME": ""
```

## How to use

1. Clone repo.
2. Complete all "Prerequisites"
3. Run Terraform from the tf/ folder.

```
    $ > terraform init
    $ > terraform plan
    $ > terraform apply
```

4. From the terraform output update set up these secrets in your Github repo:

```
    secrets.PROVIDER_ID
    secrets.SERVICE_ACCOUNT
    secrets.PROJECT_ID
```

5. Create prod, latest and dev branches in your Github repo.
Make sure to protect branches prod and latest with reviewrs before pushing to the repos.

6. When push on branches prod and latest Github Actions will trigger and do the following:

    1. Checkout repo.
    2. Read json config file.
    3. Change variables in cloudbuild.yaml that will be used when running gcloud.
        The cloudbuild.yaml have 3 steps.
        #1: Build docker image remote
        #2: Push docker image to Artifact Registry
        #3: Publish image as a Cloud Run Service
    4. Authenticate to Google Cloud Platform with Workload Identity Federation.
    5. Run 'gcloud build' with the cloudbuild.yaml file as input config.

Gcloud will build what is instructed by the 'Dockerfile' located at top level folder.
In this example it will build a static nginx website based on the code in './app'.

<br />

# FAQ ?

### What does Terraform do?

Terraform will create the following resources in Google Cloud Platform.

```
Terraform:
    - Google Cloud Project
        - Enable necessary APIs
        - Service Account for Cloud Run
        - Default VPC
    - Workload Identity Federation
        - Service Account for Github
        - Identity Pool
        - Github Identity Pool Provider
        - Correct IAM bindings
    - Cloud Build
        - Artifact Registry
        - Default Cloud Build bucket
        - Logs bucket
        - Correct IAM bindings
    - Cloud Run
        - Service for prod
        - Service for latest
        - noauth settings
```

### IAM Walkthrough ###

**Relevant Accounts:**
* "project number"@cloudbuild.gserviceaccount.com
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

**Terraform IAM resources:**
- **google_project_iam_binding.cloudrun_admin:**

    Give the Cloud Run SA run.admin role to be able to update
    Cloud Run Services.
- google_project_iam_binding.cloudrun_viewer:**
    
    The default Google SA '@cloudbuild' is used by github integration
    and needs permissions to handle Cloud Run instanses on deploy.
- **google_project_iam_custom_role.bucket_viewer:**
    
    Creates a custom role that has the permission to list buckets
    (storage.buckets.list). There is no default role in GCP that
    only allows a SA to list buckets.
- **google_project_iam_binding.viewer:**
    
    Gives the github identity SA and Cloudbuild SA the role bucket_viewer.
- **google_project_iam_binding.storage_admin:**
    
    Gives the github identity SA and Cloudbuild SA storage admin role
    but with a condition to two specific buckets that are created by
    the module "cloudrun_build". This combined with the permission
    above gives these accounts only the nessasary permissions to
    the buckets.
- **google_service_account_iam_member.act_as_compute_sa:**
    
    Gives the default Cloudbuild SA permissions to impersonate
    the Cloud Run SA that are created by the module "cloudrun".
- **google_project_iam_binding.serviceaccount_user:**
    
    Allows the github identity SA to impersonate other service accounts.
- **google_project_iam_binding.artifactory_admin:**
    
    Give the default Cloudbuild SA the role artifactregistry.admin.
    This is needed to pull/push docker images to Artifact Registry.
- **google_project_iam_binding.cloudbuild_admin:**
    
    Give the github identity SA the role cloudbuild.builds.builder
    to be able to submit cloudbuilds.
- **google_project_iam_member.secrets_manager:**
    
    Assign the secretAccessor role to the Cloud Run SA.

<br />

## How do I ... ?

- How do I test Cloud Build manually?

```
gcloud builds submit --region=REGION --tag REGION-docker.pkg.dev/PROJECT_ID/REGISTRY_ID/APP_NAME:ENVIRONMENT
```

- How do I test Gloud Run Deploy manually?

```
gcloud run deploy APP_NAME --project=PROJECT_ID --image=REGION-docker.pkg.dev/PROJECT_ID/REGISTRY_ID/APP_NAME:ENVIRONMENT --region=REGION
```

***Notes*** 

*There is a lot more I want to do with this project but I will update with more notes later*
