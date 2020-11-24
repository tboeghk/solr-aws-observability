#!/bin/bash
set -e

# retrieve first Solr node
SOLR_URL=$(terraform output -state=terraform-workspaces/aws-solr-instances/terraform.tfstate -json | jq -r '.solr_instance_urls.value[0]')

# create films collection
curl "${SOLR_URL}/solr/admin/collections?action=CREATE&name=films&numShards=2&replicationFactor=1&maxShardsPerNode=2"

# add schema fields
curl -X POST -H 'Content-type:application/json' --data-binary '{"add-field": {"name":"name", "type":"text_general", "multiValued":false, "stored":true}}' "${SOLR_URL}/solr/films/schema"
curl -X POST -H 'Content-type:application/json' --data-binary '{"add-copy-field" : {"source":"*","dest":"_text_"}}' "${SOLR_URL}/solr/films/schema"

# index data
docker run -it solr:8.7 bash bin/post -url "${SOLR_URL}/solr/films/update" example/films/films.json