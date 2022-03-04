##############################################################################
# Key Protect
##############################################################################

module "key_protect" {
  source = "./kms"
  region = var.region
  kms = {
    name              = var.key_protect.name
    resource_group_id = var.key_protect.resource_group == null ? null : local.resource_groups[var.key_protect.resource_group]
    use_data          = var.key_protect.use_data
    use_hs_crypto     = var.keyprotect.use_hs_crypto == true ? "hs-crypto" : "kms"
  }
  kms_keys = var.key_protect.keys == null ? [] : var.key_protect.keys
}


##############################################################################
