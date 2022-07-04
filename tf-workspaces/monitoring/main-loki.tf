# ---------------------------------------------------------------------
# Launch Grafana Tempo instance
# ---------------------------------------------------------------------
#
locals {
  loki_architecture = length(regexall("g\\.", var.loki.instance_type)) > 0 ? "arm64" : "x86_64"
}

# Search the most recent amazon linux ami
data "aws_ami" "loki" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
  filter {
    name   = "architecture"
    values = [local.loki_architecture]
  }
  owners = ["amazon"]
}

data "cloudinit_config" "loki" {
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
    content = templatefile("../../src/main/cloud-config/loki.yaml", {
      loki_version        = var.loki.version
      prometheus_hostname = module.prometheus.private_dns
    })
  }
}

module "loki" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 4.0"

  name = "loki"

  ami           = data.aws_ami.loki.id
  instance_type = var.loki.instance_type
  monitoring    = false
  vpc_security_group_ids = [
    data.terraform_remote_state.vpc.outputs.vpc.default_security_group_id
  ]
  subnet_id                   = data.terraform_remote_state.vpc.outputs.vpc.private_subnets[0]
  user_data                   = data.cloudinit_config.loki.rendered
  user_data_replace_on_change = true
  associate_public_ip_address = false
  iam_instance_profile        = data.terraform_remote_state.vpc.outputs.default_aws_iam_instance_profile_name

  tags = {
    Terraform   = "true"
    Environment = "solr-observability"
  }
}
