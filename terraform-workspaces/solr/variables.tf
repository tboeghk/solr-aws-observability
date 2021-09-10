terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.58"
    }
    template = {
      source = "hashicorp/template"
      version = "~> 2.2"
    }
    local = {
      source = "hashicorp/local"
      version = "~> 2.1"
    }
  }
  required_version = ">= 1.0.0"
}

provider "aws" {
  region  = "eu-west-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "solr_instance_count" {
  type = number
  default = 3
}
