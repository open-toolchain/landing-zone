##############################################################################
# Cloud Object Storage Locals
##############################################################################

locals {
  cos_location = "global"
  should_provision_cos = (var.cos.desired_plan == null) ? false : true 
  cos_instance_id = local.should_provision_cos ? ibm_resource_instance.cos[0].id : data.ibm_resource_instance.cos[0].id
}

##############################################################################

##############################################################################
# Cloud Object Storage
##############################################################################

data "ibm_resource_instance" "cos" {
  count             = local.should_provision_cos ? 0 : 1 
  name              = var.cos.service_name
  location          = local.cos_location
  resource_group_id = local.resource_groups[var.cos.resource_group]
  service           = "cloud-object-storage"
}

resource "ibm_resource_instance" "cos" {
  count             = local.should_provision_cos ? 1 : 0
  name              = "${var.prefix}-${var.cos.service_name}"
  resource_group_id = local.resource_groups[var.cos.resource_group]
  service           = "cloud-object-storage"
  location          = local.cos_location
  plan              = var.cos.desired_plan
  tags              = (var.tags != null ? var.tags : null)
}

resource "ibm_resource_key" "key" {
  name                 = var.cos_resource_key.name
  role                 = var.cos_resource_key.role
  resource_instance_id = local.cos_instance_id
  tags                 = (var.tags != null ? var.tags : null)
}

resource "ibm_iam_authorization_policy" "policy" {
  count = length(var.cos_authorization_policies)

  source_service_name         = "cloud-object-storage"
  source_resource_instance_id = local.cos_instance_id
  source_resource_group_id    = local.resource_groups[var.cos.resource_group]

  target_service_name         = var.cos_authorization_policies[count.index].target_service_name
  target_resource_instance_id = var.cos_authorization_policies[count.index].target_resource_instance_id
  target_resource_group_id    = local.resource_groups[var.cos_authorization_policies[count.index].target_resource_group]

  roles       = var.cos_authorization_policies[count.index].roles 
  description = var.cos_authorization_policies[count.index].description
}

##############################################################################

##############################################################################
# Cloud Object Storage Buckets 
##############################################################################

locals {
  # Convert COS Bucket List to Map
  buckets_map = {
    for bucket in var.cos_buckets :
    (bucket.name) => bucket 
  }
}

resource "ibm_cos_bucket" "buckets" {
  for_each = local.buckets_map

  bucket_name           = "${var.prefix}-global-${each.value.name}"
  resource_instance_id  = local.cos_instance_id
  storage_class         = "standard"
  endpoint_type         = "public"
  force_delete          = true
  single_site_location  = each.value.single_site_location
  region_location       = each.value.region_location
  cross_region_location = each.value.cross_region_location
  key_protect           = each.value.kms_key_crn
}

##############################################################################
