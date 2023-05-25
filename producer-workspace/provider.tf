terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 2.24"
    }
    okta = {
      source  = "okta/okta"
      version = "~> 3.15"
    }
  }
}

provider "okta" {
  org_name  = var.okta_org_name
  base_url  = var.okta_base_url
  api_token = var.okta_api_token
}

provider "vault" {}
