#!/bin/sh
set -e

#########################
# Control Plane Cluster #
#########################

kind create cluster --config kind.yaml

kubectl apply \
    --filename https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml



##############
# Crossplane #
##############

helm upgrade --install crossplane crossplane \
    --repo https://charts.crossplane.io/stable \
    --namespace crossplane-system --create-namespace --wait

kubectl apply \
    --filename providers/provider-kubernetes-incluster.yaml

kubectl apply --filename providers/provider-helm-incluster.yaml

kubectl apply --filename providers/dot-kubernetes.yaml

kubectl apply --filename providers/dot-sql.yaml

kubectl apply --filename providers/dot-app.yaml

gum spin --spinner dot \
    --title "Waiting for Crossplane providers..." -- sleep 60

kubectl wait --for=condition=healthy provider.pkg.crossplane.io \
    --all --timeout=1800s


# Verify all providers are healthy
UNHEALTHY_PROVIDERS=$(kubectl get providers.pkg.crossplane.io -o json | jq -r '.items[] | select(.status.conditions[] | select(.type=="Healthy" and .status!="True")) | .metadata.name')

if [ -z "$UNHEALTHY_PROVIDERS" ]; then
    echo "✅ All Crossplane providers are healthy"
else
    echo "❌ Unhealthy providers found:"
    echo "$UNHEALTHY_PROVIDERS"
    exit 1
fi