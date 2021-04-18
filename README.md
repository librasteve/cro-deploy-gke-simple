[![Build Status](https://travis-ci.com/p6steve/raku-Physics-Constants.svg?branch=master)](https://travis-ci.com/p6steve/raku-Physics-Constants)
^^FIXME

Deploy Raku Cro on Google Kubernetes Engine (simple)
_Take care to clean up to avoid any unwanted Google costs_

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

# SYNOPSIS
```
cro stub http hicro hicro
cd hicro
docker build -t hicro .
docker run --rm -p 10000:10000 hicro   [local test, view in browser, stop]

```

# FEATURES
This is a simple raku script for use with Linux/macOS to one-step deploy a Cro application to GKE, it does the following:
* build, tag and check the container image from Dockerfile for Google Container Registry
* 

# EXAMPLES
## HELLO-APP
Drawn from the GKE tutorials for Docker Container service and Static IP ingress deployment
* viz. https://cloud.google.com/kubernetes-engine/docs/tutorials/hello-app
* viz. https://cloud.google.com/kubernetes-engine/docs/tutorials/configuring-domain-name-static-ip
* actually this example app is written in go - not everyone is perfect
* this script embeds the second part of this tutorial (using manifests for service & ingress)

# SYNOPSIS

```perl6
use 
{...}
```

