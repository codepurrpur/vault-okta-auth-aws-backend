data "vault_policy_document" "dev_policy_content" {
  rule {
    path         = "dynamic-aws-creds-producer/*"
    capabilities = ["create", "read", "update", "delete", "list"]
    description  = ""
  }
}

resource "vault_policy" "developer" {
  name   = "developer"
  policy = data.vault_policy_document.dev_policy_content.hcl
}
