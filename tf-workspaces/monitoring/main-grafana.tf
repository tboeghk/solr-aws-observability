# ---------------------------------------------------------------------
# Launch Prometheus instance
# ---------------------------------------------------------------------
#
locals {
  grafana_architecture = length(regexall("g\\.", var.grafana.instance_type)) > 0 ? "arm64" : "x86_64"
}

resource "aws_security_group" "grafana" {
  name        = "public-grafana"
  description = "Security group for Grafana nodes"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Search the most recent amazon linux ami
data "aws_ami" "grafana" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
  filter {
    name   = "architecture"
    values = [local.grafana_architecture]
  }
  owners = ["amazon"]
}

data "cloudinit_config" "grafana" {
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
    content = templatefile("../../src/main/cloud-config/grafana.yaml", {
      grafana_version     = var.grafana.version
      prometheus_hostname = module.prometheus.private_dns
      tempo_hostname      = module.tempo.private_dns
      loki_hostname       = module.loki.private_dns
    })
  }
}

module "grafana" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 4.0"

  name = "grafana"

  ami           = data.aws_ami.prometheus.id
  instance_type = var.grafana.instance_type
  monitoring    = false
  vpc_security_group_ids = [
    aws_security_group.grafana.id,
    data.terraform_remote_state.vpc.outputs.vpc.default_security_group_id
  ]
  subnet_id                   = data.terraform_remote_state.vpc.outputs.vpc.public_subnets[0]
  user_data                   = data.cloudinit_config.grafana.rendered
  user_data_replace_on_change = true
  associate_public_ip_address = true
  iam_instance_profile        = data.terraform_remote_state.vpc.outputs.default_aws_iam_instance_profile_name

  tags = {
    Terraform   = "true"
    Environment = "solr-observability"
  }
}
