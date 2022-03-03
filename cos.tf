##############################################################################
# Cloud Object Storage Locals
##############################################################################

locals {
  cos_location    = "global"
  cos_instance_id = var.cos.use_data ? data.ibm_resource_instance.cos[0].id : ibm_resource_instance.cos[0].id
}

##############################################################################

##############################################################################
# Cloud Object Storage
##############################################################################

data "ibm_resource_instance" "cos" {
  count = var.cos.use_data == true ? 1 : 0

  name              = var.cos.service_name
  location          = local.cos_location
  resource_group_id = local.resource_groups[var.cos.resource_group]
  service           = "cloud-object-storage"
}

resource "ibm_resource_instance" "cos" {
  count = var.cos.use_data == true ? 0 : 1

  name              = "${var.prefix}-${var.cos.service_name}"
  resource_group_id = local.resource_groups[var.cos.resource_group]
  service           = "cloud-object-storage"
  location          = local.cos_location
  plan              = var.cos.plan
  tags              = (var.tags != null ? var.tags : null)
}

locals {
  # Convert COS Resource Key List to Map
  cos_key_map = {
    for key in var.cos_resource_keys :
    (key.name) => key
  }
}

resource "ibm_resource_key" "key" {
  for_each = local.cos_key_map

  name                 = "${var.prefix}-${each.value.name}"
  role                 = each.value.role
  resource_instance_id = local.cos_instance_id
  tags                 = (var.tags != null ? var.tags : null)
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

  bucket_name           = "${var.prefix}-${each.value.name}"
  resource_instance_id  = local.cos_instance_id
  storage_class         = each.value.storage_class
  endpoint_type         = each.value.endpoint_type
  force_delete          = each.value.force_delete
  single_site_location  = each.value.single_site_location
  region_location       = each.value.region_location
  cross_region_location = each.value.cross_region_location
  key_protect = each.value.kms_key == null ? null : [
    for key in module.key_protect.keys :
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
      activity_tracker_crn = activity_tracking.valueactivity_tracker_crn
      read_data_events     = activity_tracking.valueread_data_events
      write_data_events    = activity_tracking.valuewrite_data_events
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