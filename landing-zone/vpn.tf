##############################################################################
# VPN Gateway Locals
##############################################################################

locals {
  # Create map of VPN connections
  vpn_gateway_map = {
    # for each gateway
    for gateway in var.vpn_gateways :
    # Create a key for the gate way with an object containing options and subnet IDs
    (gateway.name) => {
      vpc_id = module.vpc[gateway.vpc_name].vpc_id
      subnet_id = [
        for subnet in module.vpc[gateway.vpc_name].subnet_zone_list :
        subnet if subnet.name == "${var.prefix}-${gateway.vpc_name}-${gateway.subnet_name}"
      ][0].id
      mode           = gateway.mode
      connections    = gateway.connections
      resource_group = gateway.resource_group
    }
  }

  # List of VPN gateway connections
  vpn_connection_list = flatten([
    for gateway in var.vpn_gateways :
    [
      for connection in gateway.connections :
      merge({
        gateway_name    = "${var.prefix}-${gateway.name}"
        connection_name = "${gateway.name}-connection-${index(gateway.connections, connection) + 1}"
      }, gateway.connections)
    ]
  ])

  # Convert list to map
  vpn_connection_map = {
    for connection in local.vpn_connection_list :
    (connection.connection_name) => connection
  }
}

##############################################################################


##############################################################################
# Create VPN Gateways
##############################################################################

resource "ibm_is_vpn_gateway" "gateway" {
  for_each       = local.vpn_gateway_map
  name           = "${var.prefix}-${each.key}"
  subnet         = each.value.subnet_id
  mode           = each.value.mode
  resource_group = each.value.resource_group == null ? null : local.resource_groups[each.value.resource_group]
  tags           = var.tags
}

resource "ibm_is_vpn_gateway_connection" "gateway_connection" {
  for_each       = local.vpn_connection_map
  name           = each.value.connection_name
  vpn_gateway    = ibm_is_vpn_gateway.gateway[each.value.gateway_name].id
  peer_address   = each.value.peer_address
  preshared_key  = each.value.preshared_key
  local_cidrs    = each.value.local_cidrs
  peer_cidrs     = each.value.peer_cidrs
  admin_state_up = each.value.admin_state_up
}

##############################################################################