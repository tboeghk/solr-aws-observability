#!/bin/bash

root_directory=$(dirname "$0")

# Unset all authentication tokens that reside in our
# environment to not spoil our scripts.
unset DO_AUTH_TOKEN
unset DIGITALOCEAN_TOKEN
unset HCLOUD_TOKEN
unset KUBECONFIG
unset AWS_ACCESS_KEY_ID
unset AWS_CA_BUNDLE
unset AWS_PROFILE
unset AWS_SECRET_ACCESS_KEY

# Use this AWS profile
export AWS_PROFILE=default

echo "-----------------------------------------------------------------"
echo " Configuring Terminal secrets for ${AWS_PROFILE} ..."
echo "-----------------------------------------------------------------"
aws configure list
echo "-----------------------------------------------------------------"
echo " You are working as ... $(aws sts get-caller-identity)"
echo "-----------------------------------------------------------------"
