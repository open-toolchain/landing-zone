##############################################################################
# Cluster Outputs
##############################################################################

output "clusters_map" {
  description = "Cluster Map for dynamic cluster creation"
  value       = local.clusters_map
}

output "worker_pools_map" {
  description = "Cluster worker pools map"
  value       = local.worker_pools_map
}

##############################################################################

##############################################################################
# COS Outputs
##############################################################################

output "cos_data_map" {
  description = "Map with key value pairs of name to instance if using data"
  value       = local.cos_data_map
}

output "cos_map" {
  description = "Map with key value pairs of name to instance if not using data"
  value       = local.cos_data_map
}

output "cos_instance_ids" {
  description = "Instance map for cloud object storage instance IDs"
  value       = local.cos_instance_ids
}

output "cos_bucket_list" {
  description = "List of all COS buckets with instance name added"
  value       = local.cos_bucket_list
}

output "cos_bucket_map" {
  description = "Map including key of bucket names with bucket data as values"
  value       = local.cos_bucket_map
}

output "cos_keys_list" {
  description = "List of all COS keys"
  value       = local.cos_keys_list
}

output "cos_key_map" {
  description = "Map of COS keys"
  value       = local.cos_key_map
}

output "bucket_to_instance_map" {
  description = "Maps bucket names to instance ids and api keys"
  value       = local.bucket_to_instance_map
}

##############################################################################

##############################################################################
# Main Outputs
##############################################################################

output "flow_logs_map" {
  description = "Map of flow logs instances to create"
  value       = local.flow_logs_map
}

output "vpc_map" {
  description = "VPC Map"
  value       = local.vpc_map
}

##############################################################################

##############################################################################
# Security Group Outputs
##############################################################################

output "security_group_map" {
  description = "Map of Security Group Components"
  value       = local.security_group_map
}

output "security_group_rule_list" {
  description = "List of all security group rules"
  value       = local.security_group_rule_list
}


output "security_group_rules_map" {
  description = "Map of all security group rules"
  value       = local.security_group_rules_map
}

##############################################################################

##############################################################################
# Service Authorization Outputs
##############################################################################

output "service_authorization_vpc_to_key_management" {
  description = "Service authorizations to allow server-protect to be encrypted by key management"
  value       = local.service_authorization_vpc_to_key_management
}

output "service_authorization_cos_to_key_management" {
  description = "Service authorizations to allow cos bucket to be encrypted by key management"
  value       = local.service_authorization_cos_to_key_management
}

output "service_authorization_flow_logs_to_cos" {
  description = "Service authorizations to allow flow logs to write in cos bucket"
  value       = local.service_authorization_flow_logs_to_cos
}

##############################################################################

##############################################################################
# VPE outputs
##############################################################################

output "vpe_services" {
  description = "Map of VPE services to be created. Currently only COS is supported."
  value       = local.vpe_services
}

output "vpe_gateway_list" {
  description = "List of gateways to be created"
  value       = local.vpe_gateway_list
}

output "vpe_gateway_map" {
  description = "Map of gateways to be created"
  value       = local.vpe_gateway_map
}

output "vpe_subnet_reserved_ip_list" {
  description = "List of reserved subnet ips for vpes"
  value       = local.vpe_subnet_reserved_ip_list
}

output "vpe_subnet_reserved_ip_map" {
  description = "Map of reserved subnet ips for vpes"
  value       = local.vpe_subnet_reserved_ip_map
}


##############################################################################

##############################################################################
# VPN Gateway Outputs
##############################################################################

output "vpn_gateway_map" {
  description = "Map of VPN Gateways with VPC data"
  value       = local.vpn_gateway_map
}

output "vpn_connection_list" {
  description = "List of VPN gateway connections"
  value       = local.vpn_connection_list
}

output "vpn_connection_map" {
  description = "Map of VPN gateway connections"
  value       = local.vpn_connection_map
}

##############################################################################


##############################################################################
# IAM Outputs
##############################################################################

output "access_groups_object" {
  description = "Convert access group list to map"
  value       = local.access_groups_object
}

output "access_policy_list" {
  description = "List of access policies"
  value       = local.access_policy_list
}

output "access_policies" {
  description = "Map of access policies"
  value       = local.access_policies
}

output "dynamic_rule_list" {
  description = "List of dynamic rules"
  value       = local.dynamic_rule_list
}

output "dynamic_rules" {
  description = "Map of dynamic rules"
  value       = local.dynamic_rules
}

output "account_management_list" {
  description = "List of account management policies for group"
  value       = local.account_management_list
}

output "account_management_map" {
  description = "Map of account management policies by group"
  value       = local.account_management_map
}

output "access_groups_with_invites" {
  description = "map of access groups with invite users"
  value       = local.access_groups_with_invites
}

##############################################################################

##############################################################################
# Bastion VSI Outputs
##############################################################################

output "bastion_vsi_map" {
  description = "Map of Bastion Host VSI deployments"
  value       = local.bastion_vsi_map
}

##############################################################################

##############################################################################
# App ID Outputs
##############################################################################

output "appid_redirect_urls" {
  description = "List of redirect urls from teleport VSI names"
  value       = local.appid_redirect_urls
}

##############################################################################

##############################################################################
# VSI Outputs
##############################################################################

output "vsi_map" {
  description = "Map of VSI deployments"
  value       = local.vsi_map
}

output "vsi_images_list" {
  description = "List of Images from VSI and Bastion VSI deployments"
  value       = local.vsi_images_list
}

output "vsi_images_map" {
  description = "Map of Images from VSI and Bastion VSI deployments"
  value       = local.vsi_images_map
}

output "ssh_keys" {
  description = "List of SSH keys with resource group ID added"
  value       = local.ssh_keys
}

##############################################################################

##############################################################################
# VSI Outputs
##############################################################################

output "f5_vsi_map" {
  description = "Map of VSI deployments"
  value       = local.f5_vsi_map
}

output "f5_template_map" {
  description = "Map of template data for f5 deployments"
  value       = module.f5_cloud_init
}

##############################################################################