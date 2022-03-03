##############################################################################
# Atracker
##############################################################################

resource "ibm_atracker_target" "atracker_target" {
  count = var.use_atracker ? 1 : 0
  cos_endpoint {
    endpoint   = "s3.private.${var.region}.cloud-object-storage.appdomain.cloud"
    target_crn = lookup(var.atracker, "target_crn", null)
    bucket     = lookup(var.atracker, "bucket_name", null)
    api_key    = lookup(var.atracker, "cos_api_key", null)
  }
  name        = "${var.prefix}-atracker"
  target_type = lookup(var.atracker, "target_type", null)
}

resource "ibm_atracker_route" "atracker_route" {
  count                 = var.use_atracker ? 1 : 0
  name                  = "${var.prefix}-atracker-route"
  receive_global_events = lookup(var.atracker, "receive_global_events", null)
  rules {
    target_ids = [ibm_atracker_target.atracker_target[0].id]
  }
}

##############################################################################