##############################################################################
# Authorization Policies
##############################################################################

locals {
  target_key_management_service = lookup(var.key_management, "use_hs_crypto", false) == true ? "hs-crypto" : "kms"
  service_authorization_vpc_to_key_management = {
    # Create authorization to allow key management to access VPC block storage for each vpc resource group
    for resource_group in distinct([
      for network in var.vpcs :
      network.resource_group if lookup(network, "resource_group", null) != null
    ]) :
    "${resource_group}-block-storage" => {
      source_service_name         = "server-protect"
      source_resource_group_id    = var.resource_groups[resource_group]
      description                 = "Allow block storage volumes to be encrypted by KMS instance"
      roles                       = ["Reader"]
      target_service_name         = local.target_key_management_service
      target_resource_instance_id = var.key_management_guid
    }
  }
  service_authorization_cos_to_key_management = {
    # Create authorization for each COS instance
    for cos in var.cos :
    "cos-${cos.name}-to-key-management" => {
      source_service_name         = "cloud-object-storage"
      source_resource_instance_id = local.cos_instance_ids[cos.name]
      description                 = "Allow COS instance to read from KMS instance"
      roles                       = ["Reader"]
      target_service_name         = local.target_key_management_service
      target_resource_instance_id = var.key_management_guid
    }
  }
  service_authorization_flow_logs_to_cos = {
    for instance in var.cos :
    "flow-logs-${instance.name}-cos" => {
      source_service_name         = "is"
      source_resource_type        = "flow-log-collector"
      description                 = "Allow flow logs write access cloud object storage instance"
      roles                       = ["Writer"]
      target_service_name         = "cloud-object-storage"
      target_resource_instance_id = split(":", local.cos_instance_ids[instance.name])[7]
    }
  }
}

##############################################################################


