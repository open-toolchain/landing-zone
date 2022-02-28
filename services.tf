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


##############################################################################
# Hyper Protect Database as a Service
##############################################################################

resource "ibm_resource_instance" "dbaas" {
  name              = "${var.prefix}-${var.dbaas_type}"
  service           = "hyperp-dbaas-${var.dbaas_type}"
  plan              = "${var.dbaas_type}-flexible"
  location          = var.region
  resource_group_id = data.ibm_resource_group.resource_group.id
  tags              = var.tags

  parameters = {
    name                  = "${var.prefix}-${var.dbaas_type}",
    admin_name            = var.dbaas_admin_config.admin_name
    password              = var.dbaas_admin_config.password
    confirm_password      = var.dbaas_admin_config.password
    db_version            = var.dbaas_cluster_config.db_version
    cpu                   = var.dbaas_cluster_config.cpu
    storage               = var.dbaas_cluster_config.storage
    memory                = var.dbaas_cluster_config.memory
    private_endpoint_type = "vpe"
    service-endpoints     = "private"
  }

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}

##############################################################################