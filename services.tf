##############################################################################
# Logging and Monitoring
##############################################################################

module "logging_and_monitoring" {
  source                  = "github.com/Cloud-Schematics/logging_monitoring_module.git"
  prefix                  = var.prefix
  region                  = var.region
  resource_group_id       = data.ibm_resource_group.resource_group.id
  tags                    = var.tags
  create_activity_tracker = var.create_activity_tracker
  service_endpoints       = var.service_endpoints
  sysdig                  = var.sysdig
  logdna                  = var.logdna
}

##############################################################################