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
  resource_groups                = lookup(local.override, "resource_groups", local.config.resource_groups)
  vpcs                           = lookup(local.override, "vpcs", local.config.vpcs)
  enable_transit_gateway         = lookup(local.override, "enable_transit_gateway", local.config.enable_transit_gateway)
  transit_gateway_resource_group = lookup(local.override, "transit_gateway_resource_group", local.config.transit_gateway_resource_group)
  transit_gateway_connections    = lookup(local.override, "transit_gateway_connections", local.config.transit_gateway_connections)
  ssh_keys                       = lookup(local.override, "ssh_keys", local.config.ssh_keys)
  vsi                            = lookup(local.override, "vsi", local.config.vsi)
  security_groups                = lookup(local.override, "security_groups", lookup(local.config, "security_groups", []))
  virtual_private_endpoints      = lookup(local.override, "virtual_private_endpoints", local.config.virtual_private_endpoints)
  cos                            = lookup(local.override, "cos", local.config.object_storage)
  service_endpoints              = lookup(local.override, "service_endpoints", "private")
  key_management                 = lookup(local.override, "key_management", local.config.key_management)
  atracker                       = lookup(local.override, "atracker", local.config.atracker)
  clusters                       = lookup(local.override, "clusters", local.config.clusters)
  wait_till                      = lookup(local.override, "wait_till", "IngressReady")
}

##############################################################################