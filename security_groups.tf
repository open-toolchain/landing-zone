##############################################################################
# Change Security Group (Optional)
##############################################################################

locals {
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

  # Convert list to map
  security_group_rules = {
    for rule in local.security_group_rule_list :
    ("${rule.sg_name}-${rule.name}") => rule
  }
}

resource "ibm_is_security_group_rule" "security_group_rules" {
  for_each  = local.security_group_rules
  group     = ibm_is_security_group.security_group[each.value.sg_name].id
  direction = each.value.direction
  remote    = each.value.source

  ##############################################################################
  # Dynamicaly create ICMP Block
  ##############################################################################

  dynamic "icmp" {

    # Runs a for each loop, if the rule block contains icmp, it looks through the block
    # Otherwise the list will be empty        

    for_each = (
      each.value.icmp != null
      ? [each.value]
      : []
    )
    # Conditianally add content if sg has icmp
    content {
      type = lookup(
        lookup(
          each.value,
          "icmp"
        ),
        "type"
      )
      code = lookup(
        lookup(
          each.value,
          "icmp"
        ),
        "code"
      )
    }
  }

  ##############################################################################

  ##############################################################################
  # Dynamically create TCP Block
  ##############################################################################

  dynamic "tcp" {

    # Runs a for each loop, if the rule block contains tcp, it looks through the block
    # Otherwise the list will be empty     

    for_each = (
      each.value.tcp != null
      ? [each.value]
      : []
    )

    # Conditionally adds content if sg has tcp
    content {

      port_min = lookup(
        lookup(
          each.value,
          "tcp"
        ),
        "port_min"
      )

      port_max = lookup(
        lookup(
          each.value,
          "tcp"
        ),
        "port_max"
      )
    }
  }

  ##############################################################################

  ##############################################################################
  # Dynamically create UDP Block
  ##############################################################################

  dynamic "udp" {

    # Runs a for each loop, if the rule block contains udp, it looks through the block
    # Otherwise the list will be empty     

    for_each = (
      each.value.tcp != null
      ? [each.value]
      : []
    )

    # Conditionally adds content if sg has tcp
    content {
      port_min = lookup(
        lookup(
          each.value,
          "udp"
        ),
        "port_min"
      )
      port_max = lookup(
        lookup(
          each.value,
          "udp"
        ),
        "port_max"
      )
    }
  }

  ##############################################################################

}

##############################################################################
