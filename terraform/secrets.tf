# Email addresses for AWS accounts
# There is a manually added "template" key for templating email addresses for new accounts configured in this account,
# so you can do:
# `email = replace(local.aws_account_email_addresses_template, "{email}", "account-name")`
# Accounts that were configured before this can use:
# `email = local.aws_account_email_addresses["account-name"][0]`
resource "aws_secretsmanager_secret" "aws_account_email_addresses" {
  name        = "aws_account_email_addresses"
  description = "Email addresses for AWS accounts in AWS Organizations"
  tags        = local.root_account
}

# We can get all account emails to update the secret, regardless of if they're in Terraform or clickopsed;
# and keep the list up to date with (new) templated email addresses.
data "aws_organizations_organization" "root" {}

locals {
  configured_aws_account_email_addresses = {
    for account in data.aws_organizations_organization.root.accounts :
    account.name => account.email...
  }
}

resource "aws_secretsmanager_secret_version" "aws_account_email_addresses" {
  secret_id = aws_secretsmanager_secret.aws_account_email_addresses.id
  secret_string = jsonencode(
    merge(
      local.configured_aws_account_email_addresses,
      local.aws_account_email_addresses
    )
  )
}

data "aws_secretsmanager_secret_version" "aws_account_email_addresses" {
  secret_id = aws_secretsmanager_secret.aws_account_email_addresses.id
}

locals {
  aws_account_email_addresses          = jsondecode(data.aws_secretsmanager_secret_version.aws_account_email_addresses.secret_string)
  aws_account_email_addresses_template = local.aws_account_email_addresses["template"]
}
