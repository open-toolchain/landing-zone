##############################################################################
# Account Variables
##############################################################################

variable resource_group_id {
  description = "id of resource group to create VPC"
  type        = string
}

variable prefix {
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources"
  type        = string
}

##############################################################################


##############################################################################
# VPC Variables
##############################################################################

variable vpc_id {
  description = "ID of VPC"
  type        = string
}

variable subnets {
  description = "A list of subnet IDs where VSI will be deployed"
  type        = list(
    object({
      name = string
      id   = string
      zone = string
      cidr = string
    })
  )
}


##############################################################################


##############################################################################
# VSI Variables
##############################################################################

variable image {
  description = "Image name used for VSI. Run 'ibmcloud is images' to find available images in a region"
  type        = string
  default     = "ibm-centos-7-6-minimal-amd64-2"
}

variable ssh_public_key {
  description = "ssh public key to use for vsi"
  type        = string
}

variable machine_type {
  description = "VSI machine type. Run 'ibmcloud is instance-profiles' to get a list of regional profiles"
  type        =  string
  default     = "bx2-8x32"
}

variable vsi_per_subnet {
    description = "Number of VSI instances for each subnet"
    type        = number
    default     = 1
}

variable security_group {
  description = "Security group for VSI"
  type        = object({
    name  = string
    rules = list(
      object({
        name      = string
        direction = string
        source    = string
        tcp       = optional(
          object({
            port_max = number
            port_min = number
          })
        )
        udp       = optional(
          object({
            port_max = number
            port_min = number
          })
        )
        icmp       = optional(
          object({
            type = number
            code = number
          })
        )
      })
    ) 
  })
}

variable load_balancers {
  description = "Load balancers to add to VSI"
  type        = list(
    object({
      name              = string
      type              = string
      listener_port     = number
      listener_protocol = string
      connection_limit  = number
      algorithm         = string
      protocol          = string
      health_delay      = number
      health_retries    = number
      health_timeout    = number
      health_type       = string
      pool_member_port  = string
    })
  )
  default = []
}

##############################################################################