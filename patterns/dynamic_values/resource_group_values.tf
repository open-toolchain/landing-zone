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