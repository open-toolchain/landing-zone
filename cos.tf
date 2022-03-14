##############################################################################
# Cloud Object Storage Locals
##############################################################################

locals {
  cos_location = "global"
  # COS instance map where names equal crn
  cos_instance_ids = merge({
    for instance in data.ibm_resource_instance.cos :
    (instance.name) => instance.id
    }, {
    for instance in ibm_resource_instance.cos :
    replace(instance.name, "${var.prefix}-", "") => instance.id
  })
  # Map bucket names to instance ID and bind api keys
  bucket_to_instance_map = {
    # For each bucket
    for bucket in local.bucket_list :
    (bucket.name) => {
      id   = local.cos_instance_ids[bucket.instance]
      name = bucket.instance
      # Get the first key of the COS instance and lookup credentials
      bind_key = lookup([
        for instance in var.cos :
        instance if instance.name == bucket.instance
        ][0], "keys", null) == null ? null : length(lookup([
          for instance in var.cos :
          instance if instance.name == bucket.instance
        ][0], "keys", null)) == 0 ? null : ibm_resource_key.key[
        lookup([
          for instance in var.cos :
          instance if instance.name == bucket.instance
        ][0], "keys", null)[0].name
      ].credentials.apikey
    }
  }
}

##############################################################################

##############################################################################
# Cloud Object Storage
##############################################################################

data "ibm_resource_instance" "cos" {
  for_each = {
    for instance in var.cos :
    (instance.name) => instance if instance.use_data == true
  }

  name              = each.value.name
  location          = local.cos_location
  resource_group_id = local.resource_groups[each.value.resource_group]
  service           = "cloud-object-storage"
}

resource "ibm_resource_instance" "cos" {
  for_each = {
    for instance in var.cos :
    (instance.name) => instance if instance.use_data != true
  }

  name              = "${var.prefix}-${each.value.name}"
  resource_group_id = local.resource_groups[each.value.resource_group]
  service           = "cloud-object-storage"
  location          = local.cos_location
  plan              = each.value.plan
  tags              = (var.tags != null ? var.tags : null)
}

locals {
  # COS Keys List
  cos_keys_list = flatten(
    [
      for instance in var.cos : [
        for cos_key in instance.keys :
        merge({
          instance = instance.name
          use_data = instance.use_data
        }, cos_key)
      ] if instance.keys != null
    ]
  )
  # Convert COS Resource Key List to Map
  cos_key_map = {
    for key in local.cos_keys_list :
    (key.name) => key
  }
}

resource "ibm_resource_key" "key" {
  for_each = local.cos_key_map

  name                 = "${var.prefix}-${each.value.name}"
  role                 = each.value.role
  resource_instance_id = local.cos_instance_ids[each.value.instance]
  tags                 = (var.tags != null ? var.tags : null)
}

##############################################################################

##############################################################################
# Cloud Object Storage Buckets 
##############################################################################

locals {
  # Create Bucket List
  bucket_list = flatten([
    for instance in var.cos :
    [
      for bucket in instance.buckets :
      merge({
        instance = instance.name
      }, bucket)
    ]
  ])
  # Convert COS Bucket List to Map
  buckets_map = {
    for bucket in local.bucket_list :
    (bucket.name) => bucket
  }
}

resource "ibm_cos_bucket" "buckets" {
  for_each = local.buckets_map

  bucket_name           = "${var.prefix}-${each.value.name}"
  resource_instance_id  = local.cos_instance_ids[each.value.instance]
  storage_class         = each.value.storage_class
  endpoint_type         = each.value.endpoint_type
  force_delete          = each.value.force_delete
  single_site_location  = each.value.single_site_location
  region_location       = each.value.region_location == null ? var.region : each.value.region_location
  cross_region_location = each.value.cross_region_location
  allowed_ip            = each.value.allowed_ip
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
