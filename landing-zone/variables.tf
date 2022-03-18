##############################################################################
# Account Variables
##############################################################################

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
      name       = string
      create     = optional(bool)
      use_prefix = optional(bool)
    })
  )
  default = [{
    name = "Default"
    }, {
    name = "default"
    }, {
    name = "slz-cs-rg"
    }, {
    name = "slz-management-rg"
    }, {
    name = "slz-workload-rg"
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
      flow_logs_bucket_name       = optional(string)
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
      resource_group = "slz-management-rg"
      use_public_gateways = {
        zone-1 = false
        zone-2 = false
        zone-3 = false
      }
      flow_logs_bucket_name = "management-bucket"
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
      vpn_gateways = [
        {
          name        = "vpn"
          subnet_name = "vpn-zone-1"
          connections = []
        }
      ]
    },
    {
      prefix                = "workload"
      resource_group        = "slz-workload-rg"
      flow_logs_bucket_name = "workload-bucket"
      use_public_gateways = {
        zone-1 = false
        zone-2 = false
        zone-3 = false
      }
      network_acls = [
        {
          name              = "workload-acl"
          add_cluster_rules = true
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
            name           = "vpe-zone-2"
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
            name           = "vpe-zone-3"
            cidr           = "10.60.20.0/24"
            public_gateway = true
            acl_name       = "workload-acl"
          }
        ]
      }
      vpn_gateways = null
    }
  ]
}

variable "vpn_gateways" {
  description = "List of VPN Gateways to create."
  type = list(
    object({
      name           = string
      vpc_name       = string
      subnet_name    = string # Do not include prefix, use same name as in `var.subnets`
      mode           = optional(string)
      resource_group = optional(string)
      connections = list(
        object({
          peer_address   = string
          preshared_key  = string
          local_cidrs    = optional(list(string))
          peer_cidrs     = optional(list(string))
          admin_state_up = optional(bool)
        })
      )
    })
  )
  default = []
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
  default     = "slz-cs-rg"
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
      name           = "jv-dev-ssh-key"
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
          ssh_key.public_key if lookup(ssh_key, "public_key", null) != null
        ]
      )
      ) == length(
      [
        for ssh_key in var.ssh_keys :
        ssh_key.public_key if lookup(ssh_key, "public_key", null) != null
      ]
    )
  }
}

variable "vsi" {
  description = "A list describing VSI workloads to create"
  type = list(
    object({
      name                            = string
      vpc_name                        = string
      subnet_names                    = list(string)
      ssh_keys                        = list(string)
      image_name                      = string
      machine_type                    = string
      vsi_per_subnet                  = number
      user_data                       = optional(string)
      resource_group                  = optional(string)
      enable_floating_ip              = optional(bool)
      security_groups                 = optional(list(string))
      boot_volume_encryption_key_name = optional(string)
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
  default = [{
    name           = "management-server"
    vpc_name       = "management"
    vsi_per_subnet = 1
    subnet_names   = ["vsi-zone-1", "vsi-zone-2", "vsi-zone-3"]
    image_name     = "ibm-ubuntu-16-04-5-minimal-amd64-1"
    machine_type   = "cx2-2x4"
    block_storage_volumes = [
      {
        name           = "kms-test-volume"
        profile        = "general-purpose"
        encryption_key = "slz-key"
    }]

    security_group = {
      name     = "management"
      vpc_name = "management"
      rules = [{
        name      = "allow-ibm-inbound"
        source    = "161.26.0.0/16"
        direction = "inbound"
        },
        {
          name      = "allow-ibm-tcp-80-outbound"
          source    = "161.26.0.0/16"
          direction = "outbound"
          tcp = {
            port_min = 80
            port_max = 80
          }
          }, {
          name      = "allow-ibm-tcp-443-outbound"
          source    = "161.26.0.0/16"
          direction = "outbound"
          tcp = {
            port_min = 443
            port_max = 443
          }
          }, {
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
    ssh_keys = ["jv-dev-ssh-key"]
    }, {
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
          }, {
          name      = "allow-ibm-tcp-80-outbound"
          source    = "161.26.0.0/16"
          direction = "outbound"
          tcp = {
            port_min = 80
            port_max = 80
          }
          }, {
          name      = "allow-ibm-tcp-443-outbound"
          source    = "161.26.0.0/16"
          direction = "outbound"
          tcp = {
            port_min = 443
            port_max = 443
          }
          }, {
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
    ssh_keys = ["jv-dev-ssh-key"]
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
      service_name   = string
      service_type   = string
      resource_group = optional(string)
      vpcs = list(
        object({
          name                = string
          subnets             = list(string)
          security_group_name = optional(string)
        })
      )
    })
  )
  default = [{
    service_name = "cos"
    service_type = "cloud-object-storage"
    vpcs = [{
      name    = "management"
      subnets = ["vpe-zone-1", "vpe-zone-2", "vpe-zone-3"]
      }, {
      name    = "workload"
      subnets = ["vpe-zone-1", "vpe-zone-2", "vpe-zone-3"]
    }]
  }]
}

##############################################################################


##############################################################################
# Cloud Object Storage Variables
##############################################################################

variable "cos" {
  description = "Object describing the cloud object storage instance, buckets, and keys. Set `use_data` to false to create instance"
  type = list(
    object({
      name           = string
      use_data       = optional(bool)
      resource_group = string
      plan           = optional(string)
      buckets = list(object({
        name                  = string
        storage_class         = string
        endpoint_type         = string
        force_delete          = bool
        single_site_location  = optional(string)
        region_location       = optional(string)
        cross_region_location = optional(string)
        kms_key               = optional(string)
        allowed_ip            = optional(list(string))
        archive_rule = optional(object({
          days    = number
          enable  = bool
          rule_id = optional(string)
          type    = string
        }))
        activity_tracking = optional(object({
          activity_tracker_crn = string
          read_data_events     = bool
          write_data_events    = bool
        }))
        metrics_monitoring = optional(object({
          metrics_monitoring_crn  = string
          request_metrics_enabled = optional(bool)
          usage_metrics_enabled   = optional(bool)
        }))
      }))
      keys = optional(
        list(object({
          name = string
          role = string
        }))
      )
    })
  )

  default = [{
    name           = "cos"
    use_data       = false
    resource_group = "Default"
    plan           = "standard"
    buckets = [
      {
        name          = "workload-bucket"
        storage_class = "standard"
        kms_key       = "slz-key"
        endpoint_type = "public"
        force_delete  = true
      },
      {
        name          = "atracker-bucket"
        storage_class = "standard"
        endpoint_type = "public"
        force_delete  = true
      },
      {
        name          = "management-bucket"
        storage_class = "standard"
        endpoint_type = "public"
        kms_key       = "slz-key"
        force_delete  = true
      }
    ]
    keys = [
      {
        name = "cos-bind-key"
        role = "Writer"
      }
    ]
  }]

  validation {
    error_message = "Each COS key must have a unique name."
    condition = length(
      flatten(
        [
          for instance in var.cos :
          [
            for keys in instance.keys :
            keys.name
          ] if lookup(instance, "keys", false) != false
        ]
      )
      ) == length(
      distinct(
        flatten(
          [
            for instance in var.cos :
            [
              for keys in instance.keys :
              keys.name
            ] if lookup(instance, "keys", false) != false
          ]
        )
      )
    )
  }

  validation {
    error_message = "Plans for COS instances can only be `lite` or `standard`."
    condition = length([
      for instance in var.cos :
      true if contains(["lite", "standard"], instance.plan)
    ]) == length(var.cos)
  }

  validation {
    error_message = "COS Bucket names must be unique."
    condition = length(
      flatten([
        for instance in var.cos :
        instance.buckets.*.name
      ])
      ) == length(
      distinct(
        flatten([
          for instance in var.cos :
          instance.buckets.*.name
        ])
      )
    )
  }

  # https://cloud.ibm.com/docs/cloud-object-storage?topic=cloud-object-storage-classes 
  validation {
    error_message = "Storage class can only be `standard`, `vault`, `cold`, or `smart`."
    condition = length(
      flatten(
        [
          for instance in var.cos :
          [
            for bucket in instance.buckets :
            true if contains(["standard", "vault", "cold", "smart"], bucket.storage_class)
          ]
        ]
      )
    ) == length(flatten([for instance in var.cos : [for bucket in instance.buckets : true]]))
  }

  # https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/cos_bucket#endpoint_type 
  validation {
    error_message = "Endpoint type can only be `public`, `private`, or `direct`."
    condition = length(
      flatten(
        [
          for instance in var.cos :
          [
            for bucket in instance.buckets :
            true if contains(["public", "private", "direct"], bucket.endpoint_type)
          ]
        ]
      )
    ) == length(flatten([for instance in var.cos : [for bucket in instance.buckets : true]]))
  }

  # https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/cos_bucket#single_site_location
  validation {
    error_message = "All single site buckets must specify `ams03`, `che01`, `hkg02`, `mel01`, `mex01`, `mil01`, `mon01`, `osl01`, `par01`, `sjc04`, `sao01`, `seo01`, `sng01`, or `tor01`."
    condition = length(
      [
        for site_bucket in flatten(
          [
            for instance in var.cos :
            [
              for bucket in instance.buckets :
              bucket if lookup(bucket, "single_site_location", null) != null
            ]
          ]
        ) : site_bucket if !contains(["ams03", "che01", "hkg02", "mel01", "mex01", "mil01", "mon01", "osl01", "par01", "sjc04", "sao01", "seo01", "sng01", "tor01"], site_bucket.single_site_location)
      ]
    ) == 0
  }

  # https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/cos_bucket#region_location
  validation {
    error_message = "All regional buckets must specify `au-syd`, `eu-de`, `eu-gb`, `jp-tok`, `us-east`, `us-south`, `ca-tor`, `jp-osa`, `br-sao`."
    condition = length(
      [
        for site_bucket in flatten(
          [
            for instance in var.cos :
            [
              for bucket in instance.buckets :
              bucket if lookup(bucket, "region_location", null) != null
            ]
          ]
        ) : site_bucket if !contains(["au-syd", "eu-de", "eu-gb", "jp-tok", "us-east", "us-south", "ca-tor", "jp-osa", "br-sao"], site_bucket.region_location)
      ]
    ) == 0
  }

  # https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/cos_bucket#cross_region_location
  validation {
    error_message = "All cross-regional buckets must specify `us`, `eu`, `ap`."
    condition = length(
      [
        for site_bucket in flatten(
          [
            for instance in var.cos :
            [
              for bucket in instance.buckets :
              bucket if lookup(bucket, "cross_region_location", null) != null
            ]
          ]
        ) : site_bucket if !contains(["us", "eu", "ap"], site_bucket.cross_region_location)
      ]
    ) == 0
  }

  # https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/cos_bucket#archive_rule
  validation {
    error_message = "Each archive rule must specify a type of `Glacier` or `Accelerated`."
    condition = length(
      [
        for site_bucket in flatten(
          [
            for instance in var.cos :
            [
              for bucket in instance.buckets :
              bucket if lookup(bucket, "archive_rule", null) != null
            ]
          ]
        ) : site_bucket if !contains(["Glacier", "Accelerated"], site_bucket.archive_rule.type)
      ]
    ) == 0
  }
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

variable "key_management" {
  description = "Key Protect instance variables"
  type = object({
    name           = string
    resource_group = string
    use_data       = optional(bool)
    use_hs_crypto  = optional(bool)
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
    name           = "slz-kms"
    resource_group = "Default"
    keys = [
      {
        name     = "slz-key"
        root_key = true
        key_ring = "slz-ring"
      }
    ]
  }
}

##############################################################################


##############################################################################
# atracker variables
##############################################################################

variable "atracker" {
  description = "atracker variables"
  type = object({
    resource_group        = string
    receive_global_events = bool
    collector_bucket_name = string
  })
  default = {
    resource_group        = "Default"
    receive_global_events = true
    collector_bucket_name = "atracker-bucket"
  }
}

##############################################################################

##############################################################################
# Cluster variables
##############################################################################


variable "clusters" {
  description = "A list describing clusters workloads to create"
  type = list(
    object({
      name               = string           # Name of Cluster
      vpc_name           = string           # Name of VPC
      subnet_names       = list(string)     # List of vpc subnets for cluster
      workers_per_subnet = number           # Worker nodes per subnet. Min 2 per subnet for openshift
      machine_type       = string           # Worker node flavor
      kube_type          = string           # iks or openshift
      entitlement        = optional(string) # entitlement option for openshift
      pod_subnet         = optional(string) # Portable subnet for pods
      service_subnet     = optional(string) # Portable subnet for services
      resource_group     = string           # Resource Group used for cluster
      cos_name           = optional(string) # Name of COS instance Required only for OpenShift clusters
      kms_config = optional(
        object({
          crk_name         = string
          instance_name    = string
          private_endpoint = optional(bool)
        })
      )
      worker_pools = optional(list(
        object({
          name               = string           # Worker pool name
          vpc_name           = string           # VPC name
          workers_per_subnet = number           # Worker nodes per subnet
          flavor             = string           # Worker node flavor
          subnet_names       = list(string)     # List of vpc subnets for worker pool
          entitlement        = optional(string) # entitlement option for openshift
      })))
  }))
  default = []

  # kube_type validation
  validation {
    condition     = length([for type in flatten(var.clusters[*].kube_type) : true if type == "iks" || type == "openshift"]) == length(var.clusters)
    error_message = "Invalid value for kube_type entered. Valid values are `iks` or `openshift`."
  }

  # openshift clusters must have cos name
  validation {
    error_message = "OpenShift clusters must have a cos name associated with them for provision."
    condition = length([
      for openshift_cluster in [
        for cluster in var.clusters :
        cluster if cluster.kube_type == "openshift"
      ] : openshift_cluster if openshift_cluster.cos_name == null
    ]) == 0
  }

  # subnet_names validation
  validation {
    condition     = length([for subnet in(var.clusters[*].subnet_names) : false if length(distinct(subnet)) != length(subnet)]) == 0
    error_message = "Duplicates in var.clusters.subnet_names list. Please provide unique subnet list."
  }

  # cluster name validation
  validation {
    condition     = length(distinct([for name in flatten(var.clusters[*].name) : name])) == length(flatten(var.clusters[*].name))
    error_message = "Duplicate cluster name. Please provide unique cluster names."
  }

  # min. workers_per_subnet=2 (default pool) for openshift validation
  validation {
    condition     = length([for n in flatten(var.clusters[*]) : false if(n.kube_type == "openshift" && n.workers_per_subnet < 2)]) == 0
    error_message = "For openshift cluster workers_per_subnet needs to be 2 or more."
  }

  # worker_pool name validation
  validation {
    condition     = length([for pools in(var.clusters[*].worker_pools) : false if(length(distinct([for pool in pools : pool.name])) != length([for pool in pools : pool.name]))]) == 0
    error_message = "Duplicate worker_pool name in list var.cluster.worker_pools. Please provide unique worker_pool names."
  }

}

variable "wait_till" {
  description = "To avoid long wait times when you run your Terraform code, you can specify the stage when you want Terraform to mark the cluster resource creation as completed. Depending on what stage you choose, the cluster creation might not be fully completed and continues to run in the background. However, your Terraform code can continue to run without waiting for the cluster to be fully created. Supported args are `MasterNodeReady`, `OneWorkerNodeReady`, and `IngressReady`"
  type        = string
  default     = "IngressReady"

  validation {
    error_message = "`wait_till` value must be one of `MasterNodeReady`, `OneWorkerNodeReady`, or `IngressReady`."
    condition = contains([
      "MasterNodeReady",
      "OneWorkerNodeReady",
      "IngressReady"
    ], var.wait_till)
  }
}

##############################################################################
