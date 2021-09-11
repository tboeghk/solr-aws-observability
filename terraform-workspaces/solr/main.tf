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

# ---------------------------------------------------------------------
# Configure EC2 instances
# ---------------------------------------------------------------------
#
# Create a bunch of IAM roles to allow the created nodes to retrieve
# data from the AWS API via AWS CLI.
resource "aws_iam_role" "node" {
  name = "node"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"]
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
    Creator     = "Terraform"
  }
}

resource "aws_iam_instance_profile" "node" {
  name = "node"
  role = aws_iam_role.node.name
}

data "aws_security_group" "default" {
  name = "default"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
}
