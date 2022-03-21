##############################################################################
# Activity Tracker and Route
##############################################################################

resource "ibm_atracker_target" "atracker_target" {
  cos_endpoint {
    endpoint   = "s3.private.${var.region}.cloud-object-storage.appdomain.cloud"
    target_crn = local.bucket_to_instance_map[var.atracker.collector_bucket_name].id
    bucket     = "${var.prefix}-${var.atracker.collector_bucket_name}"
    api_key    = local.bucket_to_instance_map[var.atracker.collector_bucket_name].bind_key
  }
  name        = "${var.prefix}-atracker"
  target_type = "cloud_object_storage"

  # Wait for buckets and auth policies to ensure successful provision
  depends_on = [ibm_cos_bucket.buckets, ibm_iam_authorization_policy.policy]
}

resource "ibm_atracker_route" "atracker_route" {
  name                  = "${var.prefix}-atracker-route"
  receive_global_events = lookup(var.atracker, "receive_global_events", null)
  rules {
    target_ids = [
      ibm_atracker_target.atracker_target.id
    ]
  }
}

##############################################################################