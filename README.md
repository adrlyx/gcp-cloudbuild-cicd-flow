# gcp-cloudbuild-cicd-flow

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

## Motivation?
The goal was...
<br />
<br />

## Prerequisites

1. Change all TODOs in the following files:

```
    tf/main.tf
    tf/modules/cloudrun/cloudrun.tf
```

2. You need to be authenticated with your GCP account to be able to run Terraform.

3. In conf/github_actions_config_latest.json and github_actions_config_prod.json set the APP_NAME same as in main.tf.

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
