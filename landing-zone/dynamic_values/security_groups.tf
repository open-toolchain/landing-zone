##############################################################################
# Security Group Dynamic Values
##############################################################################

locals {
  security_group_map = {
    for group in var.security_groups :
    (group.name) => merge(group, { vpc_id = var.vpc_modules[group.vpc_name].vpc_id })
  }

  # Create list of all sg rules to create adding the name
  security_group_rule_list = flatten([
    for group in var.security_groups :
    [
      for rule in group.rules :
      merge({
        sg_name = group.name
      }, rule)
    ]
  ])

  # Convert to map
  security_group_rules_map = {
    for rule in local.security_group_rule_list :
    ("${rule.sg_name}-${rule.name}") => rule
  }
}

##############################################################################