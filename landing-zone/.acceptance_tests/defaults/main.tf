##############################################################################
# Test Provider
##############################################################################

terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "~>1.39.2"
    }
  }
  required_version = ">=1.0"
  experiments      = [module_variable_optional_attrs]
}

##############################################################################


##############################################################################
# Landing Zone
##############################################################################

locals {
  override = jsondecode(file("${path.module}/mixed.json"))
}

##############################################################################


##############################################################################
# IBM Cloud Provider
##############################################################################

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = "us-south"
  ibmcloud_timeout = 60
}

##############################################################################


##############################################################################
# Test Module
##############################################################################

module "landing_zone" {
  source                         = "../.."
  prefix                         = "ut"
  region                         = "us-south"
  tags                           = ["unit-test", "landing-zone"]
  resource_groups                = lookup(local.override, "resource_groups")
  network_cidr                   = "10.0.0.0/8"
  vpcs                           = lookup(local.override, "vpcs")
  vpn_gateways                   = lookup(local.override, "vpn_gateways")
  enable_transit_gateway         = lookup(local.override, "enable_transit_gateway")
  transit_gateway_resource_group = lookup(local.override, "transit_gateway_resource_group")
  transit_gateway_connections    = lookup(local.override, "transit_gateway_connections")
  ssh_keys                       = lookup(local.override, "ssh_keys")
  vsi                            = lookup(local.override, "vsi")
  security_groups                = lookup(local.override, "security_groups")
  virtual_private_endpoints      = lookup(local.override, "virtual_private_endpoints")
  cos                            = lookup(local.override, "cos")
  service_endpoints              = lookup(local.override, "service_endpoints")
  key_management                 = lookup(local.override, "key_management")
  atracker                       = lookup(local.override, "atracker")
  clusters                       = lookup(local.override, "clusters")
  wait_till                      = lookup(local.override, "wait_till")
}

##############################################################################