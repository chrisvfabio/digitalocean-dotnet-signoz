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
cd infra/

# Set the DigitalOcean Access Token in your environment
export DIGITALOCEAN_ACCESS_TOKEN="<DO_ACCESS_TOKEN>"

# Apply the Terraform to provision the infrastructure
terraform apply --auto-approve
```

## Step 2: Configure the Kubernetes Cluster

This step will setup your local Kubernetes context, connect it to the newly created DOKS cluster. 

```
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


# Setup DNS

# Create SigNoz Users

# Test .NET App, check logs 


# Wait for pods to become available
kubectl port-forward -n signoz svc/signoz-frontend 3301:3301

# sample-app.upwork-32321074.proj.chrisvfab.io
# signoz.upwork-32321074.proj.chrisvfab.io
# signoz-otel.upwork-32321074.proj.chrisvfab.io

```
