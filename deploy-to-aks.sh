#!/bin/bash
trap 'echo interrupted; exit' INT
set -e


echo "Preparing to deploy resources to the cluster..."

kubeConfigFileName=kubeconfig
terraform -chdir=terraform output -raw kube_config > $kubeConfigFileName
export KUBECONFIG=$kubeConfigFileName

kubectl create namespace confluent || true
kubectl config set-context --current --namespace confluent

helm repo add confluentinc https://packages.confluent.io/helm
helm repo update

helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes

echo "Deploying..."

registryName=`terraform -chdir=terraform output -raw acr_name`
registryUrl=`terraform -chdir=terraform output -raw acr_url`
export CONNECTOR_IMAGE=$registryUrl/azure-source-expedia-connector:1.0.0

envsubst < confluent-platform.yaml | kubectl apply -f -
kubectl apply -f ./azure-source-topic.yaml

echo "Deployment initiated."
