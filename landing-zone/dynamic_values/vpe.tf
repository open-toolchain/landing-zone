##############################################################################
# VPE Dynamic Values
##############################################################################

locals {
  # Create map of services by endpoint
  vpe_services = {
    for endpoint in var.virtual_private_endpoints :
    # create string for service name and type
    "${endpoint.service_name}-${endpoint.service_type}" => {
      # Only COS supported now
      crn = "crn:v1:bluemix:public:cloud-object-storage:global:::endpoint:s3.direct.${var.region}.cloud-object-storage.appdomain.cloud"
      id  = local.cos_instance_ids[endpoint.service_name]
    }
  }

  # Create list of needed gateways
  vpe_gateway_list = flatten([
    # fore each service
    for service in var.virtual_private_endpoints :
    [
      # for each VPC create an object for the endpoints to be created
      for vpcs in service.vpcs :
      {
        name                = "${vpcs.name}-${service.service_name}"
        vpc_id              = var.vpc_modules[vpcs.name].vpc_id
        resource_group      = lookup(service, "resource_group", null)
        security_group_name = lookup(vpcs, "security_group_name", null)
        crn                 = local.vpe_services["${service.service_name}-${service.service_type}"].crn
      }
    ]
  ])

  # Convert gateway list to map
  vpe_gateway_map = {
    for gateway in local.vpe_gateway_list :
    (gateway.name) => gateway
  }

  # Get a list of subnets to create VPE reserved addressess
  vpe_subnet_reserved_ip_list = flatten([
    # For each service
    for service in var.virtual_private_endpoints :
    [
      # For each VPC attached to that service
      for vpcs in service.vpcs :
      [
        # For each subnet where a VPE will be created
        for subnet in vpcs.subnets :
        # Create reserved IP object
        {
          ip_name      = "${vpcs.name}-${service.service_name}-gateway-${subnet}-ip"
          gateway_name = "${vpcs.name}-${service.service_name}"
          id = [
            for vpc_subnet in var.vpc_modules[vpcs.name].subnet_zone_list :
            vpc_subnet.id if vpc_subnet.name == "${var.prefix}-${vpcs.name}-${subnet}"
          ][0]
        }
      ]
    ]
  ])

  # Reserved IP map
  vpe_subnet_reserved_ip_map = {
    for subnet in local.vpe_subnet_reserved_ip_list :
    (subnet.ip_name) => subnet
  }

}

##############################################################################

