##############################################################################
# Create VPCs
##############################################################################

locals {
  # Convert VPC List to Map
  vpc_map = {
    for vpc_network in var.vpcs :
    (vpc_network.prefix) => vpc_network
  }
}

module "vpc" {
  source   = "./vpc"
  for_each = local.vpc_map

  resource_group_id           = each.value.resource_group == null ? null : local.resource_groups[each.value.resource_group]
  region                      = var.region
  prefix                      = "${var.prefix}-${each.value.prefix}"
  vpc_name                    = "vpc"
  classic_access              = each.value.classic_access
  use_manual_address_prefixes = each.value.use_manual_address_prefixes
  default_network_acl_name    = each.value.default_network_acl_name
  default_security_group_name = each.value.default_security_group_name
  security_group_rules        = each.value.default_security_group_rules
  default_routing_table_name  = each.value.default_routing_table_name
  address_prefixes            = each.value.address_prefixes
  network_acls                = each.value.network_acls
  use_public_gateways         = each.value.use_public_gateways
  subnets                     = each.value.subnets
}


##############################################################################


##############################################################################
# Add VPC to Flow Logs
##############################################################################

resource "ibm_is_flow_log" "flow_logs" {
  for_each = {
    # For each network
    for vpc_network in var.vpcs :
    # Create a map containing the bucket name, id, and resource group if flow logs bucket name provided
    (vpc_network.prefix) => {
      vpc_id         = module.vpc[vpc_network.prefix].vpc_id
      bucket         = ibm_cos_bucket.buckets[vpc_network.flow_logs_bucket_name].bucket_name
      resource_group = vpc_network.resource_group == null ? null : local.resource_groups[vpc_network.resource_group]
    } if vpc_network.flow_logs_bucket_name != null
  }
  name           = "${each.key}-logs"
  target         = each.value.vpc_id
  active         = true
  storage_bucket = each.value.bucket
  resource_group = each.value.resource_group

  depends_on = [ibm_cos_bucket.buckets, ibm_iam_authorization_policy.policy]
}

##############################################################################
