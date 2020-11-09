# ---------------------------------------------------------------------
# Launch Solr instances
# ---------------------------------------------------------------------
#
resource "aws_security_group" "solr" {
  name        = "solr"
  description = "Security group for Solr nodes in the cluster"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

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
    cidr_blocks = [ "${var.external_ip}/32" ]
  }
}

data "template_cloudinit_config" "solr" {
  gzip = false
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = file("cloud-config/default.yaml")
  }
  part {
    content_type = "text/cloud-config"
    content      = file("cloud-config/solr.yaml")
  }
}

resource "aws_launch_template" "solr" {
  name_prefix            = "solr"
  instance_type          = "t3.large"
  image_id               = data.aws_ami.amazon_linux.id
  user_data              = data.template_cloudinit_config.solr.rendered
  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups             = [ 
          data.terraform_remote_state.vpc.outputs.default_security_group_id, 
          aws_security_group.solr.id 
    ]
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
  vpc_zone_identifier  = [ data.terraform_remote_state.vpc.outputs.subnet_public_id ]

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

#output "instances" {
#  value = data.aws_instance.this
#}