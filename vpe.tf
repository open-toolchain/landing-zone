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


