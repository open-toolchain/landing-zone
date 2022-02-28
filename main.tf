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
# Resource Group where VPC is created
##############################################################################

data "ibm_resource_group" "resource_group" {
  name = var.resource_group
}

##############################################################################


##############################################################################
# Create VPCs
##############################################################################

locals {
  # Conver VPC List to Map
  vpc_map = {
    for vpc_network in var.vpcs :
    (vpc_network.prefix) => vpc_network
  }
}

module "vpc" {
  source   = "github.com/Cloud-Schematics/multizone-vpc-module.git"
  for_each = local.vpc_map

  resource_group_id           = data.ibm_resource_group.resource_group.id
  region                      = var.region
  prefix                      = "${var.prefix}-${each.value.prefix}"
  vpc_name                    = "vpc"
  classic_access              = each.value.classic_access
  use_manual_address_prefixes = each.value.use_manual_address_prefixes
  default_network_acl_name    = each.value.default_network_acl_name
  default_security_group_name = each.value.default_security_group_name
  default_routing_table_name  = each.value.default_routing_table_name
  address_prefixes            = each.value.address_prefixes
  network_acls                = each.value.network_acls
  use_public_gateways         = each.value.use_public_gateways
  subnets                     = each.value.subnets
}

##############################################################################


##############################################################################
# SSH key for creating VSI
##############################################################################

resource "ibm_is_ssh_key" "ssh_key" {
  name       = "${var.prefix}-ssh-key"
  public_key = var.ssh_public_key
}

##############################################################################


##############################################################################
# Create VSI
##############################################################################

locals {
  # Convert list to map
  vsi_map = {
    for vsi_group in var.vsi :
    (vsi_group.name) => merge(vsi_group, {
      # Add VPC ID
      vpc_id = module.vpc[vsi_group.vpc_name].vpc_id
      subnets = [
        # Add subnets to list if they are contained in the subnet list, prepends prefixes
        for subnet in module.vpc[vsi_group.vpc_name].subnet_zone_list :
        subnet if contains([
          # Create modified list of names
          for name in vsi_group.subnet_names :
          "${var.prefix}-${vsi_group.vpc_name}-${name}"
        ], subnet.name)
      ]
    })
  }
}

module "vsi" {
  source            = "github.com/Cloud-Schematics/vsi-module.git"
  for_each          = local.vsi_map
  resource_group_id = data.ibm_resource_group.resource_group.id
  prefix            = each.value.name
  vpc_id            = module.vpc[each.value.vpc_name].vpc_id
  subnets           = each.value.subnets
  image             = each.value.image_name
  ssh_key_ids       = [ibm_is_ssh_key.ssh_key.id]
  machine_type      = each.value.machine_type
  vsi_per_subnet    = each.value.vsi_per_subnet
  security_group    = each.value.security_group
  load_balancers    = each.value.load_balancers
}

locals {
  vsi_list = flatten([
    for compute in module.vsi :
    compute.list
  ])
  instance_map = {
    for instance in local.vsi_list :
    (instance.name) => instance.ipv4_address
  }
}

resource "ibm_is_flow_log" "flow_logs" {
  for_each       = var.flow_logs.use ? local.instance_map : {}
  name           = "${each.key}-logs"
  target         = each.value
  active         = var.flow_logs.active
  storage_bucket = var.flow_logs.cos_bucket_name
  resource_group = data.ibm_resource_group.resource_group.id
}

##############################################################################
# Activity Tracker with COS 
##############################################################################
module "atracker" {
 //Uncomment link below line to make it point to registry level
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-atracker.git"
  #source = "../../terraform-ibm-atracker/"
  
  //source = "../.."

  resource_group = var.resource_group
  bucket_name    = var.bucket_name
  location       = var.region
  target_crn     = var.target_crn
  api_key        = var.ibmcloud_api_key
}
