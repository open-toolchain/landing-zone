##############################################################################
# Values used in Resource Group configuration
##############################################################################

locals {

  # Reference to create an array containing value if not null
  # Future resource groups from data should use this as a template
  hs_crypto_rg = var.hs_crypto_resource_group == null ? [] : [var.hs_crypto_resource_group]
  appid_rg     = var.appid_resource_group == null ? [] : [var.appid_resource_group]

  # List of resource groups used by default
  resource_group_list = flatten([
    ["Default", "service"],
    local.hs_crypto_rg,
    local.appid_rg
  ])

  # Create reference list
  dynamic_rg_list = flatten([
    [
      "Default",
      "default",
    ],
    local.hs_crypto_rg,
    local.appid_rg
  ])

  # resource_groups
  resource_groups = [
    for group in distinct(concat(local.resource_group_list, local.vpc_list)) :
    {
      name   = contains(local.dynamic_rg_list, group) ? group : "${var.prefix}-${group}-rg"
      create = contains(local.dynamic_rg_list, group) ? false : true
    }
  ]
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