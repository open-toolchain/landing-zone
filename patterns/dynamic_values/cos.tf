##############################################################################
# Object Storage Values
##############################################################################

locals {
  ##############################################################################
  # Object Storage Variables
  ##############################################################################
  object_storage = [
    # Activity Tracker COS instance
    {
      name           = "atracker-cos"
      use_data       = false
      resource_group = "${var.prefix}-service-rg"
      plan           = "standard"
      buckets = [
        {
          name          = "atracker-bucket"
          storage_class = "standard"
          endpoint_type = "public"
          kms_key       = "${var.prefix}-atracker-key"
          force_delete  = true
        }
      ]
      # Key is needed to initialize actibity tracker
      keys = [{
        name        = "cos-bind-key"
        role        = "Writer"
        enable_HMAC = false
      }]
    },
    # COS instance for everything else
    {
      name           = "cos"
      use_data       = false
      resource_group = "${var.prefix}-service-rg"
      plan           = "standard"
      buckets = [
        # Create one flow log bucket for each VPC network
        for network in concat(local.vpc_list, local.bastion_resource_list) :
        {
          name          = "${network}-bucket"
          storage_class = "standard"
          kms_key       = "${var.prefix}-slz-key"
          endpoint_type = "public"
          force_delete  = true
        }
      ]
      keys = [
        # Create Bastion COS key
        for key_name in local.bastion_resource_list :
        {
          name        = "${key_name}-key"
          enable_HMAC = true
          role        = "Writer"
        }
      ]
    }
  ]
  ##############################################################################
}

##############################################################################