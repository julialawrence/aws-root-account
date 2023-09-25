# Legal Aid Agency (sandbox)
resource "aws_organizations_account" "legal_aid_agency" {
  name                       = "Legal Aid Agency"
  email                      = replace(local.aws_account_email_addresses_template, "{email}", "legalaid")
  iam_user_access_to_billing = "ALLOW"
  parent_id                  = aws_organizations_organizational_unit.closed_accounts.id

  tags = local.tags_laa

  lifecycle {
    ignore_changes = [
      email,
      iam_user_access_to_billing,
      name,
      role_name,
    ]
  }
}
