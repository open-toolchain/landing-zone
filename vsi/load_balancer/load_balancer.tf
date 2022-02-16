##############################################################################
# Load Balancer
##############################################################################

resource ibm_is_lb lb {
    name           = "${var.prefix}-lb"
    subnets        = var.subnet_ids
    type           = var.type
    resource_group = var.resource_group_id
}

##############################################################################


##############################################################################
# Load Balancer Pool
##############################################################################

resource ibm_is_lb_pool pool {
    lb                 = ibm_is_lb.lb.id
    name               = "${var.prefix}-lb-pool"
    algorithm          = var.algorithm
    protocol           = var.protocol
    health_delay       = var.health_delay
    health_retries     = var.health_retries
    health_timeout     = var.health_timeout
    health_type        = var.health_type
}

##############################################################################

##############################################################################
# Load Balancer Pool Member
##############################################################################

resource ibm_is_lb_pool_member pool_members {
    count          = length(var.vsi_ipv4_addresses)
    port           = var.pool_member_port
    lb             = ibm_is_lb.lb.id
    pool           = element(split("/", ibm_is_lb_pool.pool.id),1)
    target_address = var.vsi_ipv4_addresses[count.index]
}

##############################################################################



##############################################################################
# Load Balancer Listener
##############################################################################

resource ibm_is_lb_listener listener {
    lb                    = ibm_is_lb.lb.id
    default_pool          = ibm_is_lb_pool.pool.id
    port                  = var.listener_port
    protocol              = var.listener_protocol
    certificate_instance  = var.certificate_instance != "" ? var.certificate_instance : null
    connection_limit      = var.connection_limit > 0 ? var.connection_limit : null
    depends_on            = [ibm_is_lb_pool_member.pool_members]
}

##############################################################################