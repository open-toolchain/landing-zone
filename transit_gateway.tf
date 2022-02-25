
##############################################################################
# Transit Gateway
##############################################################################

resource ibm_tg_gateway transit_gateway {
  count          = var.enable_transit_gateway ? 1 : 0
  name           = "${var.prefix}-transit-gateway"
  location       = var.region
  global         = false
  resource_group = data.ibm_resource_group.resource_group.id
}

##############################################################################


##############################################################################
# Transit Gateway Connections
##############################################################################

resource ibm_tg_connection connection {
  for_each     = var.enable_transit_gateway ? toset(var.transit_gateway_connections) : toset([])
  gateway      = ibm_tg_gateway.transit_gateway[0].id
  network_type = "vpc"
  name         = "${var.prefix}-${each.key}-hub-connection"
  network_id   = module.vpc[each.key].vpc_crn
}

##############################################################################