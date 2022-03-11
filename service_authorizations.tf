##############################################################################
# Service To Service Authorization Policies
# > `target_resource_group_id` and `target_resource_instance_id` are mutually
#    exclusive. IAM will use the least specific of the two
##############################################################################

locals {
  authorization_policies = merge(
    {
      block-storage = {
        source_service_name         = "server-protect"
        description                 = "Allow block storage volumes to be encrypted by KMS instance"
        roles                       = ["Reader"]
        target_service_name         = "kms"
        target_resource_instance_id = module.key_protect.kms_guid
      }
      cos-to-kms = {
        source_service_name         = "cloud-object-storage"
        description                 = "Allow COS instance to read from KMS instance"
        roles                       = ["Reader"]
        target_service_name         = "kms"
        target_resource_instance_id = module.key_protect.kms_guid
      }
    },
    {
      # Create an authorization for each COS instance
      for instance in var.cos :
      "${instance.name}-flow-logs-cos" => {
        source_service_name         = "is"
        source_resource_type        = "flow-log-collector"
        description                 = "Allow flow logs write access  cloud object storage instance"
        roles                       = ["Writer"]
        target_service_name         = "cloud-object-storage"
        target_resource_instance_id = local.cos_instance_ids[instance.name]
      }
    }
  )
}

##############################################################################


##############################################################################
# Authorization Policies
##############################################################################

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