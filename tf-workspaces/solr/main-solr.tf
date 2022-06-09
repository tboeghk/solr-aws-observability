# ---------------------------------------------------------------------
# Launch Solr instances
# ---------------------------------------------------------------------
#
locals {
  solr_architecture = length(regexall("g\\.", var.solr.instance_type)) > 0 ? "arm64" : "x86_64"
}

# Allow public access to Solr
resource "aws_security_group" "solr" {
  name        = "public-solr"
  description = "Security group for Solr nodes in the cluster"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8983
    to_port     = 8983
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Search the most recent amazon linux ami
data "aws_ami" "solr" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
  filter {
    name   = "architecture"
    values = [local.solr_architecture]
  }
  owners = ["amazon"]
}

data "cloudinit_config" "solr" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = file("../../src/main/cloud-config/default.yaml")
  }
  part {
    content_type = "text/cloud-config"
    content      = file("../../src/main/cloud-config/ssm-agent.yaml")
  }
  part {
    content_type = "text/cloud-config"
    content      = file("../../src/main/cloud-config/node-exporter.yaml")
  }
  part {
    content_type = "text/cloud-config"
    content      = file("../../src/main/cloud-config/jaeger-agent.yaml")
  }
  part {
    content_type = "text/cloud-config"
    content      = templatefile("../../src/main/cloud-config/solr.yaml", {
      solr_version = var.solr.version
    })
  }
}

resource "aws_launch_template" "solr" {
  name_prefix   = "solr-"
  instance_type = var.solr.instance_type
  image_id      = data.aws_ami.solr.id
  user_data     = data.cloudinit_config.solr.rendered
  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups = [
      aws_security_group.solr.id,
      data.terraform_remote_state.vpc.outputs.vpc.default_security_group_id
    ]
  }
  iam_instance_profile {
    name = data.terraform_remote_state.vpc.outputs.default_aws_iam_instance_profile_name
  }
  lifecycle {
    create_before_destroy = "true"
  }
}

resource "aws_autoscaling_group" "solr" {
  desired_capacity    = var.solr.count
  max_size            = 20
  min_size            = 1
  name                = "solr"
  vpc_zone_identifier = [data.terraform_remote_state.vpc.outputs.vpc.public_subnets[0]]

  launch_template {
    id      = aws_launch_template.solr.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "solr"
    propagate_at_launch = true
  }

  depends_on = [
    aws_autoscaling_group.zookeeper
  ]
}
