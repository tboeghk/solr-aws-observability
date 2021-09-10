terraform {

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.58"
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
