variable "aws_backend" {}
variable "aws_role" {}

variable "region" {
  description = "Region to deploy AWS resources in"
  type        = string
}

variable "instance_size" {
  description = "Instance size for server instances"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key to be loaded onto all EC2 instances for SSH access"
  type        = string
}

variable "default_tags" {
  type    = map(string)
  default = {}
}

