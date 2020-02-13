provider "aws" {
  version = "~> 2.48"
  region  = "eu-west-1"
}

provider "http" {
  version = "~> 1.1"
}

# ---------------------------------------------------------------------
# Set up VPC, networking and security groups
# ---------------------------------------------------------------------
#
# query available availability zones in the configured region
data "aws_availability_zones" "available" {
    state = "available"
}

# create a new vpc to put our zookeeper and solr instances in
resource "aws_vpc" "this" {
  cidr_block = "172.16.0.0/24"
  enable_dns_hostnames = true
}

# create a subnet in the first available availability zone.
# For the sake of simplicity, we create a single subnet that
# requires hosts to have a public ipv4
resource "aws_subnet" "public" {
  count             = 1
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = aws_vpc.this.cidr_block
  vpc_id            = aws_vpc.this.id
}

# create a internet gateway for the vpc
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

# create a route table inside the vpc to route all
# traffic (expect own subnet) through the internet gateway
resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

# enable routing in subnets via the internet gateway
resource "aws_route_table_association" "this" {
  count          = 1
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.this.id
}

# query my workstations public ip
data "http" "canihazip" {
  url = "https://canihazip.com/s"
}

# add ssh ingress by default
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol    = "tcp"
    cidr_blocks = [ "${data.http.canihazip.body}/32" ]
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

# ---------------------------------------------------------------------
# Launch Zookeeper instances
# ---------------------------------------------------------------------
#
# configure the template to launch zookeeper instances
resource "aws_launch_template" "zookeeper" {
  name_prefix            = "zookeeper"
  instance_type          = "t3.nano"
  image_id               = data.aws_ami.amazon_linux.id
  user_data              = base64encode(file("cloud-config/zookeeper.yaml"))
  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
  }
  iam_instance_profile {
    name                 = aws_iam_instance_profile.node.name
  }
  lifecycle {
    create_before_destroy = "true"
  }
}

resource "aws_autoscaling_group" "zookeeper" {
  desired_capacity     = 3
  max_size             = 5
  min_size             = 1
  name                 = "zookeeper"
  vpc_zone_identifier  = aws_subnet.public.*.id

  launch_template {
    id      = aws_launch_template.zookeeper.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "zookeeper"
    propagate_at_launch = true
  }
}

# ---------------------------------------------------------------------
# Launch Solr instances
# ---------------------------------------------------------------------
#
resource "aws_security_group" "solr" {
  name        = "solr"
  description = "Security group for Solr nodes in the cluster"
  vpc_id      = aws_vpc.this.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8983
    to_port   = 8983
    protocol    = "tcp"
    cidr_blocks = [ "${data.http.canihazip.body}/32" ]
  }
}

resource "aws_launch_template" "solr" {
  name_prefix            = "solr"
  instance_type          = "t3.large"
  image_id               = data.aws_ami.amazon_linux.id
  user_data              = base64encode(file("cloud-config/solr.yaml"))
  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups             = [ aws_default_security_group.this.id, aws_security_group.solr.id ]
  }
  iam_instance_profile {
    name                 = aws_iam_instance_profile.node.name
  }
  lifecycle {
    create_before_destroy = "true"
  }
}

resource "aws_autoscaling_group" "solr" {
  desired_capacity     = 3
  max_size             = 5
  min_size             = 1
  name                 = "solr"
  vpc_zone_identifier  = aws_subnet.public.*.id

  launch_template {
    id      = aws_launch_template.solr.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "solr"
    propagate_at_launch = true
  }
}

#data "aws_instance" "this" {
#  filter {
#    name   = "tag:Name"
#    values = ["zookeeper", "solr"]
#  }
#}

#output "instances" {
#  value = data.aws_instance.this
#}