##############################################################################
# Create KMS instance or get from data
##############################################################################

resource "ibm_resource_instance" "kms" {
  count             = var.key_management.use_data != true && var.key_management.use_hs_crypto != true ? 1 : 0
  name              = var.key_management.name
  service           = "kms"
  plan              = "tiered-pricing"
  location          = var.region
  resource_group_id = var.key_management.resource_group_id
}

data "ibm_resource_instance" "kms" {
  count             = var.key_management.use_data == true && var.key_management.use_hs_crypto != true ? 1 : 0
  name              = var.key_management.name
  resource_group_id = var.key_management.resource_group_id
}

data "ibm_hpcs" "hpcs_instance" {
  count             = var.key_management.use_hs_crypto == true ? 1 : 0
  name              = var.key_management.name
  resource_group_id = var.key_management.resource_group_id
}

locals {
  key_management_guid = var.key_management.use_hs_crypto == true ? data.ibm_hpcs.hpcs_instance[0].guid : var.key_management.use_data == null ? ibm_resource_instance.kms[0].guid : data.ibm_resource_instance.kms[0].guid
  key_management_keys = {
    for encryption_key in var.keys :
    (encryption_key.name) => encryption_key
  }
  key_rings = distinct([
    for encryption_key in var.keys :
    encryption_key.key_ring if encryption_key.key_ring != null
  ])
  key_management_key_policies = {
    for encryption_key in var.keys :
    (encryption_key.name) => encryption_key if encryption_key.policies != null
  }
}

##############################################################################


##############################################################################
# Create Key Rings
##############################################################################

resource "ibm_kms_key_rings" "rings" {
  for_each    = toset(local.key_rings)
  instance_id = local.key_management_guid
  key_ring_id = each.key
}

##############################################################################


##############################################################################
# Create Keys
##############################################################################

resource "ibm_kms_key" "key" {
  for_each        = local.key_management_keys
  instance_id     = local.key_management_guid
  key_name        = each.value.name
  standard_key    = each.value.root_key == null ? null : !each.value.root_key
  payload         = each.value.payload
  key_ring_id     = each.value.key_ring == null ? null : ibm_kms_key_rings.rings[each.value.key_ring].key_ring_id
  force_delete    = each.value.force_delete != false ? true : each.value.force_delete
  endpoint_type   = each.value.endpoint
  iv_value        = each.value.iv_value
  encrypted_nonce = each.value.encrypted_nonce
}

##############################################################################


##############################################################################
# Create Key Policies
##############################################################################

resource "ibm_kms_key_policies" "key_policy" {
  for_each      = local.key_management_key_policies
  instance_id   = local.key_management_guid
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

