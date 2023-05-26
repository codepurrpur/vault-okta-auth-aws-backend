resource "random_id" "id" {
  byte_length = 4
  prefix      = "cz-"
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

locals {
  vpc_cidr = "10.1.0.0/16"
  my_ip    = chomp(data.http.myip.response_body)
}

data "aws_availability_zones" "this" {
  state = "available"
  filter {
    name   = "region-name"
    values = [var.region]
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = random_id.id.dec
  cidr = local.vpc_cidr
  azs = [data.aws_availability_zones.this.names[0],
    data.aws_availability_zones.this.names[1],
  data.aws_availability_zones.this.names[2]]
  public_subnets       = [cidrsubnet(local.vpc_cidr, 8, 1), cidrsubnet(local.vpc_cidr, 8, 2), cidrsubnet(local.vpc_cidr, 8, 3)]
  enable_nat_gateway   = false
  enable_dns_hostnames = true
  tags                 = var.resource_tags
}

resource "aws_security_group" "ubuntu" {
  name   = "${random_id.id.dec}-ubuntu"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${local.my_ip}/32"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${local.my_ip}/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_key_pair" "ssh_access" {
  public_key = var.ssh_public_key
}

resource "aws_instance" "ubuntu" {
  count                       = 1
  ami                         = var.ubuntu_ami
  instance_type               = var.ubuntu_size
  key_name                    = aws_key_pair.ssh_access.key_name
  subnet_id                   = module.vpc.public_subnets[count.index]
  vpc_security_group_ids      = [aws_security_group.ubuntu.id]
  associate_public_ip_address = true
}
