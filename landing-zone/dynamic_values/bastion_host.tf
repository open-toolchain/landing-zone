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

  # Create list of bastion host template data
  bastion_template_data_list = flatten([
    # For each deployment of bastion host servers
    for deployment in var.bastion_vsi :
    [
      {
        # Add teleport config variables to list
        name               = "${var.prefix}-${deployment.name}-${deployment.subnet_name}"
        TELEPORT_LICENSE   = deployment.teleport_license
        HTTPS_CERT         = deployment.https_cert
        HTTPS_KEY          = deployment.https_key
        DOMAIN             = deployment.domain
        COS_BUCKET         = deployment.cos_bucket_name
        cos_key_name       = deployment.cos_key_name
        app_id_key_name    = deployment.app_id_key_name
        TELEPORT_VERSION   = deployment.teleport_version
        CLAIM_TO_ROLES     = deployment.claims_to_roles
        MESSAGE_OF_THE_DAY = deployment.message_of_the_day

      }
    ]
  ])

  # Covert to map
  bastion_template_data_map = {
    for template in local.bastion_template_data_list :
    (template.name) => template
  }

}

##############################################################################