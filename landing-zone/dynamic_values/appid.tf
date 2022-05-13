##############################################################################
# App ID Locals
##############################################################################

locals {
  appid_redirect_urls = [
    for vsi_group in var.bastion_vsi :
    "https://${var.prefix}-${vsi_group.name}.${var.teleport_domain}:3080/v1/webapi/oidc/callback"
  ]
}

##############################################################################