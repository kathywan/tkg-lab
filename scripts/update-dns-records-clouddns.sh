#!/bin/bash -e

source ./scripts/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply ingress-fqdn as arg"
  exit 1
fi
ingress_fqdn=$1
CLOUDDNS_HOSTED_ZONE=$(yq r $PARAMS_YAML gcp.cloud-dns-zone-name)

IAAS=$(yq r $PARAMS_YAML iaas)

if [ "$IAAS" = "aws" ];
then
  hostname=`kubectl get svc envoy -n tanzu-system-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'`
  record_type="CNAME"
else
  hostname=`kubectl get svc envoy -n tanzu-system-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`
  record_type="A"
fi
echo "hostname $hostname"
echo "CLOUDDNS_HOSTED_ZONE $CLOUDDNS_HOSTED_ZONE"
echo "ingress_fqdn $ingress_fqdn"


# Execute the change
existingDnsRecord=$(gcloud dns record-sets list --zone $CLOUDDNS_HOSTED_ZONE --name "${ingress_fqdn}")
if [ ! -z "$existingDnsRecord" ]; then
    #remove existing record
    CURR_CNAME=$(gcloud dns record-sets list --zone $CLOUDDNS_HOSTED_ZONE | grep "${ingress_fqdn}" | awk '{print $4}') 
    gcloud dns record-sets transaction start --zone $CLOUDDNS_HOSTED_ZONE
    gcloud dns record-sets transaction remove --zone $CLOUDDNS_HOSTED_ZONE --name "${ingress_fqdn}" --type ${record_type} $CURR_CNAME --ttl 300
    gcloud dns record-sets transaction execute --zone $CLOUDDNS_HOSTED_ZONE
    sleep 10s
fi
#Now Create new record
gcloud dns record-sets transaction start --zone $CLOUDDNS_HOSTED_ZONE
gcloud dns record-sets transaction add --zone $CLOUDDNS_HOSTED_ZONE --name "${ingress_fqdn}" --type ${record_type} ${hostname} --ttl 300
gcloud dns record-sets transaction execute --zone $CLOUDDNS_HOSTED_ZONE

