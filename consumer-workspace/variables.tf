variable "aws_backend" {}
variable "aws_role" {}
variable "token" {}

variable "region" {
  description = "Region to deploy AWS resources in"
  type        = string
  default     = ""
}

variable "ubuntu_ami" {
  description = "AMI ID for ubuntu instances"
  type        = string
  default     = ""
}

variable "ubuntu_size" {
  description = "Instance size for ubuntu instances"
  type        = string
  default     = ""
}

variable "ssh_public_key" {
  description = "SSH public key to be loaded onto all EC2 instances for SSH access"
  type        = string
  default     = ""
}

variable "resource_tags" {
  type    = map(string)
  default = {}
}
