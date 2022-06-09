# ---------------------------------------------------------------------
# Set up VPC, networking and security groups
# ---------------------------------------------------------------------
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  vpc_cidr = "10.89.83.0/24"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 3.14.0"

  name = "solr-observability"
  cidr = local.vpc_cidr

  azs             = [data.aws_availability_zones.available.names[0]]
  private_subnets = [cidrsubnet(local.vpc_cidr, 1, 1)]
  public_subnets  = [cidrsubnet(local.vpc_cidr, 1, 0)]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  enable_dns_hostnames = true

  tags = {
    Terraform = "true"
    Environment = "solr-observability"
  }
}
