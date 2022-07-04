# ---------------------------------------------------------------------
# Launch Grafana Tempo instance
# ---------------------------------------------------------------------
#
locals {
  tempo_architecture = length(regexall("g\\.", var.tempo.instance_type)) > 0 ? "arm64" : "x86_64"
}

# Search the most recent amazon linux ami
data "aws_ami" "tempo" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
  filter {
    name   = "architecture"
    values = [local.tempo_architecture]
  }
  owners = ["amazon"]
}

data "cloudinit_config" "tempo" {
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
    content = templatefile("../../src/main/cloud-config/tempo.yaml", {
      tempo_version       = var.tempo.version
      prometheus_hostname = module.prometheus.private_dns
    })
  }
}

module "tempo" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 4.0"

  name = "tempo"

  ami           = data.aws_ami.tempo.id
  instance_type = var.tempo.instance_type
  monitoring    = false
  vpc_security_group_ids = [
    data.terraform_remote_state.vpc.outputs.vpc.default_security_group_id
  ]
  subnet_id                   = data.terraform_remote_state.vpc.outputs.vpc.private_subnets[0]
  user_data                   = data.cloudinit_config.tempo.rendered
  user_data_replace_on_change = true
  associate_public_ip_address = false
  iam_instance_profile        = data.terraform_remote_state.vpc.outputs.default_aws_iam_instance_profile_name

  tags = {
    Terraform   = "true"
    Environment = "solr-observability"
  }
}
