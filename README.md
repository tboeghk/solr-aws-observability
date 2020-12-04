# Solr AWS autoscaling experiments

This repo holds a playground for Solr Cloud autoscaling experiments
with AWS and Terraform. It's idea is to quickly spin up a Zookeeper/Solr
ensemble and evaluate SolrCloud autoscaling triggers in conjunction
with AWS autoscaling group events.

## Project goal

Use this project as a blueprint to:

* create AWS autoscaling groups in Terraform
* scale Solr autoscaling groups at speed (~90s up and running)
* utilize Cloud-Init and SystemD to properly launch and terminate
  Solr instances.
* *Experiment with Solr autoscaling settings*

> 🚨 The autoscaling framework in its current form is deprecated and will be removed in Solr 9.0.

The Solr Autoscaling Framework is very complicated and seems pretty
overengineered. That's why I use this playground to test Solr 
Autoscaling policies.

## Up and running

> You are about to create resources in AWS that actually
> cost money. Just be aware of that when scaling your cluster
> to infinity ...

Before you start, [provide your AWS access and secret key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#environment-variables)
to Terraform either static in a `secrets.auto.tfvars` file or in environment
variables.

```bash
# create VPC and basic security groups
cd terraform-workspaces/aws-vpc && tf init && tf apply

# create Zookeeper and Solr cluster
cd ../aws-solr && tf init && tf apply

# retreive Solr urls
cd ../aws-solr-instances && tf init && tf apply -auto-approve && cd ../..

# create film sample collection
./solr-create-collection.sh
```

## Experimenting

```bash
./solr-configure-autoscaling.sh
```


## Tear down

```bash
cd terraform-workspaces/aws-solr-instances && tf destroy -auto-approve
cd ../aws-solr && tf destroy -auto-approve
cd ../aws-vpc && tf destroy -auto-approve
```