##############################################################################
# Atracker
##############################################################################

resource "ibm_atracker_target" "atracker_target" {
  cos_endpoint {
    endpoint   = "s3.private.${var.location}.cloud-object-storage.appdomain.cloud"
    target_crn = var.target_crn
    bucket     = var.bucket_name
    api_key    = var.api_key
  }
  name        = var.atracker_target_name != null ? var.atracker_target_name : "atracker-target-${var.location}"
  target_type = var.atracker_target_type
}

resource "ibm_atracker_route" "atracker_route" {
  name                  = (var.atracker_route_name != null ? var.atracker_route_name : "atracker-route-${var.location}")
  receive_global_events = var.receive_global_events
  rules {
    target_ids = [ibm_atracker_target.atracker_target.id]
  }
}
