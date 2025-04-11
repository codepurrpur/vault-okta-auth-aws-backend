resource "vault_aws_secret_backend" "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  path       = var.vault_aws_path_name

  default_lease_ttl_seconds = "3600"
  max_lease_ttl_seconds     = "3600"
}

resource "vault_aws_secret_backend_role" "producer" {
  backend         = vault_aws_secret_backend.aws.path
  name            = "${var.vault_aws_path_name}-role"
  credential_type = "iam_user"

  policy_document = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
EOF
}

output "aws_backend" {
  value = vault_aws_secret_backend.aws.path
}

output "aws_role" {
  value = vault_aws_secret_backend_role.producer.name
}
