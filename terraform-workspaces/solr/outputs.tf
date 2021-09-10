output "solr_instance_ids" {
    value = data.aws_instances.solr.ids
}

output "solr_urls" {
    value = formatlist("http://%s:8983", data.aws_instances.solr.public_ips)
}
