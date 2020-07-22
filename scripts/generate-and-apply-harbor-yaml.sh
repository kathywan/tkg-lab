#!/bin/bash -e

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

CLUSTER_NAME=$(yq r $PARAMS_YAML shared-services-cluster.name)

$TKG_LAB_SCRIPTS/../harbor/00-generate_yaml.sh $CLUSTER_NAME

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME
kubectl apply -f generated/$CLUSTER_NAME/harbor/01-namespace.yaml
kubectl apply -f generated/$CLUSTER_NAME/harbor/02-certs.yaml  

while kubectl get certificates -n harbor harbor-cert | grep True ; [ $? -ne 0 ]; do
	echo Harbor certificate is not yet ready
	sleep 5s
done   

helm repo add harbor https://helm.goharbor.io
helm upgrade --install harbor harbor/harbor -f generated/$CLUSTER_NAME/harbor/harbor-values.yaml --namespace harbor