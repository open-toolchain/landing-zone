##############################################################################
# VPN Locals
##############################################################################

locals {
  vpn_gateway_map = {
    # Convert list to map with name as the key
    for gateway in var.vpn_gateways :
    (gateway.name) => gateway
  }

  # List of subnet names used by VPN gateways
  vpn_subnet_names = var.vpn_gateways.*.name

  # For each contained subnet, create a map linking the subnet name to the ID of the subnet after creation
  vpn_subnet_map = {
    for subnet in ibm_is_subnet.subnet :
    (subnet.name) => subnet.id if contains(local.vpn_subnet_names, subnet.name)
  }

  # Create a list of all VPN gateway connections
  vpn_connection_list = flatten([
    # For each gateway
    for gateway in var.vpn_gateways :
    [
      # Return the connection object with fields added for the gateway name and connection name
      for connection in gateway.connections :
      merge(connection, {
        gateway_name    = "${var.prefix}-${gateway.name}"
        connection_name = "${gateway.name}-connection-${index(gateway.connections, connection) + 1}"
      })
    ]
  ])

  # Convert connection list into map
  vpn_connection_map = {
    for connection in local.vpn_connection_list :
    (connection.connection_name) => connection
  }
}

##############################################################################


##############################################################################
# Create VPN Gateway resources
##############################################################################

resource "ibm_is_vpn_gateway" "gateway" {
  for_each       = local.vpn_gateway_map
  name           = "${var.prefix}-${each.value.name}"
  subnet         = local.vpn_subnet_map[each.value.subnet]
  mode           = each.value.mode
  resource_group = var.resource_group_id
  tags           = each.value.tags
}

##############################################################################


##############################################################################
# Create VPN Gateway Connection resources
##############################################################################

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