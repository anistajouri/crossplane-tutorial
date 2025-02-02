#!/bin/sh
#gcloud auth login

export PROJECT_ID=project-custom-01

gcloud config set project $PROJECT_ID

echo "export PROJECT_ID=$PROJECT_ID" >>.env

gcloud services enable container.googleapis.com

gcloud services enable sqladmin.googleapis.com

gum input --placeholder "Press the enter key to continue."

export SA_NAME=devops-toolkit

export SA="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud iam service-accounts create $SA_NAME \
        --project $PROJECT_ID

export ROLE=roles/admin

gcloud projects add-iam-policy-binding \
        --role $ROLE $PROJECT_ID --member serviceAccount:$SA

gcloud iam service-accounts keys create gcp-creds.json \
        --project $PROJECT_ID --iam-account $SA

kubectl --namespace crossplane-system \
        create secret generic gcp-creds \
        --from-file creds=./gcp-creds.json

echo "
apiVersion: gcp.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  projectID: $PROJECT_ID
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: gcp-creds
      key: creds" | kubectl apply --filename -
