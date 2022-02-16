##############################################################################
# Account Variables
# Copyright 2020 IBM
##############################################################################

# Uncomment this variable if running locally
variable ibmcloud_api_key {
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources"
  type        = string
  sensitive   = true
}

# Comment out if not running in schematics
variable TF_VERSION {
 default     = "1.0"
 type        = string
 description = "The version of the Terraform engine that's used in the Schematics workspace."
}

variable prefix {
    description = "A unique identifier need to provision resources. Must begin with a letter"
    type        = string
    default     = "gcat-multizone-schematics"

    validation  {
      error_message = "Unique ID must begin and end with a letter and contain only letters, numbers, and - characters."
      condition     = can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.prefix))
    }
}

variable region {
  description = "Region where VPC will be created"
  type        = string
  default     = "us-south"
}

variable resource_group {
    description = "Name of resource group where all infrastructure will be provisioned. "
    type        = string

    validation  {
      error_message = "Unique ID must begin and end with a letter and contain only letters, numbers, and - characters."
      condition     = can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.resource_group))
    }
}

##############################################################################


##############################################################################
# VPC Variables
##############################################################################

variable vpcs {
    description = "A map describing VPCs to be created in this repo"
    type        = list(
        object({
            prefix                      = string            # VPC prefix
            use_manual_address_prefixes = optional(bool)
            classic_access              = optional(bool)
            default_network_acl_name    = optional(string)
            default_security_group_name = optional(string)
            default_routing_table_name  = optional(string)
            address_prefixes            = optional(
                object({
                    zone-1 = optional(list(string))
                    zone-2 = optional(list(string))
                    zone-3 = optional(list(string))
                })
            )
            network_acls               = list(
                object({
                  name                = string
                  network_connections = optional(list(string))
                  add_cluster_rules   = optional(bool)
                  rules               = list(
                    object({
                      name        = string
                      action      = string
                      destination = string
                      direction   = string
                      source      = string
                      tcp         = optional(
                        object({
                          port_max        = optional(number)
                          port_min        = optional(number)
                          source_port_max = optional(number)
                          source_port_min = optional(number)
                        })
                      )
                      udp         = optional(
                        object({
                          port_max        = optional(number)
                          port_min        = optional(number)
                          source_port_max = optional(number)
                          source_port_min = optional(number)
                        })
                      )
                      icmp        = optional(
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
            prefix              = "management"
            use_public_gateways = {
                zone-1 = true
                zone-2 = true
                zone-3 = true
            }
            network_acls        = [
              { 
                name                = "vpc-acl"
                add_cluster_rules   = true
                rules               = [
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
            subnets             = {
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
            prefix              = "workload"
            use_public_gateways = {
                zone-1 = true
                zone-2 = true
                zone-3 = true
            }
            network_acls        = [
              { 
                name                = "vpc-acl"
                add_cluster_rules   = true
                rules               = [
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
            subnets             = {
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
# VSI Variables
##############################################################################

variable vsi {
  description = "A list describing VSI workloads to create"
  type        = list(
    object({
      name           = string
      vpc_name       = string
      subnet_names   = list(string)
      ssh_public_key = optional(string)
      ssh_key_name   = optional(string)
      image_name     = string
      machine_type   = string
      vsi_per_subnet = number
      security_group = optional(
        object({
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
      )
      load_balancers = list(
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
    })
  )
  default = [
    {
      name           = "test-vsi"
      vpc_name       = "management"
      subnet_names   = ["subnet-a", "subnet-c"]
      ssh_public_key = "<key>"
      image_name     = "ibm-centos-7-6-minimal-amd64-2"
      machine_type   = "bx2-8x32"
      vsi_per_subnet = 2
      security_group = {
        name  = "test"
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
      load_balancers = [
        {
          name              = "test"
          type              = "public"
          listener_port     = 80
          listener_protocol = "http"
          connection_limit  = 0
          algorithm         = "round_robin"
          protocol          = "http"
          health_delay      = 5
          health_retries    = 10
          health_timeout    = 30
          health_type       = "http"
          pool_member_port  = 80
        }
      ]
    },
    {
      name           = "workload-vsi"
      vpc_name       = "workload"
      subnet_names   = ["subnet-a", "subnet-b", "subnet-c"]
      ssh_public_key = "<key>"
      image_name     = "ibm-centos-7-6-minimal-amd64-2"
      machine_type   = "bx2-8x32"
      vsi_per_subnet = 1
      security_group = {
        name  = "test"
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
      load_balancers = []
    }
    
  ]
}

##############################################################################