# Steps

```sh
# Start Vault server
$ vault server -dev -dev-root-token-id=root

# Export env vars
export VAULT_ADDR=http://127.0.0.1:8200 # Address of Vault server
export VAULT_TOKEN=root # Vault token


export OKTA_CLIENT_ID=0oa9oo9ifxE7Melhx5d7
export OKTA_CLIENT_SECRET=niW2_pxajoX_VrQnekoVwjBu03t12PIuA4P4wbqf
export OKTA_DOMAIN=dev-63201584.okta.com

# Create developer policy file
tee vault-policy-developer-read.json <<EOF
{
"policy": "path \"/secret/*\" {\n\tcapabilities = [\"read\", \"list\"]\n}\n"
}
EOF

# Create developer policy in Vault
curl --header "X-Vault-Token: $VAULT_TOKEN" \
      --request PUT \
      --data @vault-policy-developer-read.json \
      $VAULT_ADDR/v1/sys/policies/acl/vault-policy-developer-read

# List Vault policies configured
curl --header "X-Vault-Token: $VAULT_TOKEN" \
      $VAULT_ADDR/v1/sys/policy | jq '.data | .policies'

# Enable the oidc auth method at the path auth/oidc
curl --header "X-Vault-Token: $VAULT_TOKEN" \
      --request POST \
      --data '{"type": "oidc"}' \
      $VAULT_ADDR/v1/sys/auth/oidc

# Create a role file
tee vault-role-okta-default.json <<EOF
{
      "bound_audiences": "$OKTA_CLIENT_ID",
      "allowed_redirect_uris": [
         "$VAULT_ADDR/ui/vault/auth/oidc/oidc/callback",
         "http://localhost:8250/oidc/callback"
      ],
      "user_claim": "sub",
      "token_policies": ["default"]
}
EOF

# Create the role in Vault
curl --header "X-Vault-Token: $VAULT_TOKEN" \
      --request POST \
      --data @vault-role-okta-default.json \
      $VAULT_ADDR/v1/auth/oidc/role/vault-role-okta-default

# Create oidc config file
tee oidc_config.json <<EOF
{
   "oidc_discovery_url": "https://$OKTA_DOMAIN",
   "oidc_client_id": "$OKTA_CLIENT_ID",
   "oidc_client_secret": "$OKTA_CLIENT_SECRET",
   "default_role": "vault-role-okta-default"
}
EOF

# Configure oidc in Vault using the file above
curl --header "X-Vault-Token: $VAULT_TOKEN" \
      --request POST \
      --data @oidc_config.json \
      $VAULT_ADDR/v1/auth/oidc/config



```
