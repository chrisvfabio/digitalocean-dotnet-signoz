# digitalocean-dotnet-signoz

This repo demonstrates how to spin up a .NET Core Web API running in DigitalOcean App Service, and connect OpenTelemetry to [SigNoz](https://signoz.io/) running in [DigitalOcean Kubernetes Service (DOKS)](https://docs.digitalocean.com/products/kubernetes/).

This demo uses Terraform to provision the infrastructure. The Digital Ocean App is configured to point to the Dockerfile via GitHub integration. 

## Prerequisites

* Install [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
* Install [DOCTL](https://docs.digitalocean.com/reference/doctl/how-to/install/)
* Install [Kubernetes CLI](https://kubernetes.io/docs/tasks/tools/)
* [Generate a DigitalOcean Access Token](https://docs.digitalocean.com/reference/api/create-personal-access-token/)

## Step 1: Provision the Infrastructure

This step will bring up the DigitalOcean infrastructure using Terraform.

```bash
# Set the DigitalOcean Access Token in your environment
export DIGITALOCEAN_ACCESS_TOKEN="<DO_ACCESS_TOKEN>"

# Apply the Terraform to provision the infrastructure
terraform -chdir=infra/ apply --auto-approve
```

## Step 2: Configure the Kubernetes Cluster

This step will setup your local Kubernetes context, connect it to the newly created DOKS cluster. 

```bash
# Setup connection to cluster
export CLUSTER_NAME="k8s-sample-cluster" # Set in infra/main.tf
export CLUSTER_ID=$(doctl kubernetes cluster get $CLUSTER_NAME -o json | jq -rc '.[].id')
doctl kubernetes cluster kubeconfig save $CLUSTER_ID

# Create namespace for SigNoz
kubectl create ns signoz

# Install ingress-nginx via Helm
helm upgrade ingress-nginx ./kubernetes/ingress-nginx --install --namespace signoz --values ./kubernetes/ingress-nginx/values.yaml --wait

# Install cert-manager via Helm
helm upgrade cert-manager ./kubernetes/cert-manager --install --namespace signoz --values ./kubernetes/cert-manager/values.yaml --wait
kubectl apply -f ./kubernetes/cert-manager-issuers

# Install signoz via Helm and waits for pods to become available - may take a few minutes
helm upgrade signoz ./kubernetes/signoz --install --namespace signoz --values ./kubernetes/signoz/values.yaml --wait
```

> Ignore this error
>  `Error: Get "https://38988dd2-98c6-4147-8eca-9308218b1ee9.k8s.ondigitalocean.com/apis/apps/v1/namespaces/signoz/deployments/signoz-frontend": context deadline exceeded`

## Step 3: Setting up DNS

```bash
# Fetch External IP of Nginx Load Balancer
kubectl get service/ingress-nginx-controller -n signoz -o json | jq -rc '.status.loadBalancer.ingress[0].ip'
# 146.190.193.132
```

Go to your DNS provider and setup the following DNS Records:

| Type | Name | Content |
|------|------|---------|
|  A   | signoz.upwork-32321074.proj.chrisvfab.io | 146.190.193.132 (changeme)
|  A   | signoz-otel.upwork-32321074.proj.chrisvfab.io | 146.190.193.132 (changeme)


> Setup whichever domain you like and ensure it points to the external ip of the nginx ingress controller.

Once your DNS is configured, test everything is working:

```bash
ping signoz.upwork-32321074.proj.chrisvfab.io
# PING signoz.upwork-32321074.proj.chrisvfab.io (146.190.193.132): 56 data bytes

ping signoz-otel.upwork-32321074.proj.chrisvfab.io
# PING signoz-otel.upwork-32321074.proj.chrisvfab.io (146.190.193.132): 56 data bytes

# nginx http -> https redirect
curl http://signoz.upwork-32321074.proj.chrisvfab.io
# <html>
# <head><title>308 Permanent Redirect</title></head>
# <body>
# <center><h1>308 Permanent Redirect</h1></center>
# <hr><center>nginx</center>
# </body>
# </html>
```

Wait for cert-manager to issue SSL certificates:

```bash
curl https://signoz-otel.upwork-32321074.proj.chrisvfab.io
# curl: (60) SSL certificate problem: unable to get local issuer certificate
# More details here: https://curl.se/docs/sslcerts.html
```

Checking the status of a cert-manager Certificate: 

```bash
# Check cert-manager Orders objects
kubectl get orders -n signoz
# NAME                                                             STATE     AGE
# signoz-otel.upwork-32321074.proj.chrisvfab.io-n5wph-2919482837   pending   15m
# signoz.upwork-32321074.proj.chrisvfab.io-jl6br-1750714804        pending   15m

export ORDER_NAME="signoz-otel.upwork-32321074.proj.chrisvfab.io-n5wph-2919482837"

# Check events and wait for the order to complete 
kubectl get events -n signoz --field-selector involvedObject.name=$ORDER_NAME
# LAST SEEN   TYPE     REASON     OBJECT                                                                 MESSAGE
# 2m3s        Normal   Complete   order/signoz-otel.upwork-32321074.proj.chrisvfab.io-n5wph-2919482837   Order completed successfully
```

> Alternatively, use the [kubectl cert-manager plugin](https://cert-manager.io/v1.0-docs/usage/kubectl-plugin/) to check the status of a cert. Run `kubectl cert-manager status signoz-otel.upwork-32321074.proj.chrisvfab.io`

## Step 4: Configure SigNoz

Open the SigNoz UI and follow the setup prompts: https://signoz.upwork-32321074.proj.chrisvfab.io/

## Step 5: Simulate Requests to the .NET Core Web API

```bash
# Open the live url of the DO App
export APP_URL=$(doctl apps list -o json | jq -rc '.[0].live_url')

curl "$APP_URL/weatherforecast"
```

Open the SigNoz Trace UI to see the metrics coming in: https://signoz.upwork-32321074.proj.chrisvfab.io/trace


