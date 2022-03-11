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
    version       = "v2.33.5"
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
