locals {
  organisation_security_account_id = coalesce([
    for account in data.aws_organizations_organization.default.accounts :
    account.id
    if account.name == "organisation-security"
  ]...)

  # AWS Organizational Units
  ou_opg = coalesce([
    for ou in data.aws_organizations_organizational_units.organizational_units.children :
    ou.id
    if ou.name == "OPG"
  ]...)

  ou_opg_use_my_lpa = coalesce([
    for ou in data.aws_organizations_organizational_units.opg.children :
    ou.id
    if ou.name == "Use My LPA"
  ]...)

  ou_platforms_and_architecture_id = coalesce([
    for ou in data.aws_organizations_organizational_units.organizational_units.children :
    ou.id
    if ou.name == "Platforms & Architecture"
  ]...)

  ou_modernisation_platform_id = coalesce([
    for ou in data.aws_organizations_organizational_units.platforms_and_architecture.children :
    ou.id
    if ou.name == "Modernisation Platform"
  ]...)

  ou_modernisation_platform_core_id = coalesce([
    for ou in data.aws_organizations_organizational_units.modernisation_platform.children :
    ou.id
    if ou.name == "Modernisation Platform Core"
  ]...)

  ou_modernisation_platform_member_id = coalesce([
    for ou in data.aws_organizations_organizational_units.modernisation_platform.children :
    ou.id
    if ou.name == "Modernisation Platform Member"
  ]...)

  ou_modernisation_platform_unrestricted_id = coalesce([
    for ou in data.aws_organizations_organizational_units.modernisation_platform.children :
    ou.id
    if ou.name == "Modernisation Platform Member Unrestricted"
  ]...)

  # Shield Advanced
  shield_advanced_auto_remediate = {
    accounts = [
      for account_name, account_value in local.accounts.active_only_not_self :
      account_value
      if
      (
        account_name == "Legal Aid Agency" ||
        account_name == "LAA Development" ||
        account_name == "MOJ Official (Development)" ||
        account_name == "MOJ Official (Pre-Production)"
      )
    ],
    organizational_units = flatten([
      local.ou_opg_use_my_lpa,
      data.aws_organizations_organizational_units.modernisation_platform_core.id,
      [
        for ou in data.aws_organizations_organizational_units.modernisation_platform_member.children :
        ou.id
        if(
          ou.name != "modernisation-platform-xhibit-portal"
        )
      ]
    ])
  }
  shield_advanced_no_auto_remediate = {
    accounts = [
      for account_name, account_value in local.accounts.active_only_not_self :
      account_value
      if
      (
        account_name == "shared-services-dev" ||
        account_name == "MoJ Digital Services" ||
        account_name == "MOJ LPA Development" ||
        account_name ==  "MOJ LPA Preproduction"
      )
    ],
    organizational_units = null
  }

  # Accounts map
  accounts = {
    active_only_not_self : {
      for account in data.aws_organizations_organization.default.accounts :
      account.name => account.id
      if account.status == "ACTIVE" && account.name != "organisation-security"
    }
  }
}
