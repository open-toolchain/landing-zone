##############################################################################
# Create VSI
##############################################################################

locals {
  # Convert list to map
  vsi_map = {
    for vsi_group in var.vsi :
    (vsi_group.name) => merge(vsi_group, {
      # Add VPC ID
      vpc_id = module.vpc[vsi_group.vpc_name].vpc_id
      subnets = [
        # Add subnets to list if they are contained in the subnet list, prepends prefixes
        for subnet in module.vpc[vsi_group.vpc_name].subnet_zone_list :
        subnet if contains([
          # Create modified list of names
          for name in vsi_group.subnet_names :
          "${var.prefix}-${vsi_group.vpc_name}-${name}"
        ], subnet.name)
      ]
    })
  }

  ssh_keys = {
    for ssh_key in module.ssh_keys.ssh_keys :
    (ssh_key.name) => ssh_key.id
  }
}

module "ssh_keys" {
  source = "./ssh_key"
  prefix = var.prefix
  ssh_keys = [
    for ssh_key in var.ssh_keys :
    merge(
      {
        resource_group_id : ssh_key.resource_group == null ? null : local.resource_groups[ssh_key.resource_group]
      },
      ssh_key
    )
  ]
}

module "vsi" {
  source                = "github.com/Cloud-Schematics/vsi-module.git"
  for_each              = local.vsi_map
  resource_group_id     = each.value.resource_group == null ? null : local.resource_groups[each.value.resource_group]
  create_security_group = each.value.security_group == null ? false : true
  prefix                = each.value.name
  vpc_id                = module.vpc[each.value.vpc_name].vpc_id
  subnets               = each.value.subnets
  image                 = each.value.image_name
  security_group_ids = each.value.security_groups == null ? [] : [
    for group in each.value.security_groups :
    ibm_is_security_group.security_group[group].id
  ]
  ssh_key_ids = [
    for ssh_key in each.value.ssh_keys :
    local.ssh_keys[ssh_key]
  ]
  machine_type          = each.value.machine_type
  vsi_per_subnet        = each.value.vsi_per_subnet
  security_group        = each.value.security_group
  load_balancers        = each.value.load_balancers == null ? [] : each.value.load_balancers
  block_storage_volumes = each.value.block_storage_volumes == null ? [] : each.value.block_storage_volumes
  enable_floating_ip    = each.value.enable_floating_ip == true ? true : false
  depends_on            = [module.ssh_keys]
}

##############################################################################