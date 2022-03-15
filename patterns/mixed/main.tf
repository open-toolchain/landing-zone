##############################################################################
# Landing Zone
##############################################################################

module landing-zone {
  source                         = "../../landing-zone"
  ibmcloud_api_key               = var.ibmcloud_api_key
  prefix                         = var.prefix
  region                         = var.region
  tags                           = var.tags
  resource_groups                = var.resource_groups
  vpcs                           = var.vpcs
  enable_transit_gateway         = var.enable_transit_gateway
  transit_gateway_resource_group = var.transit_gateway_resource_group
  transit_gateway_connections    = var.transit_gateway_connections
  ssh_keys                       = var.ssh_keys
  vsi                            = var.vsi
  security_groups                = var.security_groups
  virtual_private_endpoints      = var.virtual_private_endpoints
  cos                            = var.cos
  service_endpoints              = var.service_endpoints
  key_management                 = var.key_management
  atracker                       = var.atracker
  clusters                       = var.clusters
  wait_till                      = var.wait_till
}

##############################################################################