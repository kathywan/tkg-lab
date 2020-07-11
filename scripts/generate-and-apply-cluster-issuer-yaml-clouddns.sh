#!/bin/bash -e

source ./scripts/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster_name as args"
  exit 1
fi

CLUSTER_NAME=$1

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

mkdir -p generated/$CLUSTER_NAME/contour/


IAAS=$(yq r $PARAMS_YAML iaas)
LETS_ENCRYPT_ACME_EMAIL=$(yq r $PARAMS_YAML lets-encrypt-acme-email)

if [ "$IAAS" = "aws" ];
then
  yq read tkg-extensions-mods-examples/ingress/contour/contour-cluster-issuer-http.yaml > generated/$CLUSTER_NAME/contour/contour-cluster-issuer.yaml
else
  yq read tkg-extensions-mods-examples/ingress/contour/contour-cluster-issuer-clouddns.yaml > generated/$CLUSTER_NAME/contour/contour-cluster-issuer.yaml
  kubectl create secret generic certbot-gcp-service-account \
        --from-file=keys/certbot-gcp-service-account.json \
        -n cert-manager
  yq write -d0 generated/$CLUSTER_NAME/contour/contour-cluster-issuer.yaml -i "spec.acme.solvers[0].dns01.clouddns.project" $(yq r $PARAMS_YAML gcp.project)
fi
yq write -d0 generated/$CLUSTER_NAME/contour/contour-cluster-issuer.yaml -i "spec.acme.email" $LETS_ENCRYPT_ACME_EMAIL

kubectl apply -f generated/$CLUSTER_NAME/contour/contour-cluster-issuer.yaml 

