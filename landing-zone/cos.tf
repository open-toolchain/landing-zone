##############################################################################
# Cloud Object Storage Locals
##############################################################################

locals {
  cos_location = "global"
  # List of COS instance IDs
  cos_instance_ids = module.dynamic_values.cos_instance_ids
  # Map of COS instances from data
  cos_data_map = {
    for instance in var.cos :
    (instance.name) => instance if instance.use_data == true
  }
  # Map of created cos instances
  cos_map = {
    for instance in var.cos :
    (instance.name) => instance if instance.use_data != true
  }
  # Map of COS buckets
  buckets_map = module.dynamic_values.cos_bucket_map
  # Map of COS keys
  cos_key_map = module.dynamic_values.cos_key_map
  # Map connecting buckets to instances and spi bind keys
  bucket_to_instance_map = module.dynamic_values.bucket_to_instance_map
}

##############################################################################

##############################################################################
# Cloud Object Storage Instances
##############################################################################

data "ibm_resource_instance" "cos" {
  for_each          = local.cos_data_map
  name              = each.value.name
  location          = local.cos_location
  resource_group_id = local.resource_groups[each.value.resource_group]
  service           = "cloud-object-storage"
}

resource "ibm_resource_instance" "cos" {
  for_each          = local.cos_map
  name              = "${var.prefix}-${each.value.name}"
  resource_group_id = local.resource_groups[each.value.resource_group]
  service           = "cloud-object-storage"
  location          = local.cos_location
  plan              = each.value.plan
  tags              = (var.tags != null ? var.tags : null)
}

##############################################################################


##############################################################################
# COS Instance Keys
##############################################################################

resource "ibm_resource_key" "key" {
  for_each             = local.cos_key_map
  name                 = "${var.prefix}-${each.value.name}"
  role                 = each.value.role
  resource_instance_id = local.cos_instance_ids[each.value.instance]
  tags                 = (var.tags != null ? var.tags : null)
  parameters           = each.value.parameters
}

##############################################################################

##############################################################################
# Cloud Object Storage Buckets 
##############################################################################

resource "ibm_cos_bucket" "buckets" {
  for_each = local.buckets_map

  bucket_name           = "${var.prefix}-${each.value.name}"
  resource_instance_id  = local.cos_instance_ids[each.value.instance]
  storage_class         = each.value.storage_class
  endpoint_type         = each.value.endpoint_type
  force_delete          = each.value.force_delete
  single_site_location  = each.value.single_site_location
  region_location       = (each.value.region_location == null && each.value.single_site_location == null && each.value.cross_region_location == null) ? var.region : each.value.region_location
  cross_region_location = each.value.cross_region_location
  allowed_ip            = each.value.allowed_ip
  hard_quota            = each.value.hard_quota
  key_protect = each.value.kms_key == null ? null : [
    for key in module.key_management.keys :
    key.id if key.name == each.value.kms_key
  ][0]
  dynamic "archive_rule" {
    for_each = (
      each.value.archive_rule == null
      ? []
      : [each.value.archive_rule]
    )

    content {
      days    = archive_rule.value.days
      enable  = archive_rule.value.enable
      rule_id = archive_rule.value.rule_id
      type    = archive_rule.value.type
    }
  }

  dynamic "activity_tracking" {
    for_each = (
      each.value.activity_tracking == null
      ? []
      : [each.value.activity_tracking]
    )

    content {
      activity_tracker_crn = activity_tracking.value.activity_tracker_crn
      read_data_events     = activity_tracking.value.read_data_events
      write_data_events    = activity_tracking.value.write_data_events
    }
  }

  dynamic "metrics_monitoring" {
    for_each = (
      each.value.metrics_monitoring == null
      ? []
      : [each.value.metrics_monitoring]
    )

    content {
      metrics_monitoring_crn  = metrics_monitoring.value.metrics_monitoring_crn
      request_metrics_enabled = metrics_monitoring.value.request_metrics_enabled
      usage_metrics_enabled   = metrics_monitoring.value.usage_metrics_enabled
    }
  }
}

##############################################################################
