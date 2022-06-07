##############################################################################
# Object Storage Dynamic Values
##############################################################################

module "cos" {
  source            = "./config_modules/cos"
  prefix            = var.prefix
  cos               = var.cos
  cos_data_source   = var.cos_data_source
  cos_resource      = var.cos_resource
  cos_resource_keys = var.cos_resource_keys
}

locals {
  cos_instance_ids = module.cos.cos_instance_ids
}

##############################################################################

##############################################################################
# [Unit Test] COS Bucket To Instance Map
##############################################################################

module "ut_cos" {
  source = "./config_modules/cos"
  prefix = "ut"
  cos_data_source = {
    data-cos = {
      name = "data-cos"
      id   = ":::::::5678"
    }
  }
  cos_resource = {
    test-cos = {
      name = "ut-test-cos"
      id   = ":::::::1234"
    }
  }
  cos_resource_keys = {
    data-bucket-key = {
      credentials = {
        apikey = "1234"
      }
    }
  }
  cos = [
    {
      name     = "data-cos"
      use_data = true
      buckets = [
        {
          name = "data-bucket"
        }
      ]
      keys = [
        {
          name        = "data-bucket-key"
          enable_HMAC = false
        },
        {
          name        = "teleport-key"
          enable_HMAC = true
        }
      ]
    },
    {
      name     = "test-cos"
      use_data = false
      buckets = [
        {
          name = "create-bucket"
        }
      ]
    }
  ]
}

locals {
  assert_bucket_contains_correct_api_key = regex("1234", module.ut_cos.bucket_to_instance_map["data-bucket"].bind_key)
}

##############################################################################