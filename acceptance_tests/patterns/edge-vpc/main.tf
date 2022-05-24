module "acceptance_tests" {
  source                              = "../../../patterns/vsi"
  ibmcloud_api_key                    = var.ibmcloud_api_key
  TF_VERSION                          = "1.0"
  prefix                              = "at-test"
  region                              = "us-south"
  ssh_public_key                      = "ssh-rsa AAAAthisisatesthihello=== test@test.test"
  tags                                = ["acceptance-test", "landing-zone"]
  network_cidr                        = "10.0.0.0/8"
  add_edge_vpc                        = true
  vpn_firewall_type                   = "vpn-and-waf"
  create_f5_network_on_management_vpc = false
  vpcs                                = ["management", "workload"]
  enable_transit_gateway              = true
  add_atracker_route                  = true
  hs_crypto_instance_name             = null
  hs_crypto_resource_group            = null
  vsi_image_name                      = "ibm-ubuntu-18-04-6-minimal-amd64-2"
  vsi_instance_profile                = "cx2-4x8"
  vsi_per_subnet                      = 1
  override                            = false
}