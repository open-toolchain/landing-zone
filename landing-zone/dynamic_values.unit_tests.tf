##############################################################################
# Cluster Unit Tests
##############################################################################

locals {
  actual_clusters_map                          = module.unit_tests.clusters_map
  actual_worker_pools_map                      = module.unit_tests.worker_pools_map
  assert_cluster_map_correct_name              = lookup(local.actual_clusters_map, "ut-test-cluster")
  assert_cluster_map_correct_vpc_id            = regex("1234", local.actual_clusters_map["ut-test-cluster"].vpc_id)
  assert_cluster_map_correct_cos_crn           = regex("5678", local.actual_clusters_map["ut-test-cluster"].cos_instance_crn)
  assert_cluster_map_correct_subnet_number     = regex("2", tostring(length(local.actual_clusters_map["ut-test-cluster"].subnets)))
  assert_cluster_map_has_subnet_1              = lookup(local.mock_cluster_map_subnet_map, "ut-test-subnet-1")
  assert_cluster_map_has_subnet_3              = lookup(local.mock_cluster_map_subnet_map, "ut-test-subnet-3")
  assert_worker_pool_correct_name              = lookup(local.actual_worker_pools_map, "ut-test-cluster-logging-worker-pool")
  assert_worker_pool_correct_vpc_id            = regex("1234", local.actual_worker_pools_map["ut-test-cluster-logging-worker-pool"].vpc_id)
  assert_worker_pool_has_correct_subnet_number = regex("2", tostring(length(local.actual_worker_pools_map["ut-test-cluster-logging-worker-pool"].subnets)))
  assert_worker_pool_has_has_subnet_1          = lookup(local.mock_worker_pool_map_subnet_map, "ut-test-subnet-1")
  assert_worker_pool_has_has_subnet_3          = lookup(local.mock_worker_pool_map_subnet_map, "ut-test-subnet-3")
  assert_worker_pool_has_os_parent_entitlement = regex("cloud_pak", local.actual_worker_pools_map["ut-test-cluster-logging-worker-pool"].entitlement)
}

##############################################################################

##############################################################################
# COS Unit Tests
##############################################################################

locals {
  assert_cos_instance_returned                 = lookup(module.unit_tests.cos_instance_ids, "test-cos")
  assert_cos_data_instance_returned            = lookup(module.unit_tests.cos_instance_ids, "data-cos")
  assert_cos_instance_id_correct               = regex(":::::::1234", module.unit_tests.cos_instance_ids["test-cos"])
  assert_cos_data_instance_id_correct          = regex(":::::::5678", module.unit_tests.cos_instance_ids["data-cos"])
  assert_instance_name_added_to_bucket_in_list = regex("data-cos", module.unit_tests.cos_bucket_list[0].instance)
  assert_bucket_key_exists_in_map              = lookup(module.unit_tests.cos_bucket_map, "create-bucket")
  assert_instance_name_added_to_key_in_list    = regex("data-cos", module.unit_tests.cos_keys_list[0].instance)
  assert_key_exists_in_map                     = lookup(module.unit_tests.cos_key_map, "data-bucket-key")
  assert_bucket_exists_in_instance_map         = lookup(module.unit_tests.bucket_to_instance_map, "data-bucket")
  assert_bucket_contains_correct_api_key       = regex("1234", module.unit_tests.bucket_to_instance_map["data-bucket"].bind_key)
  assert_cos_keys_map_contains_HMAC_key        = regex(module.unit_tests.cos_key_map["teleport-key"].parameters.HMAC, true)
  assert_cos_keys_list_contains_HMAC_key       = regex(true, module.unit_tests.cos_keys_list[1].parameters.HMAC)
}

##############################################################################

##############################################################################
# Main Unit Tests
##############################################################################

locals {
  assert_flow_logs_map_contains_instance   = lookup(module.unit_tests.flow_logs_map, "test")
  assert_flow_logs_instance_correct_vpc_id = regex("1234", module.unit_tests.flow_logs_map["test"].vpc_id)
  assert_flow_logs_instance_correct_rg     = regex("test-rg", module.unit_tests.flow_logs_map["test"].resource_group)
  assert_flow_logs_bucket_has_prefix       = regex("ut-bucket", module.unit_tests.flow_logs_map["test"].bucket)
  assert_no_flow_logs_if_no_bucket         = regex("1", tostring(length(keys(module.unit_tests.flow_logs_map))))
  assert_vpc_map_contains_vpc              = lookup(module.unit_tests.vpc_map, "test")
}

##############################################################################

##############################################################################
# Service Authorization Unit Tests
##############################################################################

locals {
  assert_rg_found_vpc_to_key_management            = lookup(module.unit_tests.service_authorization_vpc_to_key_management, "block-storage")
  assert_vpc_with_null_rg_does_not_create_auth     = regex("1", tostring(length(keys(module.unit_tests.service_authorization_vpc_to_key_management))))
  assert_correct_target_id_vpc_to_key_management   = regex("12KEY", module.unit_tests.service_authorization_vpc_to_key_management["block-storage"].target_resource_instance_id)
  assert_correct_target_name_vpc_to_key_management = regex("kms", module.unit_tests.service_authorization_vpc_to_key_management["block-storage"].target_service_name)
  assert_cos_found_cos_to_key_management           = lookup(module.unit_tests.service_authorization_cos_to_key_management, "cos-data-cos-to-key-management")
  assert_correct_target_id_cos_to_key_management   = regex("12KEY", module.unit_tests.service_authorization_cos_to_key_management["cos-data-cos-to-key-management"].target_resource_instance_id)
  assert_correct_target_name_cos_to_key_management = regex("kms", module.unit_tests.service_authorization_cos_to_key_management["cos-data-cos-to-key-management"].target_service_name)
  assert_correct_guid_cos_to_key_management        = regex("5678", module.unit_tests.service_authorization_cos_to_key_management["cos-data-cos-to-key-management"].source_resource_instance_id)
  assert_cos_found_flow_logs_to_cos                = lookup(module.unit_tests.service_authorization_flow_logs_to_cos, "flow-logs-test-cos-cos")
  assert_cos_id_flow_logs_to_cos                   = regex("1234", module.unit_tests.service_authorization_flow_logs_to_cos["flow-logs-test-cos-cos"].target_resource_instance_id)
}

##############################################################################

##############################################################################
# Security Group Unit Tests
##############################################################################

locals {
  assert_security_group_found_in_map       = lookup(module.unit_tests.security_group_map, "test-sg")
  assert_security_group_rule_found_in_list = regex("test-rule", module.unit_tests.security_group_rule_list[0].name)
  assert_security_group_rule_found_in_map  = lookup(module.unit_tests.security_group_rules_map, "test-sg-test-rule")
}

##############################################################################

##############################################################################
# VSI Unit Tests
##############################################################################

locals {
  assert_vsi_group_exits_in_map        = lookup(module.unit_tests.vsi_map, "ut-vsi")
  assert_vsi_group_vpc_correct_id      = regex("1234", module.unit_tests.vsi_map["ut-vsi"].vpc_id)
  assert_vsi_map_correct_subnet_number = regex("2", tostring(length(module.unit_tests.vsi_map["ut-vsi"].subnets)))
  assert_vsi_map_has_subnet_2          = lookup(local.mock_vsi_map_subnet_map, "ut-test-subnet-2")
  assert_vsi_map_has_subnet_4          = lookup(local.mock_vsi_map_subnet_map, "ut-test-subnet-4")
  assert_ssh_key_has_resource_group_id = regex("2345", module.unit_tests.ssh_keys[0].resource_group_id)
}

##############################################################################


##############################################################################
# VPE Unit Tests
##############################################################################

locals {
  assert_vpe_exists_in_map                                   = lookup(module.unit_tests.vpe_services, "test-cos-cloud-object-storage")
  assert_vpe_has_correct_crn                                 = regex("crn:v1:bluemix:public:cloud-object-storage:global:::endpoint:s3.direct.${var.region}.cloud-object-storage.appdomain.cloud", module.unit_tests.vpe_services["test-cos-cloud-object-storage"].crn)
  assert_vpe_has_correct_id                                  = regex("crn:v1:bluemix:public:cloud-object-storage:global:::endpoint:s3.direct.${var.region}.cloud-object-storage.appdomain.cloud", module.unit_tests.vpe_services["test-cos-cloud-object-storage"].crn)
  assert_vpe_gateway_list_contains_vpc                       = regex("test-test-cos", module.unit_tests.vpe_gateway_list[0].name)
  assert_vpe_gateway_map_contains_gateway                    = lookup(module.unit_tests.vpe_gateway_map, "test-test-cos")
  assert_vpe_gateway_correct_vpc_id                          = regex("1234", module.unit_tests.vpe_gateway_map["test-test-cos"].vpc_id)
  assert_vpe_gateway_correct_service_crn                     = regex("crn:v1:bluemix:public:cloud-object-storage:global:::endpoint:s3.direct.${var.region}.cloud-object-storage.appdomain.cloud", module.unit_tests.vpe_gateway_map["test-test-cos"].crn)
  assert_vpe_subnet_reserved_ip_list_contains_ip             = regex("test-test-cos-gateway-vpe-zone-1-ip", module.unit_tests.vpe_subnet_reserved_ip_list[0].ip_name)
  assert_vpe_subnet_reserved_ip_map_contains_ip              = lookup(module.unit_tests.vpe_subnet_reserved_ip_map, "test-test-cos-gateway-vpe-zone-1-ip")
  assert_vpe_subnet_reserved_ip_map_has_correct_gateway_name = regex("test-test-cos", module.unit_tests.vpe_subnet_reserved_ip_map["test-test-cos-gateway-vpe-zone-1-ip"].gateway_name)
  assert_vpe_subnet_reserved_ip_map_has_correct_subnet_id    = regex("vpe-id", module.unit_tests.vpe_subnet_reserved_ip_map["test-test-cos-gateway-vpe-zone-1-ip"].id)
}

##############################################################################


##############################################################################
# VPN Unit Tests
##############################################################################

locals {
  assert_vpn_gateway_exists_in_map            = lookup(module.unit_tests.vpn_gateway_map, "test-gateway")
  assert_vpn_gateway_correct_vpc_id           = regex("1234", module.unit_tests.vpn_gateway_map["test-gateway"].vpc_id)
  assert_vpn_gateway_correct_subnet_id        = regex("vpn-id", module.unit_tests.vpn_gateway_map["test-gateway"].subnet_id)
  assert_vpn_connection_exists_in_list        = regex("test-gateway-connection-1", module.unit_tests.vpn_connection_list[0].connection_name)
  assert_vpn_connection_correct_gateway_name  = regex("ut-test-gateway", module.unit_tests.vpn_connection_map["test-gateway-connection-1"].gateway_name)
  assert_vpn_connection_correct_preshared_key = regex("preshared_key", module.unit_tests.vpn_connection_map["test-gateway-connection-1"].preshared_key)
}

##############################################################################


##############################################################################
# Bastion Host Unit Tests
##############################################################################

locals {
  assert_bastion_return_correct_amount_of_subnets = regex("1", tostring(length(module.unit_tests.bastion_template_data_list)))
  assert_bastion_return_correct_template_name     = regex("ut-teleport-ut-test-subnet-1", module.unit_tests.bastion_template_data_list[0].name)
  assert_template_found_in_template_map           = lookup(module.unit_tests.bastion_template_data_map, "ut-teleport-ut-test-subnet-1")
}

##############################################################################


##############################################################################
# IAM Unit Tests
##############################################################################

locals {
  assert_access_group_convert_to_object           = lookup(module.unit_tests.access_groups_object, "ut-test")
  assert_access_group_policy_has_group_name       = regex("ut-test", module.unit_tests.access_policy_list[0].group)
  assert_access_group_policy_map_has_policy       = lookup(module.unit_tests.access_policies, "policy")
  assert_dynamic_rule_has_group_name              = regex("ut-test", module.unit_tests.dynamic_rule_list[0].group)
  assert_dynamic_rule_map_has_policy              = lookup(module.unit_tests.dynamic_rules, "dynamic-policy")
  assert_account_management_list_has_group_name   = regex("ut-test", module.unit_tests.account_management_list[0].group)
  assert_access_groups_with_invite_contains_group = lookup(module.unit_tests.access_groups_with_invites, "ut-test")
}

##############################################################################


##############################################################################
# App Id Unit Tests
##############################################################################

locals {
  assert_appid_instance_contains_redirect_url = regex("https://ut-teleport.yes:3080/v1/webapi/oidc/callback", module.unit_tests.appid_redirect_urls[0])
}

##############################################################################


##############################################################################
# F5 Unit Tests
##############################################################################

locals {
  assert_subnets_correct_list           = regex("ut-test-subnet-1", module.unit_tests.f5_vsi_map["ut-f5-zone-1"].subnets[0].name)
  assert_correct_subnet_length          = regex("1", tostring(length(module.unit_tests.f5_vsi_map["ut-f5-zone-1"].subnets)))
  assert_secondary_subnets_correct_list = regex("ut-test-subnet-f5-1", module.unit_tests.f5_vsi_map["ut-f5-zone-1"].secondary_subnets[0].name)
  assert_correct_zone                   = regex("1-zone", module.unit_tests.f5_vsi_map["ut-f5-zone-1"].zone)
  assert_template_rendered_for_vsi      = lookup(module.unit_tests.f5_template_map, "ut-f5-zone-1")
  assert_template_reges                 = regex("#cloud-config\nchpasswd:\n  expire: false\n  list: |\n    admin:frog\ntmos_dhcpv4_tmm:\n  enabled: true\n  rd_enabled: false\n  icontrollx_trusted_sources: false\n  inject_routes: true\n  configsync_interface: 1.1\n  default_route_interface: 1.2\n  dhcp_timeout: 120\n  dhcpv4_options:\n    mgmt:\n      host-name: f5-ve-01\n      domain-name: f5-ve-01\n    '1.2':\n      routers: 10.0.0.1\n  do_enabled: true \n  do_declaration: null\n  do_declaration_url: null\n  do_declaration_url_headers:\n    PRIVATE-TOKEN: x6VpQuWhiT_KgT3mzyTe\n  do_template_variables:\n    primary_dns: 8.8.8.8\n    secondary_dns: 1.1.1.1\n    timezone: Europe/Paris\n    primary_ntp: 132.163.96.5\n    secondary_ntp: 132.163.97.5\n    primary_radius: 10.20.22.20\n    primary_radius_secret: testing123\n    secondary_radius: 10.20.23.20\n    secondary_radius_secret: testing123\n  as3_enabled: true\n  as3_declaration_url: null\n  as3_declaration_url_headers:\n    PRIVATE-TOKEN: x6VpQuWhiT_KgT3mzyTe\n  as3_template_variables:\n    selfip_snat_address: 10.20.40.40\n  ts_enabled: true\n  ts_declaration_url: null\n  ts_declaration_url_headers:\n    PRIVATE-TOKEN: x6VpQuWhiT_KgT3mzyTe\n  ts_template_variables:\n    splunk_log_ingest: 10.20.23.30\n    splunk_password: 0f29e5dc-bee8-4898-9054-9b66574a3e14\n  phone_home_url: null\n  phone_home_url_verify_tls: false\n  phone_home_url_metadata:\n    template_source: f5devcentral/ibmcloud_schematics_bigip_multinic_declared\n    template_version: 20210201\n    zone: 1-zone\n    vpc: 1234\n    app_id: null\n  tgactive_url: \n  tgstandby_url: null\n  tgrefresh_url: null\n  ", module.unit_tests.f5_template_map["ut-f5-zone-1"].user_data)
}

##############################################################################