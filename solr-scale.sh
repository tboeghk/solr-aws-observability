#!/bin/bash

NODE_COUNT=$1

echo "Scaling Solr autoscaling group to ${NODE_COUNT} instances ..."
cd terraform-workspaces/aws-solr
terraform apply -var "solr_instance_count=${NODE_COUNT}" -auto-approve
cd ../aws-solr-instances

echo "Updating Solr autoscaling group members ..."
terraform apply -auto-approve