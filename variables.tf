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

  validation {
    error_message = "Prefix must begin and end with a letter and contain only letters, numbers, and - characters."
    condition     = can(regex("^([A-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.prefix))
  }
}

variable "region" {
  description = "Region where VPC will be created. To find your VPC region, use `ibmcloud is regions` command to find available regions."
  type        = string
}

variable "tags" {
  description = "List of tags to apply to resources created by this module."
  type        = list(string)
  default     = []
}

##############################################################################


##############################################################################
# Resource Groups Variables
##############################################################################

variable "resource_groups" {
  description = "Object describing resource groups to create or reference"
  type = list(
    object({
      name   = string
      create = optional(bool)
    })
  )
  default = [{
    name = "default"
  }]

  validation {
    error_message = "Each group must have a unique name."
    condition     = length(distinct(var.resource_groups.*.name)) == length(var.resource_groups.*.name)
  }
}

##############################################################################


##############################################################################
# VPC Variables
##############################################################################

variable "vpcs" {
  description = "A map describing VPCs to be created in this repo."
  type = list(
    object({
      prefix                      = string           # VPC prefix
      resource_group              = optional(string) # Name of the group where VPC will be created
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
      prefix         = "management"
      resource_group = "default"
      use_public_gateways = {
        zone-1 = false
        zone-2 = false
        zone-3 = false
      }
      network_acls = [
        {
          name = "management-acl"
          rules = [
            {
              name        = "allow-ibm-inbound"
              action      = "allow"
              direction   = "inbound"
              destination = "10.0.0.0/8"
              source      = "161.26.0.0/16"
            },
            {
              name        = "allow-all-network-inbound"
              action      = "allow"
              direction   = "inbound"
              destination = "10.0.0.0/8"
              source      = "10.0.0.0/8"
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
            name           = "vsi-zone-1"
            cidr           = "10.10.10.0/24"
            public_gateway = true
            acl_name       = "management-acl"
          },
          {
            name           = "vpn-zone-1"
            cidr           = "10.10.20.0/24"
            public_gateway = true
            acl_name       = "management-acl"
          },
          {
            name           = "vpe-zone-1"
            cidr           = "10.10.30.0/24"
            public_gateway = true
            acl_name       = "management-acl"
          }
        ],
        zone-2 = [
          {
            name           = "vsi-zone-2"
            cidr           = "10.20.10.0/24"
            public_gateway = true
            acl_name       = "management-acl"
          },
          {
            name           = "vpe-zone-2"
            cidr           = "10.20.20.0/24"
            public_gateway = true
            acl_name       = "management-acl"
          }
        ],
        zone-3 = [
          {
            name           = "vsi-zone-3"
            cidr           = "10.30.10.0/24"
            public_gateway = true
            acl_name       = "management-acl"
          },
          {
            name           = "vpe-zone-3"
            cidr           = "10.30.20.0/24"
            public_gateway = true
            acl_name       = "management-acl"
          }
        ]
      }
    },
    {
      prefix = "workload"
      use_public_gateways = {
        zone-1 = false
        zone-2 = false
        zone-3 = false
      }
      network_acls = [
        {
          name = "workload-acl"
          rules = [
            {
              name        = "allow-ibm-inbound"
              action      = "allow"
              direction   = "inbound"
              destination = "10.0.0.0/8"
              source      = "161.26.0.0/16"
            },
            {
              name        = "allow-all-network-inbound"
              action      = "allow"
              direction   = "inbound"
              destination = "10.0.0.0/8"
              source      = "10.0.0.0/8"
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
            name           = "vsi-zone-1"
            cidr           = "10.40.10.0/24"
            public_gateway = true
            acl_name       = "workload-acl"
          },
          {
            name           = "vpn-zone-1"
            cidr           = "10.40.20.0/24"
            public_gateway = true
            acl_name       = "workload-acl"
          },
          {
            name           = "vpe-zone-1"
            cidr           = "10.40.30.0/24"
            public_gateway = true
            acl_name       = "workload-acl"
          }
        ],
        zone-2 = [
          {
            name           = "vsi-zone-2"
            cidr           = "10.50.10.0/24"
            public_gateway = true
            acl_name       = "workload-acl"
          },
          {
            name           = "vpn-zone-2"
            cidr           = "10.50.20.0/24"
            public_gateway = true
            acl_name       = "workload-acl"
          }
        ],
        zone-3 = [
          {
            name           = "vsi-zone-3"
            cidr           = "10.60.10.0/24"
            public_gateway = true
            acl_name       = "workload-acl"
          },
          {
            name           = "vpn-zone-3"
            cidr           = "10.60.20.0/24"
            public_gateway = true
            acl_name       = "workload-acl"
          }
        ]
      }
    },
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

variable "transit_gateway_resource_group" {
  description = "Name of resource group to use for transit gateway. Must be included in `var.resource_group`"
  type        = string
  default     = "default"
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
  description = "SSH Keys to use for VSI Provision. If `public_key` is not provided, the named key will be looked up from data. If a resource group name is added, it must be included in `var.resource_groups`"
  type = list(
    object({
      name           = string
      public_key     = optional(string)
      resource_group = optional(string)
    })
  )
  default = [
    {
      name           = "dev-ssh-key"
      public_key     = "<ssh public key>"
      resource_group = "default"
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
      resource_group  = optional(string)
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
    name           = "management-server"
    vpc_name       = "management"
    vsi_per_subnet = 1
    subnet_names   = ["vsi-zone-1", "vsi-zone-2", "vsi-zone-3"]
    image_name     = "ibm-ubuntu-16-04-5-minimal-amd64-1"
    machine_type   = "cx2-2x4"
    security_group = {
      name     = "management"
      vpc_name = "management"
      rules = [
        {
          name      = "allow-ibm-inbound"
          source    = "161.26.0.0/16"
          direction = "inbound"
        },
        {
          name      = "allow-sg-outbound"
          source    = "mgmt-base-security-group"
          direction = "outbound"
        },
        {
          name      = "allow-ibm-tcp-80-outbound"
          source    = "161.26.0.0/16"
          direction = "outbound"
          tcp = {
            port_min = 80
            port_max = 80
          }
        },
        {
          name      = "allow-ibm-tcp-443-outbound"
          source    = "161.26.0.0/16"
          direction = "outbound"
          tcp = {
            port_min = 443
            port_max = 443
          }
        },
        {
          name      = "allow-ibm-udp-53-outbound"
          source    = "161.26.0.0/16"
          direction = "outbound"
          udp = {
            port_min = 53
            port_max = 53
          }
        }
      ]
    },
    ssh_keys = ["management"]
  },
  {
    name           = "workload-server"
    vpc_name       = "workload"
    vsi_per_subnet = 1
    subnet_names   = ["vsi-zone-1", "vsi-zone-2", "vsi-zone-3"]
    image_name     = "ibm-ubuntu-16-04-5-minimal-amd64-1"
    machine_type   = "cx2-2x4"
    security_group = {
      name     = "workload"
      vpc_name = "workload"
      rules = [
        {
          name      = "allow-ibm-inbound"
          source    = "161.26.0.0/16"
          direction = "inbound"
        },
        {
          name      = "allow-sg-outbound"
          source    = "mgmt-base-security-group"
          direction = "outbound"
        },
        {
          name      = "allow-ibm-tcp-80-outbound"
          source    = "161.26.0.0/16"
          direction = "outbound"
          tcp = {
            port_min = 80
            port_max = 80
          }
        },
        {
          name      = "allow-ibm-tcp-443-outbound"
          source    = "161.26.0.0/16"
          direction = "outbound"
          tcp = {
            port_min = 443
            port_max = 443
          }
        },
        {
          name      = "allow-ibm-udp-53-outbound"
          source    = "161.26.0.0/16"
          direction = "outbound"
          udp = {
            port_min = 53
            port_max = 53
          }
        }
      ]
    }
    ssh_keys = ["management"]
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
      name           = string
      vpc_name       = string
      resource_group = optional(string)
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

  default = []

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
      # Ensure length is 0
      [
        # For each group in security groups
        for group in var.security_groups :
        # Return true if length isn't 0
        true if length(
          distinct(
            flatten([
              # For each rule, return true if using more than one `tcp`, `udp`, `icmp block
              for rule in group.rules :
              true if length([for type in ["tcp", "udp", "icmp"] : true if rule[type] != null]) > 1
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
      resource_group       = optional(string)
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

variable "key_protect" {
  description = "Key Protect instance variables"
  type = object({
    name           = string
    resource_group = string
    use_data       = optional(bool)
    keys = optional(
      list(
        object({
          name            = string
          root_key        = optional(bool)
          payload         = optional(string)
          key_ring        = optional(string) # Any key_ring added will be created
          force_delete    = optional(bool)
          endpoint        = optional(string) # can be public or private
          iv_value        = optional(string) # (Optional, Forces new resource, String) Used with import tokens. The initialization vector (IV) that is generated when you encrypt a nonce. The IV value is required to decrypt the encrypted nonce value that you provide when you make a key import request to the service. To generate an IV, encrypt the nonce by running ibmcloud kp import-token encrypt-nonce. Only for imported root key.
          encrypted_nonce = optional(string) # The encrypted nonce value that verifies your request to import a key to Key Protect. This value must be encrypted by using the key that you want to import to the service. To retrieve a nonce, use the ibmcloud kp import-token get command. Then, encrypt the value by running ibmcloud kp import-token encrypt-nonce. Only for imported root key.
          policies = optional(
            object({
              rotation = optional(
                object({
                  interval_month = number
                })
              )
              dual_auth_delete = optional(
                object({
                  enabled = bool
                })
              )
            })
          )
        })
      )
    )
  })
  default = {
    name           = "dev-kms"
    resource_group = "default"
    keys = [
      {
        name     = "root"
        root_key = true
        key_name = "dev-ring"
      }
    ]
  }
}

##############################################################################


##############################################################################
# atracker variables
##############################################################################

variable "use_atracker" {
  description = "Use atracker and route"
  type        = bool
  default     = false
}

variable "atracker" {
  description = "atracker variables"
  type = object({
    resource_group        = string
    bucket_name           = string
    location              = string
    target_crn            = string
    receive_global_events = bool
  })
  default = {
    resource_group        = "default"
    bucket_name           = "atracker-bucket"
    location              = "us-south"
    target_crn            = "1234"
    target_type           = "cloud_object_storage"
    cos_api_key           = "<key>"
    receive_global_events = true
  }
}

##############################################################################