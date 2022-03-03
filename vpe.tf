##############################################################################
# VPE Locals
##############################################################################

locals {
  services = {
    cloud_object_storage = {
      id = local.cos_instance_id
      crn = "crn:v1:bluemix:public:cloud-object-storage:global:::endpoint:s3.direct.${var.region}.cloud-object-storage.appdomain.cloud"
    }
  }
  vpe_gateway_connection_list = flatten([
    for service in var.virtual_private_endpoints :
    [
      for vpcs in service.vpcs :
      {
        connection_name     = "${service.service_name}-${vpcs.name}"
        crn                 = local.services[service.service_name].crn
        vpc_id              = module.vpc[vpcs.name].vpc_id
        security_group_name = vpcs.security_group_name
        resource_group      = service.resource_group
        subnets = [
          for subnet in module.vpc[vpcs.name].subnet_zone_list :
          subnet.id if contains([
            for name in vpcs.subnets :
            "${var.prefix}-${vpcs.name}-${name}"
          ], subnet.name)
        ],
      }
    ]
  ])
  vpe_gateway_connections = {
    for connection in local.vpe_gateway_connection_list :
    (connection.connection_name) => connection
  }
}

##############################################################################


##############################################################################
# Endpoint Gateways
##############################################################################

resource "ibm_is_virtual_endpoint_gateway" "endpoint_gateway" {
  for_each        = local.vpe_gateway_connections
  name            = replace(each.key, "_", "-")
  vpc             = each.value.vpc_id
  resource_group  = each.value.resource_group == null ? null : local.resource_groups[each.value.resource_group]
  security_groups = each.value.security_group_name == null ? null : [each.value.security_group_name]

  target {
    crn           = each.value.crn
    resource_type = "provider_cloud_service"
  }

  dynamic "ips" {
    for_each = each.value.subnets
    content {
      name   = "${each.key}-${index(each.value.subnets, ips.value) + 1}-ip"
      subnet = ips.value
    }
  }
}

##############################################################################\