variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {}

variable "prometheus" {
  type = object({
    instance_type = string
    version       = string
  })
  default = {
    instance_type = "t4g.small"
    version       = "v2.36.2"
  }
}
variable "grafana" {
  type = object({
    instance_type = string
    version       = string
  })
  default = {
    instance_type = "t4g.small"
    version       = "8.5.6"
  }
}

variable "loki" {
  type = object({
    instance_type = string
    version       = string
  })
  default = {
    instance_type = "t4g.small"
    version       = "2.5.0"
  }
}

variable "tempo" {
  type = object({
    instance_type = string
    version       = string
  })
  default = {
    instance_type = "t4g.small"
    version       = "1.4.1"
  }
}

# ---------------------------------------------------------------------
# Load AWS infrastructure metadata
# ---------------------------------------------------------------------
#
data "terraform_remote_state" "vpc" {
  backend = "local"
  config = {
    path = "../vpc/terraform.tfstate"
  }
}
