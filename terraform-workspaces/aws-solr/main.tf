# ---------------------------------------------------------------------
# Load AWS infrastructure metadata
# ---------------------------------------------------------------------
#
data "terraform_remote_state" "vpc" {
  backend = "local"
  config = {
    path = "../aws-vpc/terraform.tfstate"
  }
}

# ---------------------------------------------------------------------
# Configure EC2 instances
# ---------------------------------------------------------------------
#
# Search the most recent amazon linux ami
data "aws_ami" "amazon_linux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  owners = ["amazon"]
}

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
