#!/bin/bash
set -xe

# retrieve first Solr node
SOLR_URL=http://localhost:8983
SOLR_INSTANCE_COUNT=1

# create blobstore collection
curl "${SOLR_URL}/solr/admin/collections?action=CREATE&name=.system&replicationFactor=${SOLR_INSTANCE_COUNT}"

# create films collection
curl "${SOLR_URL}/solr/admin/collections?action=CREATE&name=films&numShards=${SOLR_INSTANCE_COUNT}&replicationFactor=1&maxShardsPerNode=1"

# add schema fields
curl -X POST -H 'Content-type:application/json' --data-binary '{"add-field": {"name":"name", "type":"text_general", "multiValued":false, "stored":true}}' "${SOLR_URL}/solr/films/schema"
curl -X POST -H 'Content-type:application/json' --data-binary '{"add-copy-field" : {"source":"*","dest":"_text_"}}' "${SOLR_URL}/solr/films/schema"

# index data
docker run -it --network host solr:8.11.1-slim bash bin/post -url "${SOLR_URL}/solr/films/update" example/films/films.json
