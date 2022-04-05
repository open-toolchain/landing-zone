##############################################################################
# COS Dynamic Values
##############################################################################

locals {
  # Merge COS Ids from reesource and data
  cos_instance_ids = merge({
    for instance in var.cos_data_source :
    (instance.name) => instance.id
    }, {
    for instance in var.cos_resource :
    replace(instance.name, "${var.prefix}-", "") => instance.id
  })

  # Create map of COS instance to be retrieved from data
  cos_data_map = {
    for instance in var.cos :
    (instance.name) => instance if instance.use_data == true
  }

  # Create map of COS instances to create
  cos_map = {
    for instance in var.cos :
    (instance.name) => instance if instance.use_data != true
  }

  # Create Bucket List and add Instance Name
  cos_bucket_list = flatten([
    for instance in var.cos :
    [
      for bucket in instance.buckets :
      merge({
        instance               = instance.name
        use_data               = instance.use_data
        instance_reource_group = lookup(instance, "resource_group", null)
      }, bucket)
    ]
  ])

  # Convert map to list
  cos_bucket_map = {
    for bucket in local.cos_bucket_list :
    (bucket.name) => bucket
  }

  # For each key in each instastance create an object with name and use data
  cos_keys_list = flatten(
    [
      for instance in var.cos : [
        for cos_key in instance.keys :
        merge({
          instance = instance.name
        }, cos_key)
      ] if lookup(instance, "keys", null) != null
    ]
  )

  # Convert COS Resource Key List to Map
  cos_key_map = {
    for key in local.cos_keys_list :
    (key.name) => key
  }

  # Bucket to instance map to map bucket names to instance ID and Bind API Keys
  bucket_to_instance_map = {
    # For each bucket
    for bucket in local.cos_bucket_list :
    (bucket.name) => {
      # COS CRN
      id = local.cos_instance_ids[bucket.instance]
      # COS Name
      name = bucket.instance
      bind_key = lookup(
        # Get instance object with correct name
        [for instance in var.cos : instance if instance.name == bucket.instance][0], "keys", null
        # If keys for instance is null, return null
        ) == null ? null : length(
        lookup(
          [for instance in var.cos : instance if instance.name == bucket.instance][0], "keys", null
        )
        # If list of keys is empty return null
        ) == 0 ? null : var.cos_resource_keys[
        lookup([
          for instance in var.cos :
          instance if instance.name == bucket.instance
        ][0], "keys", null)[0].name
      ].credentials.apikey # Otherwise get credentials from first key
    }
  }
}

##############################################################################