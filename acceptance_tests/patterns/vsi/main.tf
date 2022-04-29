module "acceptance_tests" {
  source                   = "../../../patterns/vsi"
  ibmcloud_api_key         = var.ibmcloud_api_key
  TF_VERSION               = "1.0"
  prefix                   = "at-test"
  region                   = "us-south"
  ssh_public_key           = "<user defined>"
  tags                     = ["acceptance-test", "landing-zone"]
  network_cidr             = "10.0.0.0/8"
  vpcs                     = ["management", "workload"]
  enable_transit_gateway   = true
  add_atracker_route       = true
  hs_crypto_instance_name  = null
  hs_crypto_resource_group = null
  vsi_image_name           = "ibm-ubuntu-16-04-5-minimal-amd64-1"
  vsi_instance_profile     = "cx2-2x4"
  vsi_per_subnet           = 1
  override                 = false
}