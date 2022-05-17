##############################################################################
# Teleport / Bastion Values
##############################################################################

locals {
  # Array for creation of bastion instances
  bastion_zone_list = flatten(
    [
      # if provision teleport on f5
      var.provision_teleport_in_f5 == true
      # all three zones
      ? [1, 2, 3]
      # if not management zones
      : var.teleport_management_zones == 0
      # empty array
      ? []
      # otherwise for each zone in the range return that number +1
      : [
        for zone in range(var.teleport_management_zones) :
        zone + 1
      ]
    ]
  )

  # List of bastion resources to use for concat functions
  bastion_resource_list = var.provision_teleport_in_f5 == true || var.teleport_management_zones > 0 ? ["bastion"] : []
  use_teleport          = length(local.bastion_resource_list) > 0

  # Public Gateways for Bastion VPC
  bastion_gateways = {
    for zone in [1, 2, 3] : # for each zone
    "zone-${zone}" => (
      var.provision_teleport_in_f5 == true
      ? true # true if enable bastion host
      : zone <= var.teleport_management_zones
      ? true # true if is a zone in management
      : false
    )
  }

  # Teleport Instances
  teleport_vsi = [
    for instance in local.bastion_zone_list :
    {
      name                            = "bastion-${instance}"
      vpc_name                        = local.vpc_list[0]
      subnet_name                     = "bastion-zone-${instance}"
      resource_group                  = "${var.prefix}-${local.vpc_list[0]}-rg"
      ssh_keys                        = ["ssh-key"]
      image_name                      = var.teleport_vsi_image_name
      machine_type                    = var.teleport_instance_profile
      boot_volume_encryption_key_name = "${var.prefix}-vsi-volume-key"
      security_groups                 = ["bastion-vsi-sg"]
    }
  ]
}

##############################################################################


##############################################################################
# Bastion / Teleport Outputs
##############################################################################

output "bastion_zone_list" {
  description = "List of zones where teleport will be provisoned"
  value       = local.bastion_zone_list
}

output "bastion_resource_list" {
  description = "Returns an empty array or an array of \"bastion\" when bastion resources are created"
  value       = local.bastion_resource_list
}

output "bastion_gateways" {
  description = "List of public gateways to use in bastion vpc."
  value       = local.bastion_gateways
}

output "teleport_vsi" {
  description = "List of teleport VSI to create using landing zone module"
  value       = local.teleport_vsi
}

##############################################################################