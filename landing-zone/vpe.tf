##############################################################################
# VPE Locals
##############################################################################

locals {
  services = {
    for endpoint in var.virtual_private_endpoints :
    # create string for service name and type
    "${endpoint.service_name}-${endpoint.service_type}" => {
      # Only COS supported now
      crn = "crn:v1:bluemix:public:cloud-object-storage:global:::endpoint:s3.direct.${var.region}.cloud-object-storage.appdomain.cloud"
      id  = local.cos_instance_ids[endpoint.service_name]
    }
  }
  vpe_gateway_list = flatten([
    for service in var.virtual_private_endpoints :
    [
      for vpcs in service.vpcs :
      {
        name                = "${vpcs.name}-${service.service_name}"
        vpc_id              = module.vpc[vpcs.name].vpc_id
        resource_group      = service.resource_group
        security_group_name = vpcs.security_group_name
        crn                 = local.services["${service.service_name}-${service.service_type}"].crn
      }
    ]
  ])
  vpe_gateway_map = {
    for gateway in local.vpe_gateway_list :
    (gateway.name) => gateway
  }
  subnet_reserved_ip_list = flatten([
    for service in var.virtual_private_endpoints :
    [
      for vpcs in service.vpcs :
      [
        for subnet in vpcs.subnets :
        {
          ip_name      = "${vpcs.name}-${service.service_name}-gateway-${subnet}-ip"
          gateway_name = "${vpcs.name}-${service.service_name}"
          id = [
            for vpc_subnet in module.vpc[vpcs.name].subnet_zone_list :
            vpc_subnet.id if vpc_subnet.name == "${var.prefix}-${vpcs.name}-${subnet}"
          ][0]
        }
      ]
    ]
  ])
  reserved_ip_map = {
    for subnet in local.subnet_reserved_ip_list :
    (subnet.ip_name) => subnet
  }
}

##############################################################################


##############################################################################
# Endpoint Gateways
##############################################################################

resource "ibm_is_subnet_reserved_ip" "ip" {
  for_each = local.reserved_ip_map
  subnet   = each.value.id
}

resource "ibm_is_virtual_endpoint_gateway" "endpoint_gateway" {
  for_each        = local.vpe_gateway_map
  name            = "${var.prefix}-${each.key}"
  vpc             = each.value.vpc_id
  resource_group  = each.value.resource_group == null ? null : local.resource_groups[each.value.resource_group]
  security_groups = each.value.security_group_name == null ? null : [each.value.security_group_name]

  target {
    crn           = each.value.crn
    resource_type = "provider_cloud_service"
  }
}

resource "ibm_is_virtual_endpoint_gateway_ip" "endpoint_gateway_ip" {
  for_each    = local.reserved_ip_map
  gateway     = ibm_is_virtual_endpoint_gateway.endpoint_gateway[each.value.gateway_name].id
  reserved_ip = ibm_is_subnet_reserved_ip.ip[each.key].reserved_ip
}

##############################################################################\