##############################################################################
# Account Variables
##############################################################################

# Uncomment this variable if running locally
variable "ibmcloud_api_key" {
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources."
  type        = string
  sensitive   = true
}

# Comment out if not running in schematics
# variable "TF_VERSION" {
#   default     = "1.0"
#   type        = string
#   description = "The version of the Terraform engine that's used in the Schematics workspace."
# }

variable "prefix" {
  description = "A unique identifier for resources. Must begin with a letter. This prefix will be prepended to any resources provisioned by this template."
  type        = string
  default     = "gcat-multizone-schematics"

  validation {
    error_message = "Prefix must begin and end with a letter and contain only letters, numbers, and - characters."
    condition     = can(regex("^([A-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.prefix))
  }
}

variable "region" {
  description = "Region where VPC will be created. To find your VPC region, use `ibmcloud is regions` command to find available regions."
  type        = string
  default     = "us-south"
}

variable "resource_group" {
  description = "Name of resource group where all infrastructure will be provisioned."
  type        = string

  validation {
    error_message = "Unique ID must begin and end with a letter and contain only letters, numbers, and - characters."
    condition     = can(regex("^([A-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.resource_group))
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

variable "vpcs" {
  description = "A map describing VPCs to be created in this repo."
  type = list(
    object({
      prefix                      = string # VPC prefix
      use_manual_address_prefixes = optional(bool)
      classic_access              = optional(bool)
      default_network_acl_name    = optional(string)
      default_security_group_name = optional(string)
      default_routing_table_name  = optional(string)
      address_prefixes = optional(
        object({
          zone-1 = optional(list(string))
          zone-2 = optional(list(string))
          zone-3 = optional(list(string))
        })
      )
      network_acls = list(
        object({
          name              = string
          add_cluster_rules = optional(bool)
          rules = list(
            object({
              name        = string
              action      = string
              destination = string
              direction   = string
              source      = string
              tcp = optional(
                object({
                  port_max        = optional(number)
                  port_min        = optional(number)
                  source_port_max = optional(number)
                  source_port_min = optional(number)
                })
              )
              udp = optional(
                object({
                  port_max        = optional(number)
                  port_min        = optional(number)
                  source_port_max = optional(number)
                  source_port_min = optional(number)
                })
              )
              icmp = optional(
                object({
                  type = optional(number)
                  code = optional(number)
                })
              )
            })
          )
        })
      )
      use_public_gateways = object({
        zone-1 = optional(bool)
        zone-2 = optional(bool)
        zone-3 = optional(bool)
      })
      subnets = object({
        zone-1 = list(object({
          name           = string
          cidr           = string
          public_gateway = optional(bool)
          acl_name       = string
        }))
        zone-2 = list(object({
          name           = string
          cidr           = string
          public_gateway = optional(bool)
          acl_name       = string
        }))
        zone-3 = list(object({
          name           = string
          cidr           = string
          public_gateway = optional(bool)
          acl_name       = string
        }))
      })
    })
  )
  default = [
    {
      prefix = "management"
      use_public_gateways = {
        zone-1 = true
        zone-2 = true
        zone-3 = true
      }
      network_acls = [
        {
          name              = "vpc-acl"
          add_cluster_rules = true
          rules = [
            {
              name        = "allow-all-inbound"
              action      = "allow"
              direction   = "inbound"
              destination = "0.0.0.0/0"
              source      = "0.0.0.0/0"
            },
            {
              name        = "allow-all-outbound"
              action      = "allow"
              direction   = "outbound"
              destination = "0.0.0.0/0"
              source      = "0.0.0.0/0"
            }
          ]
        }
      ]
      subnets = {
        zone-1 = [
          {
            name           = "subnet-a"
            cidr           = "10.10.10.0/24"
            public_gateway = true
            acl_name       = "vpc-acl"
          }
        ],
        zone-2 = [
          {
            name           = "subnet-b"
            cidr           = "10.20.10.0/24"
            public_gateway = true
            acl_name       = "vpc-acl"
          }
        ],
        zone-3 = [
          {
            name           = "subnet-c"
            cidr           = "10.30.10.0/24"
            public_gateway = true
            acl_name       = "vpc-acl"
          }
        ]
      }
    },
    {
      prefix = "workload"
      use_public_gateways = {
        zone-1 = true
        zone-2 = true
        zone-3 = true
      }
      network_acls = [
        {
          name              = "vpc-acl"
          add_cluster_rules = true
          rules = [
            {
              name        = "allow-all-inbound"
              action      = "allow"
              direction   = "inbound"
              destination = "0.0.0.0/0"
              source      = "0.0.0.0/0"
            },
            {
              name        = "allow-all-outbound"
              action      = "allow"
              direction   = "outbound"
              destination = "0.0.0.0/0"
              source      = "0.0.0.0/0"
            }
          ]
        }
      ]
      subnets = {
        zone-1 = [
          {
            name           = "subnet-a"
            cidr           = "10.40.10.0/24"
            public_gateway = true
            acl_name       = "vpc-acl"
          }
        ],
        zone-2 = [
          {
            name           = "subnet-b"
            cidr           = "10.50.10.0/24"
            public_gateway = true
            acl_name       = "vpc-acl"
          }
        ],
        zone-3 = [
          {
            name           = "subnet-c"
            cidr           = "10.60.10.0/24"
            public_gateway = true
            acl_name       = "vpc-acl"
          }
        ]
      }
    }
  ]
}

##############################################################################


##############################################################################
# Flow Logs Variables
##############################################################################

variable "flow_logs" {
  description = "List of variables for flow log to connect to each VSI instance. Set `use` to false to disable flow logs."
  type = object({
    cos_bucket_name = string
    active          = bool
  })
  default = {
    cos_bucket_name = "jv-dev-bucket"
    active          = true
  }
}

##############################################################################


##############################################################################
# Transit Gateway
##############################################################################

variable "enable_transit_gateway" {
  description = "Create transit gateway"
  type        = bool
  default     = true
}

variable "transit_gateway_connections" {
  description = "Transit gateway vpc connections. Will only be used if transit gateway is enabled."
  type        = list(string)
  default = [
    "management",
    "workload"
  ]
}

##############################################################################

##############################################################################
# VSI Variables
##############################################################################

variable "ssh_keys" {
  description = "SSH Keys to use for VSI Provision. If `public_key` is not provided, the named key will be looked up from data."
  type = list(
    object({
      name       = string
      public_key = optional(string)
    })
  )
  default = [
    {
      name       = "dev-ssh-key"
      public_key = "<ssh public key>"
    }
  ]

  validation {
    error_message = "Each SSH key must have a unique name."
    condition     = length(distinct(var.ssh_keys.*.name)) == length(var.ssh_keys.*.name)
  }

  validation {
    error_message = "Each key using the public_key field must have a unique public key."
    condition = length(
      distinct(
        [
          for ssh_key in var.ssh_keys :
          ssh_key.public_key if ssh_key.public_key != null
        ]
      )
      ) == length(
      [
        for ssh_key in var.ssh_keys :
        ssh_key.public_key if ssh_key.public_key != null
      ]
    )
  }
}

variable "vsi" {
  description = "A list describing VSI workloads to create"
  type = list(
    object({
      name            = string
      vpc_name        = string
      subnet_names    = list(string)
      ssh_keys        = list(string)
      image_name      = string
      machine_type    = string
      vsi_per_subnet  = number
      user_data       = optional(string)
      security_groups = optional(list(string))
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
      block_storage_volumes = optional(list(
        object({
          name           = string
          profile        = string
          capacity       = optional(number)
          iops           = optional(number)
          encryption_key = optional(string)
        })
      ))
      load_balancers = optional(list(
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
      ))
    })
  )
  default = [
    {
      name           = "test-vsi"
      vpc_name       = "management"
      subnet_names   = ["subnet-a", "subnet-c"]
      image_name     = "ibm-centos-7-6-minimal-amd64-2"
      machine_type   = "bx2-8x32"
      ssh_keys       = ["dev-ssh-key"]
      vsi_per_subnet = 1
      security_group = {
        name = "test"
        rules = [
          {
            name      = "allow-all-inbound"
            source    = "0.0.0.0/0"
            direction = "inbound"
          },
          {
            name      = "allow-all-outbound"
            source    = "0.0.0.0/0"
            direction = "outbound"
          }
        ]
      }
      /*
      block_storage_volumes = [{
        name    = "one"
        profile = "general-purpose"
        }, {
        name    = "two"
        profile = "general-purpose"
      }]
      load_balancers = [
        {
          name              = "test"
          type              = "public"
          listener_port     = 80
          listener_protocol = "http"
          connection_limit  = 0
          algorithm         = "round_robin"
          protocol          = "http"
          health_delay      = 10
          health_retries    = 10
          health_timeout    = 5
          health_type       = "http"
          pool_member_port  = 80
        }
      ]*/
    }
  ]
}



##############################################################################


##############################################################################
# Security Group Variables
##############################################################################

variable "security_groups" {
  description = "Security groups for VPC"
  type = list(
    object({
      name     = string
      vpc_name = string
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

  default = [
    {
      name     = "workload-vpe"
      vpc_name = "workload"
      rules = [
        {
          name      = "allow-all-inbound"
          source    = "0.0.0.0/0"
          direction = "inbound"
        },
        {
          name      = "allow-all-outbound"
          source    = "0.0.0.0/0"
          direction = "outbound"
        }
      ]
    }
  ]

  validation {
    error_message = "Each security group rule must have a unique name."
    condition = length([
      for security_group in var.security_groups :
      true if length(distinct(security_group.rules.*.name)) != length(security_group.rules.*.name)
    ]) == 0
  }

  validation {
    error_message = "Security group rules can only use one of the following blocks: `tcp`, `udp`, `icmp`."
    condition = length(
      [
        for group in var.security_groups :
        true if length(
          distinct(
            flatten([
              for rule in group.rules :
              true if length(
                [
                  for type in ["tcp", "udp", "icmp"] :
                  true if rule[type] != null
                ]
              ) > 1
            ])
          )
        ) != 0
      ]
    ) == 0
  }

  validation {
    error_message = "Security group rule direction can only be `inbound` or `outbound`."
    condition = length(
      [
        for group in var.security_groups :
        true if length(
          distinct(
            flatten([
              for rule in group.rules :
              false if !contains(["inbound", "outbound"], rule.direction)
            ])
          )
        ) != 0
      ]
    ) == 0
  }

}

##############################################################################


##############################################################################
# VPE Variables
##############################################################################

variable "virtual_private_endpoints" {
  description = "Object describing VPE to be created"
  type = list(
    object({
      service_name         = string
      service_crn          = string
      cloud_object_storage = optional(bool)
      vpcs = list(
        object({
          name                = string
          subnets             = list(string)
          security_group_name = optional(string)
        })
      )
    })
  )
  default = []
}

##############################################################################


##############################################################################
# Service Instance Variables
##############################################################################

variable "service_endpoints" {
  description = "Service endpoints. Can be `public`, `private`, or `public-and-private`"
  type        = string
  default     = "private"

  validation {
    error_message = "Service endpoints can only be `public`, `private`, or `public-and-private`."
    condition     = contains(["public", "private", "public-and-private"], var.service_endpoints)
  }
}

##############################################################################