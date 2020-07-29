#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster_name arg"
  exit 1
fi

CLUSTER_NAME=$1

$TKG_LAB_SCRIPTS/../kubeapps/00-generate_yaml.sh $CLUSTER_NAME

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME
kubectl apply -f generated/$CLUSTER_NAME/kubeapps/01-namespace.yaml
kubectl apply -f generated/$CLUSTER_NAME/kubeapps/02-certs.yaml  

while kubectl get certificates -n kubeapps kubeapps-cert | grep True ; [ $? -ne 0 ]; do
	echo Kubeapps certificate is not yet ready
	sleep 5s
done   

helm repo add bitnami https://charts.bitnami.com/bitnami
helm upgrade --install kubeapps bitnami/kubeapps -f generated/$CLUSTER_NAME/kubeapps/kubeapps-values.yaml --namespace kubeapps
