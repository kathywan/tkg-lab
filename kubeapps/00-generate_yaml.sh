#!/bin/bash -e

if [ ! $# -eq 1 ]; then
  echo "Must supply cluster_name as args"
  exit 1
fi

CLUSTER_NAME=$1

KUBEAPPS_CN=$(yq r $PARAMS_YAML kubeapps.kubeapps-cn)

mkdir -p generated/$CLUSTER_NAME/kubeapps

# 01-namespace.yaml
yq read kubeapps/01-namespace.yaml > generated/$CLUSTER_NAME/kubeapps/01-namespace.yaml

# 02-certs.yaml
yq read kubeapps/02-certs.yaml > generated/$CLUSTER_NAME/kubeapps/02-certs.yaml
yq write generated/$CLUSTER_NAME/kubeapps/02-certs.yaml -i "spec.commonName" $KUBEAPPS_CN
yq write generated/$CLUSTER_NAME/kubeapps/02-certs.yaml -i "spec.dnsNames[0]" $KUBEAPPS_CN
yq write generated/$CLUSTER_NAME/kubeapps/02-certs.yaml -i "spec.secretName" ${KUBEAPPS_CN}-tls

# kubeapps-values.yaml
yq read kubeapps/kubeapps-values.yaml > generated/$CLUSTER_NAME/kubeapps/kubeapps-values.yaml
yq write generated/$CLUSTER_NAME/kubeapps/kubeapps-values.yaml -i "ingress.hostname" $KUBEAPPS_CN  
