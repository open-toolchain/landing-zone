##############################################################################
# Access Group Locals
##############################################################################

locals {
  # Convert access groups from list into object
  access_groups_object = {
    for group in var.access_groups :
    ("${var.prefix}-${group.name}") => group
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

  # Convert to map
  access_policies = {
    for item in local.access_policy_list :
    (item.name) => item
  }


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

  # Convert access policy list into object
  dynamic_rules = {
    for item in local.dynamic_rule_list :
    (item.name) => item
  }

  # All account management policies
  account_management_list = [
    for group in var.access_groups :
    {
      group = "${var.prefix}-${group.name}"
      roles = group.account_management_policies
    } if lookup(group, "account_management_policies", null) != null
  ]

  # Convert to map
  account_management_map = {
    for group in local.account_management_list :
    (group.group) => group.roles
  }

  # Map of groups with invites
  access_groups_with_invites = {
    for group in local.access_groups_object :
    ("${var.prefix}-${group.name}") => group if lookup(group, "invite_users", null) != null
  }
}

##############################################################################
