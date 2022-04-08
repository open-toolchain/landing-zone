##############################################################################
# Account Variables
##############################################################################

variable "resource_group_id" {
  description = "id of resource group to create VPC"
  type        = string
}

variable "prefix" {
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources"
  type        = string

  validation {
    error_message = "Prefix must begin and end with a letter and contain only letters, numbers, and - characters."
    condition     = can(regex("^([A-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.prefix))
  }
}

variable "tags" {
  description = "List of tags to apply to resources created by this module."
  type        = list(string)
  default     = []
}

##############################################################################


##############################################################################
# VPC Variables
##############################################################################

variable "vpc_id" {
  description = "ID of VPC"
  type        = string
}

variable "subnets" {
  description = "A list of subnet IDs where VSI will be deployed"
  type = list(
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

variable "image_id" {
  description = "Image ID used for VSI. Run 'ibmcloud is images' to find available images in a region"
  type        = string
}

variable "ssh_key_ids" {
  description = "ssh key ids to use in creating vsi"
  type        = list(string)
}

variable "machine_type" {
  description = "VSI machine type. Run 'ibmcloud is instance-profiles' to get a list of regional profiles"
  type        = string
}

variable "vsi_per_subnet" {
  description = "Number of VSI instances for each subnet"
  type        = number
}

variable "user_data" {
  description = "User data to initialize VSI deployment"
  type        = string
}

variable "boot_volume_encryption_key" {
  description = "CRN of boot volume encryption key"
  type        = string
}

variable "enable_floating_ip" {
  description = "Create a floating IP for each virtual server created"
  type        = bool
}

variable "create_security_group" {
  description = "Create security group for VSI. If this is passed as false, the default will be used"
  type        = bool
}

variable "security_group" {
  description = "Security group created for VSI"
  type = object({
    name = string
    rules = list(
      object({
        name      = string
        direction = string
        source    = string
        tcp = optional(
          object({
            port_max = number
            port_min = number
          })
        )
        udp = optional(
          object({
            port_max = number
            port_min = number
          })
        )
        icmp = optional(
          object({
            type = number
            code = number
          })
        )
      })
    )
  })

  validation {
    error_message = "Each security group rule must have a unique name."
    condition     = length(distinct(var.security_group.rules.*.name)) == length(var.security_group.rules.*.name)
  }

  validation {
    error_message = "Security group rules can only use one of the following blocks: `tcp`, `udp`, `icmp`."
    condition = length(
      distinct(
        flatten([
          for rule in var.security_group.rules :
          true if length(
            [
              for type in ["tcp", "udp", "icmp"] :
              true if rule[type] != null
            ]
          ) > 1
        ])
      )
    ) == 0
  }

  validation {
    error_message = "Security group rule direction can only be `inbound` or `outbound`."
    condition = length(
      distinct(
        flatten([
          for rule in var.security_group.rules :
          false if !contains(["inbound", "outbound"], rule.direction)
        ])
      )
    ) == 0
  }

}

variable "security_group_ids" {
  description = "IDs of additional security groups to be added to VSI deployment. A VSI can have a maximum of 5 security groups."
  type        = list(string)
  default     = []

  validation {
    error_message = "Security group IDs must be unique."
    condition     = length(var.security_group_ids) == length(distinct(var.security_group_ids))
  }

  validation {
    error_message = "No more than 5 security groups can be added to a VSI deployment."
    condition     = length(var.security_group_ids) <= 5
  }
}

variable "block_storage_volumes" {
  description = "List describing the block storage volumes that will be attached to each vsi"
  type = list(
    object({
      name           = string
      profile        = string
      capacity       = optional(number)
      iops           = optional(number)
      encryption_key = optional(string)
    })
  )
  default = []

  validation {
    error_message = "Each block storage volume must have a unique name."
    condition     = length(distinct(var.block_storage_volumes.*.name)) == length(var.block_storage_volumes)
  }
}

variable "load_balancers" {
  description = "Load balancers to add to VSI"
  type = list(
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
      security_group = optional(
        object({
          name = string
          rules = list(
            object({
              name      = string
              direction = string
              source    = string
              tcp = optional(
                object({
                  port_max = number
                  port_min = number
                })
              )
              udp = optional(
                object({
                  port_max = number
                  port_min = number
                })
              )
              icmp = optional(
                object({
                  type = number
                  code = number
                })
              )
            })
          )
        })
      )
    })
  )
  default = []

  validation {
    error_message = "Load balancer names must match the regex pattern ^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$."
    condition = length(distinct(
      flatten([
        # Check through rules
        for load_balancer in var.load_balancers :
        # Return false if direction is not valid
        false if !can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", load_balancer.name))
      ])
    )) == 0
  }

  validation {
    error_message = "Load Balancer Pool algorithm can only be `round_robin`, `weighted_round_robin`, or `least_connections`."
    condition = length(
      flatten([
        for load_balancer in var.load_balancers :
        true if !contains(["round_robin", "weighted_round_robin", "least_connections"], load_balancer.algorithm)
      ])
    ) == 0
  }

  validation {
    error_message = "Load Balancer Pool Protocol can only be `http`, `https`, or `tcp`."
    condition = length(
      flatten([
        for load_balancer in var.load_balancers :
        true if !contains(["http", "https", "tcp"], load_balancer.protocol)
      ])
    ) == 0
  }

  validation {
    error_message = "Pool health delay must be greater than the timeout."
    condition = length(
      flatten([
        for load_balancer in var.load_balancers :
        true if load_balancer.health_delay < load_balancer.health_timeout
      ])
    ) == 0
  }

  validation {
    error_message = "Load Balancer Pool Health Check Type can only be `http`, `https`, or `tcp`."
    condition = length(
      flatten([
        for load_balancer in var.load_balancers :
        true if !contains(["http", "https", "tcp"], load_balancer.health_type)
      ])
    ) == 0
  }

  validation {
    error_message = "Each load balancer must have a unique name."
    condition     = length(distinct(var.load_balancers.*.name)) == length(var.load_balancers.*.name)
  }
}

##############################################################################