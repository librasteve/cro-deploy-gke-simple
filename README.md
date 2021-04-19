[![Build Status](https://travis-ci.com/p6steve/cro-deploy-gke-simple.svg?branch=master)](https://travis-ci.com/p6steve/cro-deploy-gke-simple)

# Deploy a raku Cro app on GKE (simple)
_Please be sure to check clean up to avoid any unwanted bills_

# SYNOPSIS
```bash
#usual Cro / Docker setup
cro stub http hicro hicro
cd hicro
docker build -t hicro .
docker run --rm -p 10000:10000 hicro   [local test, view in browser, stop]

#deploy to GKE
cro-gke-create.raku .
#clean-up
cro-gke-delete.raku .
```

# FEATURES
This is a simple (ie. very basic) raku script to one-step deploy a Cro app to GKE, it does the following:
* build, tag [check] and push the Docker container image to Google Container Registry
* create a GKE cluster
* create a global static IP address
* create & apply Deployment and IngressStaticIP manifest files
* delete all the above

Track status (& costs) on your [Kubernetes Engine Console](https://console.cloud.google.com/kubernetes/discovery) and [Google Container Repo](https://console.cloud.google.com/gcr/images)

# PREREQUISITES
* RakudoStar and Docker
* Cro ```zef install --/test cro``` - viz. https://cro.services
* Google Cloud Platform Account - viz. https://console.cloud.google.com/home/dashboard
  * with an active project (payment method & Kubernetes Engine API enabled)
* Google Cloud SDK CLI installed and in your path - viz. https://cloud.google.com/sdk/docs/quickstart
  * check this with ```gcloud auth list``` & ```gcloud config list```
  * install Kubernetes CLI tool with ```gcloud components install kubectl```
* Use gcloud config to set your project and compute zone
  * ```gcloud config set project YOUR_PROJECT_ID```
  * ```gcloud config set compute/zone YOUR_COMPUTE_ZONE``` (eg. 'us-west1-a')
