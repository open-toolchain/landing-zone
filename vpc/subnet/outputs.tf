##############################################################################
# Subnet Outputs
# Copyright 2020 IBM
##############################################################################

output ids {
  description = "The IDs of the subnets"
  value       = [
    for subnet in ibm_is_subnet.subnet:
    subnet.id
  ]
}

output detail_list {
  description = "A list of subnets containing names, CIDR blocks, and zones."
  value       = {
    for zone_name in distinct([
      for subnet in ibm_is_subnet.subnet:
      subnet.zone
    ]):
    zone_name => {
      for subnet in ibm_is_subnet.subnet: 
      subnet.name => {
        id = subnet.id
        cidr = subnet.ipv4_cidr_block 
      } if subnet.zone == zone_name
    }
  }
}

output zone_list {
  description = "A list containing subnet IDs and subnet zones"
  value       = [
    for subnet in ibm_is_subnet.subnet: {
      name = subnet.name
      id   = subnet.id
      zone = subnet.zone
      cidr = subnet.ipv4_cidr_block
    }
  ]
}

##############################################################################