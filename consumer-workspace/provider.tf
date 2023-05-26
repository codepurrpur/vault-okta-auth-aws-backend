data "vault_aws_access_credentials" "creds" {
  backend = var.aws_backend
  role    = var.aws_role
}

provider "aws" {
  access_key = data.vault_aws_access_credentials.creds.access_key
  secret_key = data.vault_aws_access_credentials.creds.secret_key
  region     = var.region
}

provider "vault" {
}
