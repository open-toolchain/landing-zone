##############################################################################
# Atracker
##############################################################################

resource "ibm_atracker_target" "atracker_target" {
  cos_endpoint {
    endpoint   = "s3.private.${var.region}.cloud-object-storage.appdomain.cloud"
    target_crn = local.cos_instance_id
    bucket     = ibm_cos_bucket.buckets[var.flow_logs.cos_bucket_name].bucket_name
    api_key    = ibm_resource_key.key["cos-bind-key"].credentials.apikey
  }
  name        = "${var.prefix}-atracker"
  target_type = "cloud_object_storage"

  depends_on = [ibm_cos_bucket.buckets, ibm_iam_authorization_policy.policy]
}

resource "ibm_atracker_route" "atracker_route" {
  name                  = "${var.prefix}-atracker-route"
  receive_global_events = lookup(var.atracker, "receive_global_events", null)
  rules {
    target_ids = [ibm_atracker_target.atracker_target.id]
  }
}

##############################################################################