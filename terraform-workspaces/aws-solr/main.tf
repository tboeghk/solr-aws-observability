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
  assume_role_policy = file("iam-policies/node-assume-role.js")
}
resource "aws_iam_policy" "node-permissions" {
  name   = "node-permissions"
  policy = file("iam-policies/node-permissions.js")
}
resource "aws_iam_role_policy_attachment" "node-assume-role" {
  policy_arn = aws_iam_policy.node-permissions.arn
  role       = aws_iam_role.node.name
}
resource "aws_iam_instance_profile" "node" {
  name = "node"
  role = aws_iam_role.node.name
}
