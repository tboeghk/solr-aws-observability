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

output "solr_instance_urls" {
  value = formatlist("http://%s:8983", data.aws_instances.solr.public_ips.*)
}
