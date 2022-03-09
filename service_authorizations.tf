##############################################################################
# Service To Service Authorization Policies
##############################################################################

locals {
  authorization_policies = {
    block-storage = {
      source_service_name         = "server-protect"
      description                 = "Allow KMS to access block storage volumes"
      roles                       = ["Reader"]
      target_service_name         = "kms"
      target_resource_instance_id = module.key_management.kms_guid
    },
    cos-to-kms = {
      source_service_name         = "cloud-object-storage"
      description                 = "Allow KMS to access cloud object storage"
      roles                       = ["Reader"]
      target_service_name         = "kms"
      target_resource_instance_id = module.key_management.kms_guid
    },
    flow-logs-cos = {
      source_service_name         = "is"
      source_resource_type        = "flow-log-collector"
      description                 = "Allow flow logs to access cloud object storage"
      roles                       = ["Writer"]
      target_service_name         = "cloud-object-storage"
      target_resource_instance_id = local.cos_instance_id
      target_resource_group_id    = local.resource_groups[var.cos.resource_group]
    }
  }
}

resource "ibm_iam_authorization_policy" "policy" {
  for_each = local.authorization_policies

  source_service_name         = each.value.source_service_name
  source_resource_type        = lookup(each.value, "source_resource_type", null)
  source_resource_instance_id = lookup(each.value, "source_resource_instance_id", null)
  source_resource_group_id    = lookup(each.value, "source_resource_group_id", null)

  target_service_name         = each.value.target_service_name
  target_resource_instance_id = lookup(each.value, "target_resource_instance_id", null)
  target_resource_group_id    = lookup(each.value, "target_resource_group", null)
  roles                       = each.value.roles
  description                 = each.value.description
}


##############################################################################
