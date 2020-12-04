#!/bin/bash
set -xe

# retrieve first Solr node
SOLR_URL=$(terraform output -state=terraform-workspaces/aws-solr-instances/terraform.tfstate -json | jq -r '.solr_instance_urls.value[0]')
SOLR_INSTANCE_COUNT=$(terraform output -state=terraform-workspaces/aws-solr-instances/terraform.tfstate -json | jq -r '.solr_instance_urls.value|length')

# create blobstore collection
curl "${SOLR_URL}/solr/admin/collections?action=CREATE&name=.system&replicationFactor=${SOLR_INSTANCE_COUNT}"

# create films collection
curl "${SOLR_URL}/solr/admin/collections?action=CREATE&name=films&numShards=${SOLR_INSTANCE_COUNT}&replicationFactor=1&maxShardsPerNode=1"

# add schema fields
curl -X POST -H 'Content-type:application/json' --data-binary '{"add-field": {"name":"name", "type":"text_general", "multiValued":false, "stored":true}}' "${SOLR_URL}/solr/films/schema"
curl -X POST -H 'Content-type:application/json' --data-binary '{"add-copy-field" : {"source":"*","dest":"_text_"}}' "${SOLR_URL}/solr/films/schema"

# index data
docker run -it solr:8.7 bash bin/post -url "${SOLR_URL}/solr/films/update" example/films/films.json