##############################################################################
# Bastion VSI Dynamic Values
##############################################################################

locals {
  # Convert list to map
  bastion_vsi_map = {
    for vsi_group in var.bastion_vsi :
    ("${var.prefix}-${vsi_group.name}") => merge(vsi_group, {
      # Add VPC ID
      vpc_id = var.vpc_modules[vsi_group.vpc_name].vpc_id
      subnets = [
        # Add subnets to list if they are contained in the subnet list, prepends prefixes
        for subnet in var.vpc_modules[vsi_group.vpc_name].subnet_zone_list :
        subnet if "${var.prefix}-${vsi_group.vpc_name}-${vsi_group.subnet_name}" == subnet.name
      ]
    })
  }
}

##############################################################################