terraform {
  # synchronize cluster state across trainers
  backend "remote" {
    organization = "tboeghk"
    workspaces {
      name = "solr-autoscaling-infrastructure"
    }

    # credentials for terraform.io are read from .terraformrc
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 2.70"
    }
    template = {
      source = "hashicorp/template"
      version = "~> 2.2"
    }
    local = {
      source = "hashicorp/local"
      version = "~> 2.0"
    }
  }
  required_version = ">= 0.13"
}

provider "aws" {
  region  = "eu-west-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "external_ip" {
  type = string
}
