output "vpc_id" {
    value = aws_vpc.this.id
}

output "subnet_private_id" {
    value = aws_subnet.private.id
}

output "subnet_public_id" {
    value = aws_subnet.public.id
}

output "default_security_group_id" {
    value = aws_default_security_group.this.id
}

output "external_ip" {
    value = data.http.external_ip.body
}