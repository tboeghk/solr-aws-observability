# ---------------------------------------------------------------------
# Launch Prometheus instance
# ---------------------------------------------------------------------
#
locals {
  prometheus_architecture = length(regexall("g\\.", var.prometheus.instance_type)) > 0 ? "arm64" : "x86_64"
}

resource "aws_security_group" "prometheus" {
  name        = "public-prometheus"
  description = "Security group for Prometheus nodes"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9091
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Search the most recent amazon linux ami
data "aws_ami" "prometheus" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
  filter {
    name   = "architecture"
    values = [local.prometheus_architecture]
  }
  owners = ["amazon"]
}

data "cloudinit_config" "prometheus" {
  gzip          = false
  base64_encode = false

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
    content      = file("../../src/main/cloud-config/prometheus-alerting-rules.yaml")
  }
  part {
    content_type = "text/cloud-config"
    content = templatefile("../../src/main/cloud-config/prometheus.yaml", {
      prometheus_version = var.prometheus.version
      aws_region         = var.aws_region
    })
  }
}

module "prometheus" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 4.0"

  name = "prometheus"

  ami           = data.aws_ami.prometheus.id
  instance_type = var.prometheus.instance_type
  monitoring    = false
  vpc_security_group_ids = [
    aws_security_group.prometheus.id,
    data.terraform_remote_state.vpc.outputs.vpc.default_security_group_id
  ]
  subnet_id                   = data.terraform_remote_state.vpc.outputs.vpc.public_subnets[0]
  user_data                   = data.cloudinit_config.prometheus.rendered
  associate_public_ip_address = true
  iam_instance_profile        = data.terraform_remote_state.vpc.outputs.default_aws_iam_instance_profile_name

  tags = {
    Terraform   = "true"
    Environment = "solr-observability"
  }
}
