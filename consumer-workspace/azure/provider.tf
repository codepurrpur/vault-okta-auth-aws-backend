terraform {
  required_version = ">= 1.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.11, < 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.0.0"
    }
  }
}

provider "vault" {
}

data "vault_azure_access_credentials" "creds" {
  role    = var.azure_role
  backend = var.azure_backend

  # validate_creds              = true
  # num_sequential_successes    = 8
  # num_seconds_between_tests   = 1
  # max_cred_validation_seconds = 300
}

provider "azurerm" {
  features {}
  client_id       = data.vault_azure_access_credentials.creds.client_id
  client_secret   = data.vault_azure_access_credentials.creds.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}
