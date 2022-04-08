##############################################################################
# VSI Variables
##############################################################################

variable "vsi" {
  description = "Direct reference to VSI variable"
}

variable "ssh_keys" {
  description = "Direct reference to SSH Keys"
}

##############################################################################


##############################################################################
# VSI Dynamic Values
##############################################################################

locals {
  # Convert list to map
  vsi_map = {
    for vsi_group in var.vsi :
    ("${var.prefix}-${vsi_group.name}") => merge(vsi_group, {
      # Add VPC ID
      vpc_id = var.vpc_modules[vsi_group.vpc_name].vpc_id
      subnets = [
        # Add subnets to list if they are contained in the subnet list, prepends prefixes
        for subnet in var.vpc_modules[vsi_group.vpc_name].subnet_zone_list :
        subnet if contains([
          # Create modified list of names
          for name in vsi_group.subnet_names :
          "${var.prefix}-${vsi_group.vpc_name}-${name}"
        ], subnet.name)
      ]
    })
  }

  ssh_keys = [
    for ssh_key in var.ssh_keys :
    merge(
      {
        resource_group_id : ssh_key.resource_group == null ? null : var.resource_groups[ssh_key.resource_group]
      },
      ssh_key
    )
  ]
}

##############################################################################


##############################################################################
# VSI Outputs
##############################################################################

output "vsi_map" {
  description = "Map of VSI deployments"
  value       = local.vsi_map
}

output "ssh_keys" {
  description = "List of SSH keys with resource group ID added"
  value       = local.ssh_keys
}

##############################################################################