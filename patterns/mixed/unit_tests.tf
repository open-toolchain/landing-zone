##############################################################################
# Init Unit Tests
##############################################################################

module "edge_unit_tests" {
  source                              = "../dynamic_values"
  prefix                              = "ut"
  region                              = "us-south"
  vpcs                                = ["management", "workload"]
  hs_crypto_instance_name             = "test"
  hs_crypto_resource_group            = "test"
  add_edge_vpc                        = true
  create_f5_network_on_management_vpc = false
  provision_teleport_in_f5            = null
  vpn_firewall_type                   = "waf"
  f5_image_name                       = "f5-bigip-15-1-5-1-0-0-14-all-1slot"
  f5_instance_profile                 = "cx2-4x8"
  app_id                              = "appid"
  enable_f5_management_fip            = false
  enable_f5_external_fip              = false
  teleport_management_zones           = 0
  appid_resource_group                = "test-appid-rg"
  teleport_instance_profile           = "cx2-4x8"
  teleport_vsi_image_name             = "ibm-ubuntu-18-04-6-minimal-amd64-2"
  domain                              = "domain"
  hostname                            = "hostname"
}

module "f5_on_management" {
  source                              = "../dynamic_values"
  prefix                              = "ut"
  region                              = "us-south"
  vpcs                                = ["management", "workload"]
  hs_crypto_instance_name             = "test"
  hs_crypto_resource_group            = "test"
  add_edge_vpc                        = false
  create_f5_network_on_management_vpc = true
  provision_teleport_in_f5            = true
  vpn_firewall_type                   = "vpn-and-waf"
  f5_image_name                       = "f5-bigip-15-1-5-1-0-0-14-all-1slot"
  f5_instance_profile                 = "cx2-4x8"
  app_id                              = "appid"
  enable_f5_management_fip            = false
  enable_f5_external_fip              = false
  teleport_management_zones           = 0
  appid_resource_group                = "test-appid-rg"
  teleport_instance_profile           = "cx2-4x8"
  teleport_vsi_image_name             = "ibm-ubuntu-18-04-6-minimal-amd64-2"
  domain                              = "domain"
  hostname                            = "hostname"
}

##############################################################################