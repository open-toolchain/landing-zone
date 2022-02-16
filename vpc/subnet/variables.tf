##############################################################################
# Subnet Parameters
# Copyright 2020 IBM
##############################################################################

variable prefix {
  description = "Prefix to be added to the beginning of each subnet name"
  type        = string
  default     = "multizone-subnet"
}

variable vpc_id {
  description = "ID of VPC where subnets will be created"
  type        = string
}

variable region {
  description = "Region where VPC will be created"
  type        = string
  default     = "us-south"
}

variable subnets {
  description = "List of subnets for the vpc. For each item in each array, a subnet will be created. Items can be either CIDR blocks or total ipv4 addressess. Public gateways will be enabled only in zones where a gateway has been created"
  type        = object({
    zone-1 = list(object({
      name           = string
      cidr           = string
      public_gateway = optional(bool)
      acl_id         = string
    }))
    zone-2 = list(object({
      name           = string
      cidr           = string
      public_gateway = optional(bool)
      acl_id         = string
    }))
    zone-3 = list(object({
      name           = string
      cidr           = string
      public_gateway = optional(bool)
      acl_id         = string
    }))
  })
  default = {
    zone-1 = [],
    zone-2 = [],
    zone-3 = []
  }

  validation {
    error_message = "Keys for `subnets` must be in the order `zone-1`, `zone-2`, `zone-3`."
    condition     = keys(var.subnets)[0] == "zone-1" && keys(var.subnets)[1] == "zone-2" && keys(var.subnets)[2] == "zone-3"
  }
}

##############################################################################


##############################################################################
# Optional Subnet Creation Variables
##############################################################################

variable resource_group_id {
  description = "Optional. Resource group ID"
  type        = string
  default     = null
}

variable public_gateways {
  description = "Optional. A map of public gateway IDs. To not use a gateway in a specific zone, leave string empty. If public gateway IDs are provided, they will be used by any subnet created in the zone."
  type        = object({
    zone-1 = string
    zone-2 = string
    zone-3 = string
  })
  default     = {
    zone-1 = ""
    zone-2 = ""
    zone-3 = ""
  }

  validation {
      error_message = "Keys for `subnets` must be in the order `zone-1`, `zone-2`, `zone-3`."
      condition     = keys(var.public_gateways)[0] == "zone-1" && keys(var.public_gateways)[1] == "zone-2" && keys(var.public_gateways)[2] == "zone-3"
  }
}

variable routing_table_id {
  description = "Optional. Routing Table ID"
  type        = string
  default     = null
}

##############################################################################