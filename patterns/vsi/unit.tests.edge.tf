##############################################################################
# Unit Tests
##############################################################################


##############################################################################
# VPC Values
##############################################################################

locals {
  vpc_list_length                        = regex("3", tostring(length(module.edge_unit_tests.vpc_list)))
  vpc_list_append_edge                   = regex("edge", module.edge_unit_tests.vpc_list[0])
  vpc_correct_edge_address_prefix_zone_1 = regex("10.5.0.0/16", module.edge_unit_tests.vpc_use_edge_prefixes["edge"]["zone-1"][0])
  vpc_correct_management_prefix_zone_1   = regex("0", tostring(length(module.edge_unit_tests.vpc_use_edge_prefixes["management"]["zone-1"])))
  vpc_correct_vpn_tier_management_zone_1 = regex("vpn", module.edge_unit_tests.vpc_subnet_tiers["management"]["zone-1"][2])
  vpc_create_vpn                         = regex("management-gateway", module.edge_unit_tests.vpn_gateways[0].name)
  create_f5_sgs                          = regex("3", tostring(length(module.edge_unit_tests.security_groups)))
  vpc_no_public_gateways = regex("false", tostring(
    distinct([
      for zone in [1, 2, 3] :
      # for each zone make sure false
      module.edge_unit_tests.vpcs[0].use_public_gateways["zone-${zone}"]
    ])[0]
  ))
}

##############################################################################

##############################################################################
# Resource Group Values
##############################################################################

locals {
  hs_crypto_resource_group       = regex("test", module.edge_unit_tests.hs_cypto_rg[0])
  app_id_resource_group          = regex("test-appid-rg", module.edge_unit_tests.appid_rg[0])
  list_contains_all_rg           = regex("4", tostring(length(module.edge_unit_tests.resource_group_list)))
  dynamic_list_contains_all_rg   = regex("4", tostring(length(module.edge_unit_tests.dynamic_rg_list)))
  dynamic_resource_group_created = regex("true", tostring(module.edge_unit_tests.resource_groups[5].create))
}

##############################################################################

##############################################################################
# F5 Values
##############################################################################

locals {
  f5_tier_length_is_6                         = regex("6", tostring(length(module.edge_unit_tests.f5_tiers)))
  f5_no_bastion_sg_rules_length_match_default = regex(tostring(length(module.edge_unit_tests.default_vsi_sg_rules)), tostring(length(module.edge_unit_tests.f5_security_groups["f5-management"].rules)))
  f5_three_instances                          = regex("3", tostring(length(module.edge_unit_tests.f5_deployments)))
}

##############################################################################

##############################################################################
# Teleport Values
##############################################################################

locals {
  bastion_empty_array          = regex("0", tostring(length(module.edge_unit_tests.bastion_zone_list)))
  bastion_resource_empty_array = regex("0", tostring(length(module.edge_unit_tests.bastion_resource_list)))
  bastion_gatways_false        = regex("false", tostring(module.edge_unit_tests.bastion_gateways["zone-1"]))
  no_teleport_vsi              = regex("0", tostring(length(module.edge_unit_tests.teleport_vsi)))
}

##############################################################################

##############################################################################
# Object Storage Values
##############################################################################

locals {
  edge_bucket_created = regex("edge-bucket", module.edge_unit_tests.object_storage[1].buckets[0].name)
  only_three_buckets  = regex("3", tostring(length(module.edge_unit_tests.object_storage[1].buckets)))
  no_bastion_key      = regex("0", tostring(length(module.edge_unit_tests.object_storage[1].keys)))
}

##############################################################################

##############################################################################
# Key Management Values
##############################################################################

locals {
  use_hs_crypto_true = regex("true", tostring(module.edge_unit_tests.key_management.use_hs_crypto))
  use_hs_crypto_rg   = regex("test", tostring(module.edge_unit_tests.key_management.resource_group))
}

##############################################################################