
# ---------------------------------------------------------------------
# Launch Zookeeper instances
# ---------------------------------------------------------------------
#
# Distinguish between arm64 and amd64 instances
locals {
  zookeeper_architecture = length(regexall("g\\.", var.zookeeper.instance_type)) > 0 ? "arm64" : "x86_64"
}

# Search the most recent amazon linux ami
data "aws_ami" "zookeeper" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
  filter {
    name   = "architecture"
    values = [local.zookeeper_architecture]
  }
  owners = ["amazon"]
}

# render user-data
data "cloudinit_config" "zookeeper" {
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
    content      = file("../../src/main/cloud-config/zookeeper.yaml")
  }
}

# configure the template to launch zookeeper instances
resource "aws_launch_template" "zookeeper" {
  name_prefix   = "zookeeper-"
  instance_type = var.zookeeper.instance_type
  image_id      = data.aws_ami.zookeeper.id
  user_data     = data.cloudinit_config.zookeeper.rendered
  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
  }
  iam_instance_profile {
    name = data.terraform_remote_state.vpc.outputs.default_aws_iam_instance_profile_name
  }
  lifecycle {
    create_before_destroy = "true"
  }
}

resource "aws_autoscaling_group" "zookeeper" {
  desired_capacity    = 3
  max_size            = 5
  min_size            = 1
  name                = "zookeeper"
  vpc_zone_identifier = [data.terraform_remote_state.vpc.outputs.vpc.private_subnets[0]]

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
