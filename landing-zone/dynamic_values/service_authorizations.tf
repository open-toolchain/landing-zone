##############################################################################
# Authorization Policies
##############################################################################

locals {
  target_key_management_service = lookup(var.key_management, "use_hs_crypto", false) == true ? "hs-crypto" : "kms"
  service_authorization_vpc_to_key_management = {
    # Create authorization to allow key management to access VPC block storage
    "block-storage" = {
      source_service_name         = "server-protect"
      description                 = "Allow block storage volumes to be encrypted by KMS instance"
      roles                       = ["Reader"]
      target_service_name         = local.target_key_management_service
      target_resource_instance_id = var.key_management_guid
    }
  }
  service_authorization_cos_to_key_management = {
    # Create authorization for each COS instance
    for instance in var.cos :
    "cos-${instance.name}-to-key-management" => {
      source_service_name         = "cloud-object-storage"
      source_resource_instance_id = split(":", local.cos_instance_ids[instance.name])[7]
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
  service_authorization_secrets_manager_to_key_management = {
    for instance in(var.secrets_manager.use_secrets_manager ? ["secrets-manager-to-kms"] : []) :
    (instance) => {
      source_service_name         = "secrets-manager"
      description                 = "Allow secrets manager to read from Key Management"
      roles                       = ["Reader"]
      target_service_name         = local.target_key_management_service
      target_resource_instance_id = var.key_management_guid
    }
  }
}

##############################################################################


