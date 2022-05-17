##############################################################################
# Key Management Values
##############################################################################

locals {
  key_management = {
    name           = var.hs_crypto_instance_name == null ? "${var.prefix}-slz-kms" : var.hs_crypto_instance_name
    resource_group = var.hs_crypto_resource_group == null ? "${var.prefix}-service-rg" : var.hs_crypto_resource_group
    use_hs_crypto  = var.hs_crypto_instance_name == null ? false : true
    keys = [
      # Create encryption keys for landing zone, activity tracker, and vsi boot volume
      for service in ["slz", "atracker", "vsi-volume", "roks"] :
      {
        name     = "${var.prefix}-${service}-key"
        root_key = true
        key_ring = "${var.prefix}-slz-ring"
      }
    ]
  }
}

##############################################################################

##############################################################################
# Key Management Outputs
##############################################################################

output "key_management" {
  description = "Key management map for landing zone"
  value       = local.key_management
}

##############################################################################