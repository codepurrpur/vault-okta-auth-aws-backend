resource "vault_azure_secret_backend" "azure" {
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  path            = var.vault_azure_path_name
}

# locals {
#   azure_roles = [
#     for rg in var.azure_rg : {
#       role_name = "Contributor"
#       scope     = "/subscriptions/${var.subscription_id}/resourceGroups/${rg}"
#     }
#   ]
# }


resource "vault_azure_secret_backend_role" "producer" {
  backend = vault_azure_secret_backend.azure.path
  role    = "${var.vault_azure_path_name}-role"
  ttl     = 300
  max_ttl = 600

  azure_roles {
    role_name = "Contributor"
    scope     = "/subscriptions/${var.subscription_id}"
  }

  # dynamic "azure_roles" {
  #   for_each = local.azure_roles
  #   content {
  #     role_name = azure_roles.value.role_name
  #     scope     = azure_roles.value.scope
  #   }
  # }
}

output "azure_backend" {
  value = vault_azure_secret_backend.azure.path
}

output "azure_role" {
  value = vault_azure_secret_backend_role.producer.role
}
