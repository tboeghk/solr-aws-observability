#!/bin/bash
set -e

# retrieve first Solr node
SOLR_URL=$(terraform output -state=terraform-workspaces/aws-solr-instances/terraform.tfstate -json | jq -r '.solr_instance_urls.value[0]')

# create films collection
curl "${SOLR_URL}/solr/admin/collections?action=DELETE&name=films"
