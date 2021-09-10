# ---------------------------------------------------------------------
# Set up VPC, networking and security groups
# ---------------------------------------------------------------------
#
# query available availability zones in the configured region
data "aws_availability_zones" "available" {
    state = "available"
}

# create a new vpc to put our zookeeper and solr instances in
resource "aws_vpc" "this" {
  cidr_block = "172.16.0.0/24"
  enable_dns_hostnames = true
}

# create a subnet in the first available availability zone.
resource "aws_subnet" "public" {
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 1, 0)
  vpc_id            = aws_vpc.this.id
  map_public_ip_on_launch = true
}

# create a internet gateway for the vpc
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

# create a route table inside the vpc to route all
# traffic (expect own subnet) through the internet gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

# enable routing in subnets via the internet gateway
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# create a private subnet for hosts without a public
# ip address
resource "aws_subnet" "private" {
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 1, 1)
  vpc_id            = aws_vpc.this.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

data "aws_ami" "nat" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat*"]
  }
  owners = ["amazon"]
}

resource "aws_instance" "nat" {
  ami                         = data.aws_ami.nat.id
  instance_type               = "t3.nano"
  source_dest_check           = false
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true

  tags = {
    Name = "nat-instance"
  }
}

resource "aws_route" "nat-instance" {
  route_table_id = aws_route_table.private.id
  instance_id    = aws_instance.nat.id
  destination_cidr_block = "0.0.0.0/0"
}
