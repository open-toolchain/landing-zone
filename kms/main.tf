##############################################################################
# Create KMS instance or get from data
##############################################################################

resource "ibm_resource_instance" "kms" {
  count             = var.kms.use_instance == true ? 0 : 1
  name              = var.kms.name
  service           = (var.kms_service == "keyprotect" ? "kms" : "hs-crypto")
  plan              = "tiered-pricing"
  location          = var.region
  resource_group_id = var.kms.resource_group_id
}

data "ibm_resource_instance" "kms" {
  count             = var.kms.use_instance == true ? 1 : 0
  name              = var.kms.name
  resource_group_id = var.kms.resource_group_id
}

locals {
  kms_guid = var.kms.use_instance == true ? data.ibm_resource_instance.kms[0].guid : ibm_resource_instance.kms[0].guid
  kms_keys = {
    for kms_key in var.kms_keys :
    (kms_key.name) => kms_key
  }
  key_rings = distinct([
    for kms_key in var.kms_keys :
    kms_key.key_ring if kms_key.key_ring != null
  ])
  kms_key_policies = {
    for kms_key in var.kms_keys :
    (kms_key.name) => kms_key if kms_key.policies != null
  }
}

##############################################################################


##############################################################################
# Create Key Rings
##############################################################################

resource "ibm_kms_key_rings" "rings" {
  for_each    = toset(local.key_rings)
  instance_id = local.kms_guid
  key_ring_id = each.key
}

##############################################################################


##############################################################################
# Create Keys
##############################################################################

resource "ibm_kms_key" "key" {
  for_each        = local.kms_keys
  instance_id     = local.kms_guid
  key_name        = each.value.name
  standard_key    = each.value.root_key == null ? null : !each.value.root_key
  payload         = each.value.payload
  key_ring_id     = each.value.key_ring == null ? null : ibm_kms_key_rings.rings[each.value.key_ring].key_ring_id
  force_delete    = each.value.force_delete
  endpoint_type   = each.value.endpoint
  iv_value        = each.value.iv_value
  encrypted_nonce = each.value.encrypted_nonce
}

##############################################################################


##############################################################################
# Create Key Policies
##############################################################################

resource "ibm_kms_key_policies" "key_policy" {
  for_each      = local.kms_key_policies
  instance_id   = local.kms_guid
  endpoint_type = each.value.endpoint
  key_id        = ibm_kms_key.key[each.key].key_id
  # Dynamically create rotation block
  dynamic "rotation" {
    for_each = (each.value.policies.rotation == null ? [] : [each.value])
    content {
      interval_month = each.value.policies.rotation.interval_month
    }
  }
  dynamic "dual_auth_delete" {
    for_each = (each.value.policies.dual_auth_delete == null ? [] : [each.value])
    content {
      enabled = each.value.policies.dual_auth_delete.enabled
    }
  }
}

##############################################################################

