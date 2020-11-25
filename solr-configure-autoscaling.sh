#!/bin/bash

# retrieve first Solr node
SOLR_URL=$(terraform output -state=terraform-workspaces/aws-solr-instances/terraform.tfstate -json | jq -r '.solr_instance_urls.value[0]')

curl -X POST -H 'Content-type:application/json' \
    --data-binary @solr-config/set-cluster-policy.json \
    "${SOLR_URL}/api/cluster/autoscaling"

curl -X POST -H 'Content-type:application/json' \
    --data-binary @solr-config/set-trigger-node-added.json \
    "${SOLR_URL}/api/cluster/autoscaling"

curl -X POST -H 'Content-type:application/json' \
    --data-binary @solr-config/set-trigger-node-lost.json \
    "${SOLR_URL}/api/cluster/autoscaling"

echo "----------------------------------------------------------------"
echo " AUTOSCALING DIAGNOSTICS:"
echo " curl -s ${SOLR_URL}/solr/admin/autoscaling/diagnostics | jq ."
echo ""
echo " AUTOSCALING CONFIGURATION:"
echo " curl -s ${SOLR_URL}/api/cluster/autoscaling | jq ."
echo "----------------------------------------------------------------"
