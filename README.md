# Intro

<https://codepurrpurr.io/identity/vault-okta-dynamic-secrets/>

## Steps

```sh
# Start Vault server
$ vault server -dev -dev-root-token-id=root

# Export env vars
export TF_VAR_aws_access_key=${AWS_ACCESS_KEY_ID} # AWS Access Key ID - This command assumes the AWS Access Key ID is set in your environment as AWS_ACCESS_KEY_ID
export TF_VAR_aws_secret_key=${AWS_SECRET_ACCESS_KEY} # AWS Secret Access Key - This command assumes the AWS Access Key ID is set in your environment as AWS_SECRET_ACCESS_KEY
export VAULT_ADDR=http://127.0.0.1:8200 # Address of Vault server
export VAULT_TOKEN=root # Vault token

# Check path and verb to tune Vault policy
vault audit disable file file_path=/Users/chichi/Desktop/audit.log
tail -f  audit.log | jq '.request | {path, operation}'

```
