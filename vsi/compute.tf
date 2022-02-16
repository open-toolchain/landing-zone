##############################################################################
# SSH key for creating VSI
##############################################################################

resource ibm_is_ssh_key ssh_key {
  name       = "${var.prefix}-ssh-key"
  public_key = var.ssh_public_key
}

##############################################################################


##############################################################################
# Image Data Block
##############################################################################

data ibm_is_image image {
  name = var.image
}

##############################################################################



##############################################################################
# Provision VSI
##############################################################################

locals {
  # Create a list of subnets and zones within range
  vsi_list = flatten([
    for subnet in var.subnets: [
      for count in range(var.vsi_per_subnet):
      {
        subnet_id = subnet.id
        zone      = subnet.zone
      }
    ]
  ])
}

resource ibm_is_instance vsi {
  count          = length(local.vsi_list)
  name           = "${var.prefix}-vsi-${count.index + 1}"
  image          = data.ibm_is_image.image.id
  profile        = var.machine_type
  resource_group = var.resource_group_id
  
  primary_network_interface {
    subnet   = local.vsi_list[count.index].subnet_id
    security_groups = [
      ibm_is_security_group.security_group.id
    ]
  }     
  vpc        = var.vpc_id
  zone       = local.vsi_list[count.index].zone

  
  keys       = [ibm_is_ssh_key.ssh_key.id]
}

##############################################################################


##############################################################################
# Create Load Balancers
##############################################################################

locals {
  load_balancer_map = {
    for load_balancer in var.load_balancers:
    (load_balancer.name) => load_balancer
  }
}

module load_balancers {
  source               = "./load_balancer"
  for_each             = local.load_balancer_map
  prefix               = "${var.prefix}-${each.value.name}"
  vsi_ipv4_addresses   = ibm_is_instance.vsi.*.primary_network_interface.0.primary_ipv4_address
  subnet_ids           = var.subnets.*.id
  resource_group_id    = var.resource_group_id
  type                 = each.value.type
  listener_port        = each.value.listener_port
  listener_protocol    = each.value.listener_protocol
  connection_limit     = each.value.connection_limit
  algorithm            = each.value.algorithm
  protocol             = each.value.protocol
  health_delay         = each.value.health_delay
  health_retries       = each.value.health_retries
  health_timeout       = each.value.health_timeout
  health_type          = each.value.health_type
  pool_member_port     = each.value.pool_member_port
}

##############################################################################