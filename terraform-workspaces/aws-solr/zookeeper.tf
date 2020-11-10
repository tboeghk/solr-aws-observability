
# ---------------------------------------------------------------------
# Launch Zookeeper instances
# ---------------------------------------------------------------------
#
#
# render user-data
data "template_cloudinit_config" "zookeeper" {
  gzip = false
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = file("../../cloud-config/default.yaml")
  }
  part {
    content_type = "text/cloud-config"
    content      = file("../../cloud-config/zookeeper.yaml")
  }
}

# configure the template to launch zookeeper instances
resource "aws_launch_template" "zookeeper" {
  name_prefix            = "zookeeper"
  instance_type          = "t3.small"
  image_id               = data.aws_ami.amazon_linux.id
  user_data              = data.template_cloudinit_config.zookeeper.rendered
  network_interfaces {
    associate_public_ip_address = false
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
  vpc_zone_identifier  = [ data.terraform_remote_state.vpc.outputs.subnet_private_id ]

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
