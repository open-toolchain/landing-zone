
##############################################################################
# VPN Gateway Values
##############################################################################

locals {
  # Create map of VPN gatways
  vpn_gateway_map = {
    # for each gateway
    for gateway in var.vpn_gateways :
    # Create a key for the gate way with an object containing options and subnet IDs
    (gateway.name) => {
      vpc_id = var.vpc_modules[gateway.vpc_name].vpc_id
      subnet_id = [
        for subnet in var.vpc_modules[gateway.vpc_name].subnet_zone_list :
        subnet if subnet.name == "${var.prefix}-${gateway.vpc_name}-${gateway.subnet_name}"
      ][0].id
      mode           = gateway.mode
      connections    = gateway.connections
      resource_group = gateway.resource_group
    }
  }

  # Create list of VPN Connections
  vpn_connection_list = flatten([
    for gateway in var.vpn_gateways :
    [
      for connection in gateway.connections :
      merge({
        gateway_name    = "${var.prefix}-${gateway.name}"
        connection_name = "${gateway.name}-connection-${index(gateway.connections, connection) + 1}"
      }, connection)
    ]
  ])

  vpn_connection_map = {
    for connection in local.vpn_connection_list :
    (connection.connection_name) => connection
  }
}

##############################################################################

