##############################################################################
# Local References
##############################################################################

locals {
  address_prefixes = module.dynamic_values.address_prefixes
  routes           = module.dynamic_values.routes
  gateway_map      = module.dynamic_values.use_public_gateways
}

##############################################################################

##############################################################################
# Create new VPC
##############################################################################

resource "ibm_is_vpc" "vpc" {
  name                        = var.prefix != null ? "${var.prefix}-${var.vpc_name}" : var.vpc_name
  resource_group              = var.resource_group_id
  classic_access              = var.classic_access
  address_prefix_management   = var.use_manual_address_prefixes == false ? null : "manual"
  default_network_acl_name    = var.default_network_acl_name
  default_security_group_name = var.default_security_group_name
  default_routing_table_name  = var.default_routing_table_name
  tags                        = var.tags
}

##############################################################################

##############################################################################
# Address Prefixes
##############################################################################

resource "ibm_is_vpc_address_prefix" "address_prefixes" {
  count = length(local.address_prefixes)
  name  = local.address_prefixes[count.index].name
  vpc   = ibm_is_vpc.vpc.id
  zone  = local.address_prefixes[count.index].zone
  cidr  = local.address_prefixes[count.index].cidr
}

##############################################################################

##############################################################################
# ibm_is_vpc_route: Create vpc route resource
##############################################################################

resource "ibm_is_vpc_route" "route" {
  for_each    = local.routes
  name        = "${var.prefix}-route-${each.value.name}"
  vpc         = ibm_is_vpc.vpc.id
  zone        = each.value.zone
  destination = each.value.destination
  next_hop    = each.value.next_hop
}

##############################################################################

##############################################################################
# Public Gateways (Optional)
##############################################################################

resource "ibm_is_public_gateway" "gateway" {
  for_each       = local.gateway_map
  name           = "${var.prefix}-public-gateway-${each.key}"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = var.resource_group_id
  zone           = each.value
}

##############################################################################