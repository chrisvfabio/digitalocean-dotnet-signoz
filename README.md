# digitalocean-dotnet-signoz


```bash
# Set DO access token
export DIGITALOCEAN_ACCESS_TOKEN="<DO_ACCESS_TOKEN"

# Provison .NET DO app + DO Kubernetes Cluster
cd infra/
terraform apply --auto-approve
cd ..

# Pull kubeconfig
export CLUSTER_ID=$(doctl kubernetes cluster get k8s-sample-cluster -o json | jq -rc '.[].id')
doctl kubernetes cluster kubeconfig save $CLUSTER_ID

# Create namespace
kubectl create ns signoz

# Install ingress-nginx
helm upgrade ingress-nginx ./kubernetes/ingress-nginx --install --namespace signoz --values ./kubernetes/ingress-nginx/values.yaml --wait

# Install cert-manager
helm upgrade cert-manager ./kubernetes/cert-manager --install --namespace signoz --values ./kubernetes/cert-manager/values.yaml --wait
kubectl apply -f ./kubernetes/cert-manager-issuers

# Install signoz helm chart and waits for pods to become available - may take a few minutes
helm upgrade signoz ./kubernetes/signoz --install --namespace signoz --values ./kubernetes/signoz/values.yaml --wait



# Setup DNS

# Create SigNoz Users

# Test .NET App, check logs 


# Wait for pods to become available
kubectl port-forward -n signoz svc/signoz-frontend 3301:3301

# sample-app.upwork-32321074.proj.chrisvfab.io
# signoz.upwork-32321074.proj.chrisvfab.io
# signoz-otel.upwork-32321074.proj.chrisvfab.io

```