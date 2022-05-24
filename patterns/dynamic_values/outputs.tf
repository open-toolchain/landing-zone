##############################################################################
# Outputs
##############################################################################

output "default_vsi_sg_rules" {
  description = "Default rules added to VSI security groups"
  value       = local.default_vsi_sg_rules
}

##############################################################################

##############################################################################
# Bastion / Teleport Outputs
##############################################################################

output "bastion_zone_list" {
  description = "List of zones where teleport will be provisoned"
  value       = local.bastion_zone_list
}

output "bastion_resource_list" {
  description = "Returns an empty array or an array of \"bastion\" when bastion resources are created"
  value       = local.bastion_resource_list
}

output "bastion_gateways" {
  description = "List of public gateways to use in bastion vpc."
  value       = local.bastion_gateways
}

output "teleport_vsi" {
  description = "List of teleport VSI to create using landing zone module"
  value       = local.teleport_vsi
}

##############################################################################

##############################################################################
# Object Storage Outputs
##############################################################################

output "object_storage" {
  description = "List of object storage instances and buckets"
  value       = local.object_storage
}

##############################################################################


##############################################################################
# F5 Outputs
##############################################################################

output "f5_tiers" {
  description = "List of subnet to provision in VPC where F5 is enabled"
  value       = local.f5_tiers
}

output "f5_security_groups" {
  description = "Map of security groups and rules for each F5 interface"
  value       = local.f5_security_groups
}

output "f5_deployments" {
  description = "List of F5 deployments for landing-zone module"
  value       = local.f5_deployments
}

##############################################################################


##############################################################################
# Resource Group Outputs
##############################################################################

output "hs_cypto_rg" {
  description = "List of resource groups for hs_crypto. Can be array of one element."
  value       = local.hs_crypto_rg
}

output "appid_rg" {
  description = "List of resource groups for hs_crypto. Can be array of one element."
  value       = local.appid_rg
}

output "resource_group_list" {
  description = "List of resource groups"
  value       = local.resource_group_list
}

output "dynamic_rg_list" {
  description = "List of resource groups for dynamic creation of resources"
  value       = local.dynamic_rg_list
}

output "resource_groups" {
  description = "List of resource groups transformed to use as landing zone configuration"
  value       = local.resource_groups
}

##############################################################################


##############################################################################
# VPC Value Outputs
##############################################################################

output "vpc_list" {
  description = "List of VPCs, used for adding Edge VPC"
  value       = local.vpc_list
}

output "vpc_use_edge_prefixes" {
  description = "Map of vpc network and zones with needed address prefixes."
  value       = local.vpc_use_edge_prefixes
}

output "vpc_subnet_tiers" {
  description = "map of vpcs and zone with list of expected subnet tiers in each zone"
  value       = local.vpc_subnet_tiers
}

output "vpcs" {
  description = "List of VPCs with needed information to be created by landing zone module"
  value       = local.vpcs
}

output "security_groups" {
  description = "List of additional security groups to be created by landing-zone module"
  value       = local.security_groups
}

##############################################################################

##############################################################################
# VPN Gateway Outputs
##############################################################################

output "vpn_gateways" {
  description = "List of gateways for landing zone module"
  value       = local.vpn_gateways
}

##############################################################################