variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {}

variable "zookeeper" {
  type = object({
    instance_type = string
    version       = string
    count         = number
  })
  default = {
    instance_type = "t4g.micro"
    version       = "3.6"
    count         = 3
  }
}

variable "solr" {
  type = object({
    instance_type = string
    version       = string
    count         = number
  })
  default = {
    instance_type = "t4g.medium"
    version       = "8.11.2-slim"
    count         = 2
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
