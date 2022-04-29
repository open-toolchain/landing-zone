##############################################################################
# Security Group Locals
##############################################################################

locals {
  security_group_map       = module.dynamic_values.security_group_map
  security_group_rules_map = module.dynamic_values.security_group_rules_map
}

##############################################################################


##############################################################################
# Security Group
##############################################################################

resource "ibm_is_security_group" "security_group" {
  for_each       = local.security_group_map
  name           = each.value.name
  resource_group = each.value.resource_group == null ? null : local.resource_groups[each.value.resource_group]
  vpc            = each.value.vpc_id
  tags           = var.tags
}

##############################################################################


##############################################################################
# Security Group Rules
##############################################################################

resource "ibm_is_security_group_rule" "security_group_rules" {
  for_each  = local.security_group_rules_map
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
        "type",
        null
      )
      code = lookup(
        lookup(
          each.value,
          "icmp"
        ),
        "code",
        null
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
        "port_min",
        null
      )

      port_max = lookup(
        lookup(
          each.value,
          "tcp"
        ),
        "port_max",
        null
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
      each.value.udp != null
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
        "port_min",
        null
      )
      port_max = lookup(
        lookup(
          each.value,
          "udp"
        ),
        "port_max",
        null
      )
    }
  }

  ##############################################################################

}

##############################################################################