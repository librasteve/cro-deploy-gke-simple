unit module Cro::Deploy::GKE::Simple:ver<0.0.1>:auth<Steve Roe (p6steve@furnival.net)>;
#fixme - deconfuse web name

class App is export {
    has Str $.name is required;
    has Str $.version is required;
    has Int $.target-port = 8080;
    has Str $.project-id is required;
    has Str $.ip-address is rw;

    method cont-name {
        "{ $.name }-app"
    }
    method cont-image {
        "gcr.io/{ $.project-id }/{ $.cont-name }:{ $.version }";
    }
    method cluster-name {
        "{ $.name }-cluster"
    }
    method ip-name {
        "{ $.name }-ip"
    }
    method dep-name {
        "{ $.name }web"
    }
    method svc-name {
        "{ $.dep-name }-backend"
    }
}

class Manifest {
    has App $.app;
}

class Deployment is Manifest is export {
    method filename {
        "{ $.app.name }web-deployment.yaml";
    }
    method document {
        qq:to/FINISH/;
# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# [START container_{ $.app.name }app_deployment]
apiVersion: apps/v1
kind: Deployment
metadata:
  name: { $.app.dep-name }
  labels:
    app: { $.app.name }
spec:
  selector:
    matchLabels:
      app: { $.app.name }
      tier: web
  template:
    metadata:
      labels:
        app: { $.app.name }
        tier: web
    spec:
      containers:
      - name: { $.app.cont-name }
        image: { $.app.cont-image }
        ports:
        - containerPort: { $.app.target-port }
        resources:
          requests:
            cpu: 200m
# [END container_{ $.app.name }app_deployment]
FINISH
    }
}

class IngressStaticIP is Manifest is export {
    method filename {
        "{ $.app.name }web-ingress-static-ip.yaml";
    }
    method document {
        qq:to/FINISH/;
# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# [START container_{ $.app.name }app_ingress]
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: { $.app.dep-name }
  annotations:
    kubernetes.io/ingress.global-static-ip-name: { $.app.ip-name }
  labels:
    app: { $.app.name }
spec:
  backend:
    serviceName: { $.app.svc-name }
    servicePort: { $.app.target-port }
---
apiVersion: v1
kind: Service
metadata:
  name: { $.app.svc-name }
  labels:
    app: { $.app.name }
spec:
  type: NodePort
  selector:
    app: { $.app.name }
    tier: web
  ports:
  - port: { $.app.target-port }
    targetPort: { $.app.target-port }
# [END container_{ $.app.name }app_ingress]
FINISH
    }
}

#EOF
