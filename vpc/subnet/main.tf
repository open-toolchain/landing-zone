##############################################################################
# Subnet Resource
# Copyright 2020 IBM
##############################################################################

locals {
  # Convert subnets into a single list
  subnet_list         = flatten([
    # For each key in the object create an array
    for zone in keys(var.subnets):
    # Each item in the list contains information about a single subnet
    [
      for value in var.subnets[zone]:
      {
        name           = value.name                                             # Subnet shortname
        prefix_name    = "${var.prefix}-${value.name}"                          # Creates a name of the prefix and subnet name
        zone           = index(keys(var.subnets), zone) + 1                     # Zone 1, 2, or 3
        zone_name      = "${var.region}-${index(keys(var.subnets), zone) + 1}"  # Contains region and zone
        cidr           = value.cidr                                             # CIDR Block
        count          = index(var.subnets[zone], value) + 1                    # Count of the subnet within the zone
        public_gateway = value.public_gateway                                   # Public Gateway ID
        acl_id         = value.acl_id                                           # ACL ID
      }
    ]
  ])

  # Create an object from the array for human readable reference
  subnet_object = {
    for subnet in local.subnet_list:
    "${var.prefix}-${subnet.name}" => subnet
  }

  # List of public gateways
  public_gateway_list = [
    for gateway in keys(var.public_gateways):
    var.public_gateways[gateway] == "" ? null : var.public_gateways[gateway]
  ]

}

##############################################################################


##############################################################################
# Create New Prefixes
##############################################################################

resource ibm_is_vpc_address_prefix subnet_prefix {
  for_each = local.subnet_object
  name     = each.value.prefix_name
  zone     = each.value.zone_name
  vpc      = var.vpc_id
  cidr     = each.value.cidr
}

##############################################################################


##############################################################################
# Create Subnets
##############################################################################

resource ibm_is_subnet subnet {
  for_each                 = local.subnet_object
  vpc                      = var.vpc_id
  name                     = each.key
  zone                     = each.value.zone_name
  resource_group           = var.resource_group_id
  ipv4_cidr_block          = ibm_is_vpc_address_prefix.subnet_prefix[each.value.prefix_name].cidr
  network_acl              = each.value.acl_id
  routing_table            = var.routing_table_id
  # If the public gateway variable is an empty string, or if the subnet public gateway is set to false
  # will be null
  public_gateway           = local.public_gateway_list[each.value.zone - 1] == "" || each.value.public_gateway == false ? null : local.public_gateway_list[each.value.zone - 1]
}

##############################################################################