##############################################################################
# Service To Service Authorization Policies
# > `target_resource_group_id` and `target_resource_instance_id` are mutually
#    exclusive. IAM will use the least specific of the two
##############################################################################

locals {
  authorization_policies = merge(
    module.dynamic_values.service_authorization_vpc_to_key_management,
    module.dynamic_values.service_authorization_cos_to_key_management,
    module.dynamic_values.service_authorization_flow_logs_to_cos,
    module.dynamic_values.service_authorization_secrets_manager_to_key_management
  )
}

##############################################################################


##############################################################################
# Authorization Policies
##############################################################################

resource "ibm_iam_authorization_policy" "policy" {
  for_each                    = local.authorization_policies
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
