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
    name   = "slz-cs-rg"
    create = true
    }, {
    name   = "slz-management-rg"
    create = true
    }, {
    name   = "slz-workload-rg"
    create = true
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
      resource_group = "slz-management-rg"
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
      prefix         = "workload"
      resource_group = "slz-workload-rg"
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
    cos_bucket_name = "flowlogs-bucket"
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
      name               = string
      vpc_name           = string
      subnet_names       = list(string)
      ssh_keys           = list(string)
      image_name         = string
      machine_type       = string
      vsi_per_subnet     = number
      user_data          = optional(string)
      resource_group     = optional(string)
      enable_floating_ip = optional(bool)
      security_groups    = optional(list(string))
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
          name     = string
          profile  = string
          capacity = optional(number)
          iops     = optional(number)
          kms_key  = optional(string)
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
  default = []
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
    service_name = "cloud-object-storage"
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
  description = "Object describing the cloud object storage instance. Set `use_data` to false to create instance"
  type = object({
    service_name   = string
    use_data       = bool
    resource_group = string
    plan           = optional(string)
  })

  default = {
    service_name   = "cos"
    use_data       = false
    resource_group = "Default"
    plan           = "standard"
  }

  validation {
    error_message = "Plan can only be `lite` or `standard`."
    condition     = contains(["lite", "standard"], var.cos.plan)
  }
}

variable "cos_resource_keys" {
  description = "List of objects describing resource keys to create for cos instance"
  type = list(object({
    name = string
    role = string
  }))

  default = [
    {
      name = "cos-bind-key"
      role = "Writer"
    }
  ]

  validation {
    error_message = "Resource key names must be unique."
    condition     = length(distinct(var.cos_resource_keys.*.name)) == length(var.cos_resource_keys.*.name)
  }
}

variable "cos_buckets" {
  description = "List of standard buckets to be created in desired cloud object storage instance. Please note, logging and monitoring are not FS validated."
  type = list(object({
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

  default = [
    {
      name            = "dev-bucket"
      storage_class   = "standard"
      endpoint_type   = "public"
      force_delete    = true
    },
    {
      name            = "atracker-bucket"
      storage_class   = "standard"
      endpoint_type   = "public"
      force_delete    = true
    },
    {
      name            = "flowlogs-bucket"
      storage_class   = "standard"
      endpoint_type   = "public"
      kms_key         = "slz-key"
      force_delete    = true
    }
  ]

  validation {
    error_message = "COS Bucket names must be unique."
    condition     = length(distinct(var.cos_buckets.*.name)) == length(var.cos_buckets.*.name)
  }

  # https://cloud.ibm.com/docs/cloud-object-storage?topic=cloud-object-storage-classes 
  validation {
    error_message = "Storage class can only be `standard`, `vault`, `cold`, or `smart`."
    condition = length([
      for bucket in var.cos_buckets :
      bucket if contains(["standard", "vault", "cold", "smart"], bucket.storage_class)
    ]) == length(var.cos_buckets)
  }

  # https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/cos_bucket#endpoint_type 
  validation {
    error_message = "Endpoint type can only be `public`, `private`, or `direct`."
    condition = length([
      for bucket in var.cos_buckets :
      bucket if contains(["public", "private", "direct"], bucket.endpoint_type)
    ]) == length(var.cos_buckets)
  }

  validation {
    error_message = "Exactly one parameter for the bucket's location must be set. Please choose one from `single_site_location`, `region_location`, or `cross_region_location`."
    condition = length([
      for bucket in var.cos_buckets :
      bucket if length(setintersection([for key in keys(bucket) : key if lookup(bucket, key) != null], ["single_site_location", "region_location", "cross_region_location"])) <= 1
    ]) == length(var.cos_buckets)
  }

  # https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/cos_bucket#single_site_location
  validation {
    error_message = "All single site buckets must specify `ams03`, `che01`, `hkg02`, `mel01`, `mex01`, `mil01`, `mon01`, `osl01`, `par01`, `sjc04`, `sao01`, `seo01`, `sng01`, or `tor01`."
    condition = length([
      for bucket in var.cos_buckets :
      bucket if bucket.single_site_location == null
      ? true
      : contains(["ams03", "che01", "hkg02", "mel01", "mex01", "mil01", "mon01", "osl01", "par01", "sjc04", "sao01", "seo01", "sng01", "tor01"], bucket.single_site_location)
    ]) == length(var.cos_buckets)
  }

  # https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/cos_bucket#region_location
  validation {
    error_message = "All regional buckets must specify `au-syd`, `eu-de`, `eu-gb`, `jp-tok`, `us-east`, `us-south`, `ca-tor`, `jp-osa`, `br-sao`."
    condition = length([
      for bucket in var.cos_buckets :
      bucket if bucket.region_location == null
      ? true
      : contains(["au-syd", "eu-de", "eu-gb", "jp-tok", "us-east", "us-south", "ca-tor", "jp-osa", "br-sao"], bucket.region_location)
    ]) == length(var.cos_buckets)
  }

  # https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/cos_bucket#cross_region_location
  validation {
    error_message = "All cross-regional buckets must specify `us`, `eu`, `ap`."
    condition = length([
      for bucket in var.cos_buckets :
      bucket if bucket.cross_region_location == null
      ? true
      : contains(["us", "eu", "ap"], bucket.cross_region_location)
    ]) == length(var.cos_buckets)
  }

  # https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/cos_bucket#archive_rule
  validation {
    error_message = "Each archive rule must specify a type of `Glacier` or `Accelerated`."
    condition = length([
      for bucket in var.cos_buckets :
      bucket if bucket.archive_rule == null
      ? true
      : contains(["Glacier", "Accelerated"], bucket.archive_rule.type)
    ]) == length(var.cos_buckets)
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
    bucket_name           = string
    receive_global_events = bool
  })
  default = {
    resource_group        = "Default"
    bucket_name           = "atracker-bucket"
    receive_global_events = true
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
