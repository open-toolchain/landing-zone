##############################################################################
# IBM Cloud Provider
##############################################################################

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
  ibmcloud_timeout = 60
}

##############################################################################


##############################################################################
# Landing Zone
##############################################################################

module "landing-zone" {
  source                         = "../../landing-zone"
  prefix                         = var.prefix
  region                         = var.region
  tags                           = var.tags
  resource_groups                = local.env.resource_groups
  vpcs                           = local.env.vpcs
  enable_transit_gateway         = local.env.enable_transit_gateway
  transit_gateway_resource_group = local.env.transit_gateway_resource_group
  transit_gateway_connections    = local.env.transit_gateway_connections
  ssh_keys                       = local.env.ssh_keys
  vsi                            = local.env.vsi
  security_groups                = local.env.security_groups
  virtual_private_endpoints      = local.env.virtual_private_endpoints
  cos                            = local.env.cos
  service_endpoints              = local.env.service_endpoints
  key_management                 = local.env.key_management
  atracker                       = local.env.atracker
  clusters                       = local.env.clusters
  wait_till                      = local.env.wait_till
}

##############################################################################