# ---------------------------------------------------------------------
# Load AWS solr metadata
# ---------------------------------------------------------------------
#
data "terraform_remote_state" "solr" {
  backend = "local"
  config = {
    path = "../aws-solr/terraform.tfstate"
  }
}

data "aws_instance" "solr" {
  count = length(data.terraform_remote_state.solr.outputs.solr_instance_ids)
  instance_id = data.terraform_remote_state.solr.outputs.solr_instance_ids[count.index]
}

output "solr_instance_urls" {
    value = formatlist("http://%s:8983", data.aws_instance.solr.*.public_dns)
}
