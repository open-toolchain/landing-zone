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

data "ibm_resource_group" "cos_resource_group" {
  name = var.cos.resource_group
}

data "ibm_resource_instance" "cos" {
  count             = local.should_provision_cos ? 0 : 1 
  name              = var.cos.service_name
  location          = local.cos_location
  resource_group_id = data.ibm_resource_group.cos_resource_group.id
  service           = "cloud-object-storage"
}

resource "ibm_resource_instance" "cos" {
  count             = local.should_provision_cos ? 1 : 0
  name              = "${var.prefix}-${var.cos.service_name}"
  resource_group_id = data.ibm_resource_group.cos_resource_group.id
  service           = "cloud-object-storage"
  location          = local.cos_location
  plan              = var.cos.desired_plan
  tags              = (var.tags != null ? var.tags : null)
}

resource "ibm_resource_key" "key" {
  name                 = var.cos.bind_key_name
  role                 = var.cos.bind_key_role
  resource_instance_id = local.cos_instance_id
  tags                 = (var.tags != null ? var.tags : null)
}

##############################################################################

##############################################################################
# Cloud Object Storage Buckets 
##############################################################################

data "ibm_resource_instance" "kms" {
  name              = var.kms.service_name
  service           = var.kms.service
}

resource "ibm_iam_authorization_policy" "policy" {
  source_service_name         = "cloud-object-storage"
  target_resource_instance_id = data.ibm_resource_instance.kms.id
  target_service_name         = var.kms.service
  roles                       = ["Reader"]  
}

resource "ibm_cos_bucket" "buckets" {
  for_each = var.cos_buckets

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
