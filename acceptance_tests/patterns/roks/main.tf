module "acceptance_tests" {
  source                   = "../../../patterns/roks"
  ibmcloud_api_key         = var.ibmcloud_api_key
  TF_VERSION               = "1.0"
  prefix                   = "at-test"
  region                   = "us-south"
  tags                     = ["acceptance-test", "landing-zone"]
  network_cidr             = "10.0.0.0/8"
  vpcs                     = ["management", "workload"]
  enable_transit_gateway   = true
  add_atracker_route       = true
  hs_crypto_instance_name  = null
  hs_crypto_resource_group = null
  cluster_zones            = 1
  flavor                   = "bx2.16x64"
  workers_per_zone         = 2
  wait_till                = "IngressReady"
  entitlement              = null
  override                 = false
}