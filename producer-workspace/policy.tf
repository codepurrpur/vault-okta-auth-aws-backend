data "vault_policy_document" "dev_policy_content" {
  rule {
    path         = "dynamic-aws-creds-producer/creds/dynamic-aws-creds-producer-role"
    capabilities = ["read"]
    description  = ""
  }

  rule {
    path         = "dynamic-azure-creds-producer/creds/dynamic-azure-creds-producer-role"
    capabilities = ["read"]
    description  = ""
  }

  rule {
    path         = "dynamic-azure-creds-producer/config"
    capabilities = ["read"]
    description  = ""
  }

  rule {
    path         = "auth/token/lookup-self"
    capabilities = ["read"]
    description  = ""
  }

  rule {
    path         = "auth/token/create"
    capabilities = ["update"]
    description  = ""
  }

}

resource "vault_policy" "developer" {
  name   = "developer"
  policy = data.vault_policy_document.dev_policy_content.hcl
}
