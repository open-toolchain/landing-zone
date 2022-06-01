##############################################################################
# Access Group Locals
##############################################################################

module "access_group_object" {
  source = "./config_modules/list_to_map"
  list   = var.access_groups
  prefix = var.prefix
}

module "access_policies" {
  source = "./config_modules/list_to_map"
  list   = local.access_policy_list
}

module "dynamic_rules" {
  source = "./config_modules/list_to_map"
  list   = local.dynamic_rule_list
}

locals {
  access_groups_object = module.access_group_object.value
  access_policies      = module.access_policies.value
  dynamic_rules        = module.dynamic_rules.value
  account_management_map = {
    for group in local.account_management_list :
    (group.group) => group.roles
  }

  # Add all policies to a single list
  access_policy_list = flatten([
    # For each group
    for group in var.access_groups : [
      # Add policy object to array
      for policy in group.policies :
      # Add `group` field to object
      merge(policy, { group : "${var.prefix}-${group.name}" })
      # Unless no policies
    ] if group.policies != null
  ])


  # Add all policies to a single list
  dynamic_rule_list = flatten([
    # For each group
    for group in var.access_groups : [
      # Add policy object to array
      for policy in group.dynamic_policies :
      # Add `group` field to object
      merge(policy, { group : "${var.prefix}-${group.name}" })
      # Unless no policies
    ] if lookup(group, "dynamic_policies", null) != null
  ])

  # All account management policies
  account_management_list = [
    for group in var.access_groups :
    {
      group = "${var.prefix}-${group.name}"
      roles = group.account_management_policies
    } if lookup(group, "account_management_policies", null) != null
  ]

  # Convert to map

  # Map of groups with invites
  access_groups_with_invites = {
    for group in local.access_groups_object :
    ("${var.prefix}-${group.name}") => group if lookup(group, "invite_users", null) != null
  }
}

##############################################################################
