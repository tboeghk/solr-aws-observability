#!/bin/bash

# retrieve first Solr node
SOLR_URL=$(terraform output -state=terraform-workspaces/aws-solr-instances/terraform.tfstate -json | jq -r '.solr_instance_urls.value[0]')

curl -s ${SOLR_URL}/solr/admin/autoscaling/history | jq '.response.docs'