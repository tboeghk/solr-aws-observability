# 🧪 Solr AWS observability & autoscaling experiments

This repo holds a playground for Solr Cloud observability & autoscaling
experiments with AWS and Terraform. It's idea is to quickly spin up a
Zookeeper/Solr ensemble and evaluate SolrCloud autoscaling triggers in conjunction with AWS autoscaling group events.

The Solr Autoscaling Framework is very complicated and seems pretty
overengineered. That's why I use this playground to test Solr
Autoscaling policies.

> 🚨 The autoscaling framework in its current form is deprecated
>    and will be removed in Solr 9.0.

## Project goal

Use this project as a blueprint to:

* scale Solr autoscaling groups at speed (~90s up and running)
* utilize Cloud-Init and SystemD to properly launch and terminate
  Solr instances.
* See _Prometheus metrics and alarms_ in action
* See _Jaeger distributed tracing_ in action
* Experiment with _Solr autoscaling_ settings

## Dependencies

Before you start, [provide your AWS access and secret key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#environment-variables)
to Terraform either static in a `secrets.auto.tfvars` file or in environment
variables.

```bash
cat << EOF > secrets.auto.tfvars
aws_access_key = "YOUR_AWS_ACCESS_KEY"
aws_secret_key = "YOUR_AWS_SECRET_KEY"
aws_region     = "eu-west-1"
EOF
```

## Up and running

> 💰 You are about to create resources in AWS that actually
> cost money. Just be aware of that when scaling your cluster
> beyond infinity ...


```bash
# create VPC and basic security groups
cd tf-workspaces/vpc && tf init && tf apply

# create monitoring instances
cd ../monitoring && tf init && tf apply

# create Zookeeper and Solr cluster
cd ../solr && tf init && tf apply

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
