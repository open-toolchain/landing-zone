##############################################################################
# Unit Tests
##############################################################################


##############################################################################
# VPC Values
##############################################################################

locals {
  f5_mgmt_vpc_list_length                          = regex("2", tostring(length(module.f5_on_management.vpc_list)))
  f5_mgmt_vpc_correct_mgmt_address_prefix_zone_1   = regex("10.5.0.0/16", module.f5_on_management.vpc_use_edge_prefixes["management"]["zone-1"][0])
  f5_mgmt_vpc_correct_mgmt_address_prefix_zone_1_2 = regex("10.10.10.0/24", module.f5_on_management.vpc_use_edge_prefixes["management"]["zone-1"][1])
  f5_mgmt_vpc_correct_management_prefix_zone_1     = regex("2", tostring(length(module.f5_on_management.vpc_use_edge_prefixes["management"]["zone-1"])))
  f5_mgmt_create_f5_sgs                            = regex("5", tostring(length(module.f5_on_management.security_groups)))
  f5_mgmt_vpc_no_public_gateways = regex("true", tostring(
    distinct([
      for zone in [1, 2, 3] :
      # for each zone make sure false
      module.f5_on_management.vpcs[0].use_public_gateways["zone-${zone}"]
    ])[0]
  ))
}

##############################################################################

##############################################################################
# Resource Group Values
##############################################################################

locals {
  f5_mgmt_hs_crypto_resource_group       = regex("test", module.f5_on_management.hs_cypto_rg[0])
  f5_mgmt_app_id_resource_group          = regex("test-appid-rg", module.f5_on_management.appid_rg[0])
  f5_mgmt_list_contains_all_rg           = regex("4", tostring(length(module.f5_on_management.resource_group_list)))
  f5_mgmt_dynamic_list_contains_all_rg   = regex("4", tostring(length(module.f5_on_management.dynamic_rg_list)))
  f5_mgmt_dynamic_resource_group_created = regex("true", tostring(module.f5_on_management.resource_groups[5].create))
}

##############################################################################

##############################################################################
# F5 Values
##############################################################################

locals {
  f5_mgmt_f5_tier_length_is_6 = regex("8", tostring(length(module.f5_on_management.f5_tiers)))
  f5_mgmt_f5_three_instances  = regex("3", tostring(length(module.f5_on_management.f5_deployments)))
}

##############################################################################

##############################################################################
# Teleport Values
##############################################################################

locals {
  f5_mgmt_bastion_array     = regex("3", tostring(length(module.f5_on_management.bastion_zone_list)))
  f5_mgmt_bastion_resource  = regex("bastion", module.f5_on_management.bastion_resource_list[0])
  f5_mgmt_bastion_gatways_1 = regex("true", tostring(module.f5_on_management.bastion_gateways["zone-1"]))
  f5_mgmt_bastion_gatways_2 = regex("true", tostring(module.f5_on_management.bastion_gateways["zone-2"]))
  f5_mgmt_bastion_gatways_3 = regex("true", tostring(module.f5_on_management.bastion_gateways["zone-3"]))
  f5_mgmt_teleport_vsi      = regex("3", tostring(length(module.f5_on_management.teleport_vsi)))
}

##############################################################################

##############################################################################
# Object Storage Values
##############################################################################

locals {
  f5_mgmt_bastion_bucket = regex("bastion-bucket", module.f5_on_management.object_storage[1].buckets[2].name)
  f5_mgmt_bastion_key    = regex("1", tostring(length(module.f5_on_management.object_storage[1].keys)))
}

##############################################################################

##############################################################################
# Key Management Values
##############################################################################

locals {
  f5_mgmt_use_hs_crypto_true = regex("true", tostring(module.f5_on_management.key_management.use_hs_crypto))
  f5_mgmt_use_hs_crypto_rg   = regex("test", tostring(module.f5_on_management.key_management.resource_group))
}

##############################################################################