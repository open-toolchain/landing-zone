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

locals {
  # For each address prefix
  address_prefixes = var.address_prefixes == null ? [] : flatten([
    # For each zone
    for zone in var.address_prefixes :
    [
      # Return object containing name, zone, and CIDR
      for address in zone :
      {
        name = "${var.prefix}-${zone}-${index(zone, address) + 1}"
        cidr = address
        zone = "${var.region}-${index(keys(var.address_prefixes), zone) + 1}"
      }
    ] if zone != null
  ])
}

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

locals {
  routes_map = {
    # Convert routes from list to map
    for route in var.routes :
    (route.name) => route
  }
}

resource "ibm_is_vpc_route" "route" {
  for_each    = local.routes_map
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

locals {
  # create object that only contains gateways that will be created
  gateway_object = {
    for zone in keys(var.use_public_gateways) :
    zone => "${var.region}-${index(keys(var.use_public_gateways), zone) + 1}" if var.use_public_gateways[zone]
  }
}

resource "ibm_is_public_gateway" "gateway" {
  for_each       = local.gateway_object
  name           = "${var.prefix}-public-gateway-${each.key}"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = var.resource_group_id
  zone           = each.value
}

##############################################################################