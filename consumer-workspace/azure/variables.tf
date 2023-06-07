variable "azure_backend" {}
variable "azure_role" {}
variable "ssh_public_key" {}
variable "tenant_id" {}
variable "subscription_id" {}

variable "resource_tags" {
  type    = map(string)
  default = {}
}

variable "admin_username" {
  type = string
}

variable "location" {
  type = string
}

variable "vm_os_simple" {
  type = string
}

