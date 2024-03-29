# ---------------------------------------------------------------------
# Load AWS solr metadata
# ---------------------------------------------------------------------
#

# query asg members
data "aws_instances" "solr" {
  instance_tags = {
    Name = "solr"
  }

  instance_state_names = ["running"]
}

data "aws_instances" "prometheus" {
  instance_tags = {
    Name = "prometheus"
  }

  instance_state_names = ["running"]
}

data "aws_instances" "grafana" {
  instance_tags = {
    Name = "grafana"
  }

  instance_state_names = ["running"]
}

output "solr_instance_urls" {
  value = formatlist("http://%s:8983", data.aws_instances.solr.public_ips.*)

}

output "prometheus_instance_url" {
  value = formatlist("http://%s:9090", data.aws_instances.prometheus.public_ips.*)
}

output "grafana_instance_url" {
  value = formatlist("http://%s:3000", data.aws_instances.grafana.public_ips.*)
}
