##############################################################################
# Multizone subnets
##############################################################################

locals {
  # Convert subnets into a single list
  subnet_list = flatten([
    # For each key in the object create an array
    for zone in keys(var.subnets) :
    # Each item in the list contains information about a single subnet
    [
      for value in var.subnets[zone] :
      {
        name        = value.name                                            # Subnet shortname
        prefix_name = "${var.prefix}-${value.name}"                         # Creates a name of the prefix and subnet name
        zone        = index(keys(var.subnets), zone) + 1                    # Zone 1, 2, or 3
        zone_name   = "${var.region}-${index(keys(var.subnets), zone) + 1}" # Contains region and zone
        cidr        = value.cidr                                            # CIDR Block
        count       = index(var.subnets[zone], value) + 1                   # Count of the subnet within the zone
        acl         = value.acl_name
        # Public gateway ID
        public_gateway = value.public_gateway && var.use_public_gateways[zone] ? ibm_is_public_gateway.gateway[zone].id : null
      }
    ]
  ])

  # Create an object from the array for human readable reference
  subnet_object = {
    for subnet in local.subnet_list :
    "${var.prefix}-${subnet.name}" => subnet
  }
}

##############################################################################


##############################################################################
# Create New Prefixes
##############################################################################

resource "ibm_is_vpc_address_prefix" "subnet_prefix" {
  for_each = local.subnet_object
  name     = each.value.prefix_name
  zone     = each.value.zone_name
  vpc      = ibm_is_vpc.vpc.id
  cidr     = each.value.cidr
}

##############################################################################


##############################################################################
# Create Subnets
##############################################################################

resource "ibm_is_subnet" "subnet" {
  for_each        = local.subnet_object
  vpc             = ibm_is_vpc.vpc.id
  name            = each.key
  zone            = each.value.zone_name
  resource_group  = var.resource_group_id
  ipv4_cidr_block = ibm_is_vpc_address_prefix.subnet_prefix[each.value.prefix_name].cidr
  network_acl     = ibm_is_network_acl.network_acl[each.value.acl].id
  public_gateway  = each.value.public_gateway
}

##############################################################################