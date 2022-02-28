##############################################################################
# Atracker
##############################################################################

resource "ibm_atracker_target" "atracker_target" {
  count = var.use_atracker ? 1 : 0
  cos_endpoint {
    endpoint   = "s3.private.${var.region}.cloud-object-storage.appdomain.cloud"
    target_crn = var.atracker.target_crn
    bucket     = var.atracker.bucket_name
    api_key    = var.atracker.cos_api_key
  }
  name        = "${var.prefix}-atracker"
  target_type = var.atracker.target_type
}

resource "ibm_atracker_route" "atracker_route" {
  count = var.use_atracker ? 1 : 0
  name                  = "${var.prefix}-atracker-route"
  receive_global_events = var.receive_global_events
  rules {
    target_ids = [ibm_atracker_target.atracker_target[0].id]
  }
}

##############################################################################