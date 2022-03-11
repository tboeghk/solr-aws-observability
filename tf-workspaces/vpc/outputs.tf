output "vpc" {
    value = module.vpc
}

output "default_aws_iam_instance_profile_name" {
    value = aws_iam_instance_profile.node.name
}
