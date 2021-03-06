#!/bin/bash -e

source ./scripts/set-env.sh

if [ ! $# -eq 1 ]; then
  echo "Must supply ingress-fqdn as arg"
  exit 1
fi
ingress_fqdn=$1
CLOUDDNS_HOSTED_ZONE=$(yq r $PARAMS_YAML gcp.cloud-dns-zone-name)

IAAS=$(yq r $PARAMS_YAML iaas)
echo "IAAS $IAAS"
if [ "$IAAS" = "aws" ];
then
  hostname=`kubectl get svc envoy -n tanzu-system-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'.` #for CNAME, hostname need to end with .
  record_type="CNAME"
else
  hostname=`kubectl get svc envoy -n tanzu-system-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`
  record_type="A"
fi
echo "hostname $hostname"
echo "CLOUDDNS_HOSTED_ZONE $CLOUDDNS_HOSTED_ZONE"
echo "ingress_fqdn $ingress_fqdn"
echo "record_type $record_type"

# Execute the change
gcloud dns record-sets transaction start --zone $CLOUDDNS_HOSTED_ZONE
existingDnsRecord=$(gcloud dns record-sets list --zone $CLOUDDNS_HOSTED_ZONE --name "${ingress_fqdn}")
if [ ! -z "$existingDnsRecord" ]; then
    #remove existing record
    CURR_CNAME=$(gcloud dns record-sets list --zone $CLOUDDNS_HOSTED_ZONE | grep "${ingress_fqdn}" | awk '{print $4}') 
    gcloud dns record-sets transaction remove --zone $CLOUDDNS_HOSTED_ZONE --name "${ingress_fqdn}" --type ${record_type} $CURR_CNAME --ttl 300
    # gcloud dns record-sets transaction execute --zone $CLOUDDNS_HOSTED_ZONE
    # sleep 20s # needs better way here to make sure traction completed
fi
#Now Create new record
# gcloud dns record-sets transaction start --zone $CLOUDDNS_HOSTED_ZONE
gcloud dns record-sets transaction add  "${hostname}" --zone $CLOUDDNS_HOSTED_ZONE --name "${ingress_fqdn}" --type ${record_type} --ttl 300
gcloud dns record-sets transaction execute --zone $CLOUDDNS_HOSTED_ZONE

