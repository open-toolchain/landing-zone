##############################################################################
# ibm_is_security_group
##############################################################################

locals {
  vsi_security_group = [var.create_security_group ? var.security_group : null]
  # Create list of all security groups including the ones for load balancers
  security_groups = flatten([
    [
      for group in local.vsi_security_group :
      group if group != null
    ],
    [
      for load_balancer in var.load_balancers :
      load_balancer.security_group if load_balancer.security_group != null
    ]
  ])

  # Convert list to map
  security_group_map = {
    for group in local.security_groups :
    (group.name) => group
  }
}

resource "ibm_is_security_group" "security_group" {
  for_each       = local.security_group_map
  name           = each.value.name
  resource_group = var.resource_group_id
  vpc            = var.vpc_id
  tags           = var.tags
}

##############################################################################


##############################################################################
# Change Security Group (Optional)
##############################################################################

locals {
  # Create list of all sg rules to create adding the name
  security_group_rule_list = flatten([
    for group in local.security_groups :
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
