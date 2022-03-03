##############################################################################
# KMS Outputs
##############################################################################

output "kms_crn" {
  description = "CRN for KMS instance"
  value       = var.kms.use_data == true ? data.ibm_resource_instance.kms[0].crn : ibm_resource_instance.kms[0].crn
}

output "kms_guid" {
  description = "GUID for KMS instance"
  value       = local.kms_guid
}

##############################################################################


##############################################################################
# Key Rings
##############################################################################

output "key_rings" {
  description = "Key rings created by module"
  value       = ibm_kms_key_rings.rings
}

##############################################################################


##############################################################################
# Keys
##############################################################################

output "keys" {
  description = "List of names and ids for keys created."
  value = [
    for kms_key in var.kms_keys :
    {
      name = kms_key.name
      id   = ibm_kms_key.key[kms_key.name].id
      crn  = ibm_kms_key.key[kms_key.name].crn
    }
  ]
}

##############################################################################