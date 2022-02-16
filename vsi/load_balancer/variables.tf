##############################################################################
# Variables
##############################################################################

variable prefix {
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources"
  type        = string
  default     = "asset-module-vsi"
}

variable vsi_ipv4_addresses {
    description = "A list of vsi ipv4 addresses"
    type        = list(string)
}

variable subnet_ids {
    description = "list of subnet ids where load balancer will be provisioned"
    type        = list(string)
}

variable resource_group_id {
  description = "ID of resource group to create VPC"
  type        = string
}

##############################################################################


##############################################################################
# LB Variables
##############################################################################

variable type {
    description = "Load Balancer type, can be public or private"
    type        = string
    default     = "public"
}

variable listener_port {
    description = "Listener port"
    # type       = number
    default     = 80
}

##############################################################################


##############################################################################
# Listener Variables
##############################################################################

variable listener_protocol {
    description = "The listener protocol. Supported values are http, tcp, and https"
    type        = string
    default     = "http"
}

variable certificate_instance {
    description = "Optional, the CRN of a certificate instance to use with the load balancer."
    type        = string
    default     = ""
}

variable connection_limit {
    description = "Optional, connection limit for the listener. Valid range 1 to 15000."
    # type        = number
    default     = 0
}

##############################################################################


##############################################################################
# Pool Variables
##############################################################################

variable algorithm {
    description = "The load balancing algorithm. Supported values are round_robin, or least_connections"
    type        = string
    default     = "round_robin"
}

variable protocol {
    description = "The pool protocol. Supported values are http, and tcp."
    type        = string    
    default     = "http"
}

variable health_delay {
    description = "The health check interval in seconds. Interval must be greater than timeout value."
    # type        = number
    default     = 5
}

variable health_retries {
    description = "The health check max retries."
    # type       = number
    default     = 10
}

variable health_timeout {
    description = "The health check timeout in seconds."
    # type       = number
    default     = 30    
}

variable health_type {
    description = "The pool protocol. Supported values are http, and tcp."
    type        = string
    default     = "http"
}

##############################################################################


##############################################################################
# Pool Member Variables
##############################################################################

variable pool_member_port {
    description = "The port number of the application running in the server member."
    default     = 80
}

##############################################################################