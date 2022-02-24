##############################################################################
# VPE Locals
##############################################################################

locals {
  vpe_gateway_connection_list = flatten([
    for service in var.virtual_private_endpoints :
    [
      for vpcs in service.vpcs :
      {
        connection_name     = "${service.service_name}-${vpcs.name}"
        crn                 = service.service_crn
        vpc_id              = module.vpc[vpcs.name].vpc_id
        security_group_name = vpcs.security_group_name
        subnets = [
          for subnet in module.vpc[vpcs.name].subnet_zone_list :
          subnet.id if contains([
            for name in vpcs.subnets :
            "${var.prefix}-${vpcs.name}-${name}"
          ], subnet.name)
        ],
      }
    ]
  ])
  vpe_gateway_connections = {
    for connection in local.vpe_gateway_connection_list :
    (connection.connection_name) => connection
  }
}

##############################################################################


##############################################################################
# Endpoint Gateways
##############################################################################

resource "ibm_is_virtual_endpoint_gateway" "endpoint_gateway" {
  for_each        = local.vpe_gateway_connections
  name            = each.key
  vpc             = each.value.vpc_id
  resource_group  = data.ibm_resource_group.resource_group.id
  security_groups = each.value.security_group_name == null ? null : [each.value.security_group_name]

  target {
    crn           = each.value.crn
    resource_type = "provider_cloud_service"
  }

  dynamic "ips" {
    for_each = each.value.subnets
    content {
      name   = "${each.key}-${index(each.value.subnets, ips.value) + 1}-ip"
      subnet = ips.value
    }
  }
}

##############################################################################\

##############################################################################
# ibm_is_security_group
##############################################################################

locals {
  # Convert list to map
  security_group_map = {
    for group in var.security_groups :
    (group.name) => group
  }
}

resource "ibm_is_security_group" "security_group" {
  for_each       = local.security_group_map
  name           = each.value.name
  resource_group = data.ibm_resource_group.resource_group.id
  vpc            = module.vpc[each.value.vpc_name].vpc_id
  tags           = var.tags
}

##############################################################################


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