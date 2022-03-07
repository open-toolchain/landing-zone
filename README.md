# Secure Landing Zone

This module creates a secure landing zone within a single region.

---

## Table of Contents

- [Secure Landing Zone](#secure-landing-zone)
  - [Table of Contents](#table-of-contents)
  - [VPC](#vpc)
    - [VPCs Variable](#vpcs-variable)
  - [Flow Logs](#flow-logs)
  - [Transit Gateway](#transit-gateway)
  - [Security Groups](#security-groups)
    - [Security Groups Variable](#security-groups-variable)
  - [Virtual Servers](#virtual-servers)
    - [VPC SSH Keys](#vpc-ssh-keys)
    - [SSH Keys Variable](#ssh-keys-variable)
    - [Virtual Servers Variable](#virtual-servers-variable)
  - [Cluster and Worker pool](#cluster-and-worker-pool)
  - [IBM Cloud Services](#ibm-cloud-services)
  - [Virtual Private Endpoints](#virtual-private-endpoints)
  - [IBM Cloud Services](#ibm-cloud-services-1)
    - [Cloud Object Storage](#cloud-object-storage)
  - [Module Variables](#module-variables)
  - [Contributing](#contributing)
  - [Terraform Language Resources](#terraform-language-resources)

---

## VPC

![vpc-module](./.docs/vpc-module.png)

This template allows users to create any number of VPCs in a single region. The VPC network and components are created by the [Cloud Schematics VPC module](https://github.com/Cloud-Schematics/multizone-vpc-module). VPC components can be found in [main.tf](./main.tf)

### VPCs Variable

The list of VPCs from the `vpcs` variable is transformed into a map, allowing for additions and deletion of resources without forcing updates. The VPC Network includes:

- VPC
- Subnets
- Network ACLs
- Public Gateways
- VPN Gateway and Gateway Connections

The type of the VPC Variable is as follows:

```terraform
  type = list(
    object({
      prefix                      = string            # A unique prefix that will prepend all components in the VPC
      resource_group              = optional(string)  # Name of the resource group to use for VPC. Must by in `var.resource_groups`
      use_manual_address_prefixes = optional(bool)    # Optionally assign prefixes to VPC manually. By default this is false, and prefixes will be created along with subnets
      classic_access              = optional(bool)    # Optionally allow VPC to access classic infrastructure network
      default_network_acl_name    = optional(string)  # Override default ACL name
      default_security_group_name = optional(string)  # Override default VPC security group name
      default_routing_table_name  = optional(string)  # Override default VPC routing table name

      ##############################################################################
      # Use `address_prefixes` only if `use_manual_address_prefixes` is true
      # otherwise prefixes will not be created. Use only if you need to manage
      # prefixes manually.
      ##############################################################################

      address_prefixes = optional(
        object({
          zone-1 = optional(list(string))
          zone-2 = optional(list(string))
          zone-3 = optional(list(string))
        })
      )

      ##############################################################################

      ##############################################################################
      # List of network ACLs to create with VPC
      ##############################################################################

      network_acls = list(
        object({
          name                = string         # Name of ACL, this can be referenced by subnets to be connected on creation
          add_cluster_rules   = optional(bool) # Automatically add to ACL rules needed to allow cluster provisioning from private service endpoints

          ##############################################################################
          # List of rules to add to the ACL, by default all inbound and outbound traffic
          # will be allowed. By default, ACLs have a limit of 50 rules.
          ##############################################################################

          rules = list(
            object({
              name        = string # Name of ACL rule
              action      = string # Allow or deny traffic
              direction   = string # Inbound or outbound
              destination = string # Destination CIDR block
              source      = string # Source CIDR block

              ##############################################################################
              # Optionally the rule can be created for TCP, UDP, or ICMP traffic.
              # Only ONE of the following blocks can be used in a single ACL rule
              ##############################################################################

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
            ##############################################################################
          )
        })
      )

      ##############################################################################


      ##############################################################################
      # Public Gateways
      # For each `zone` that is set to `true`, a public gateway will be created in
      # That zone
      ##############################################################################

      use_public_gateways = object({
        zone-1 = optional(bool)
        zone-2 = optional(bool)
        zone-3 = optional(bool)
      })

      ##############################################################################


      ##############################################################################
      # Object for subnets to be created in each zone, each zone can have any number
      # of subnets
      #
      # Each subnet accepts the four following arguments:
      # * name           - Name of the subnet
      # * cidr           - CIDR block for the subnet
      # * public_gateway - Optionally add a public gateway. This works only if the zone
      #                    for `use_public_gateway` is set to `true`
      # * acl_name       - Name of ACL to be attached. Name must be found in
      #                    `network_acl` object
      ##############################################################################

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

      ##############################################################################

    })
  )
  ##############################################################################
```

---

## Flow Logs

By default, a flow logs collector will be attached to each VPC.

Flow logs resources can be found in [main.tf](./main.tf)

---

## Transit Gateway

A transit gateway connecting any number of VPC to the same network can optionally be created by setting the `enable_transit_gateway` variable to `true`. A connection will be dynamically created for each vpc specified in the `transit_gateway_connections` variable.

Transit Gateway resource can be found in `transit_gateway.tf`.

---

## Security Groups

This module can provision any number of security groups within any of the provisioned VPC.

Security Group components can be found in [security_groups.tf](./security_groups.tf).

### Security Groups Variable

The `security_group` variable allows for the dynamic creation of security groups. This list is converted into a map before provision to ensure that changes, updates, and deletions won't impact other existing resources.

The `security_group` variable type is as follows:

```terraform
  list(
    object({
      name     = string # Name for each security group
      vpc_name = string # The group will be created. Only VPCs from `var.vpc` can be used

      ##############################################################################
      # List of rules to be added to the security group
      ##############################################################################

      rules = list(
        object({
          name      = string # Name of the rule
          direction = string # Inbound or outbound
          source    = string # Source CIDR to allow

          ##############################################################################
          # Optionally, security groups can allow ONE of the following blocks
          # additional rules will have to be created for different types of traffic
          ##############################################################################

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

        ##############################################################################

      )

      ##############################################################################
    })
  )
```

---

## Virtual Servers

![Virtual Servers](./.docs/vsi-lb.png)

This module uses the [Cloud Schematics VSI Module](https://github.com/Cloud-Schematics/vsi-module) to let users create any number of VSI workloads. The VSI Module covers the following resources:

- Virtual Server Instances
- Block Storage for those Instances
- VPC Load Balancers for those instances

Virtual server components can be found in [virual_servers.tf](./virtual_servers.tf)

### VPC SSH Keys

This Template allows users to create or get from data any number of VPC SSH Keys using the `ssh_keys` variable.

### SSH Keys Variable

Users can add a name and optionally a public key. If `public_key` is not provided, the SSH Key will be retrieved using a `data` block

```terraform
  type = list(
    object({
      name           = string
      public_key     = optional(string)
      resource_group = optional(string) # Must be in var.resource_groups
    })
  )
```

### Virtual Servers Variable

The virtual server variable type is as follows:

```terraform
list(
    object({
      name            = string                  # Name to be used for each VSI created
      vpc_name        = string                  # Name of VPC from `vpcs` variable
      subnet_names    = list(string)            # Names of subnets where VSI will be provisioned
      ssh_keys        = list(string)            # List of SSH Keys from `var.ssh_keys` to use when provisioning.
      image_name      = string                  # Name of the image for VSI, use `ibmcloud is images` to view
      machine_type    = string                  # Name of machine type. Use `ibmcloud is in-prs` to view
      vsi_per_subnet  = number                  # Number of identical VSI to be created on each subnet
      user_data       = optional(string)        # User data to initialize instance
      resource_group  = optional(string)        # Name of resource group where VSI will be provisioned, must be in `var.resource_groups`
      security_groups = optional(list(string))  # Optional Name of additional security groups from `var.security groups` to add to VSI

      ##############################################################################
      # When creating VSI, users can optionally create a new security group for
      # those instances. These fields function the same as in `var.security_groups`
      ##############################################################################

      security_group  = optional(
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

      ##############################################################################

      ##############################################################################
      # Optionally block storage volumes can be created. A volume from this list
      # will be created and attached to each VSI
      ##############################################################################

      block_storage_volumes = optional(list(
        object({
          name           = string           # Volume name
          profile        = string           # Profile
          capacity       = optional(number) # Capacity
          iops           = optional(number) # IOPs
          encryption_key = optional(string) # Optionally provide kms key
        })
      ))

      ##############################################################################

      ##############################################################################
      # Any number of VPC Load Balancers
      ##############################################################################

      load_balancers = list(
        object({
          name              = string # Name of the load balancer
          type              = string # Can be public or private
          listener_port     = number # Port for front end listener
          listener_protocol = string # Protocol for listener. Can be `tcp`, `http`, or `https`
          connection_limit  = number # Connection limit
          algorithm         = string # Back end Pool algorithm can only be `round_robin`, `weighted_round_robin`, or `least_connections`.
          protocol          = string # Back End Pool Protocol can only be `http`, `https`, or `tcp`
          health_delay      = number # Health delay for back end pool
          health_retries    = number # Health retries for back end pool
          health_timeout    = number # Health timeout for back end pool
          health_type       = string # Load Balancer Pool Health Check Type can only be `http`, `https`, or `tcp`.
          pool_member_port  = string # Listener port

          ##############################################################################
          # A security group can optionally be created and attached to each load
          # balancer
          ##############################################################################

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

          ##############################################################################
        })
      )

      ##############################################################################

    })
  )
```

---

## Cluster and Worker pool

You can create as many `iks` or `openshift` clusters and worker pools on vpc. Cluster variable type is as follows:

For `ROKS` clusters, ensure public gateways are enabled to allow your cluster to correctly provision ingress ALBs.

```
list(
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
```

---

## IBM Cloud Services

---

## Virtual Private Endpoints

Virtual Private endpoints can be created for any number of services. Virtual private endpoint components can be found in [vpe.tf](vpe.tf).

---

## IBM Cloud Services

### Cloud Object Storage

This module can provision a Cloud Object Storage instance or retrieve an existing Cloud Object Storage instance, then create any number of buckets within the desired instance. 

Cloud Object Storage components can be found in cos.tf. 

## Module Variables

| Name                        | Description                                                                                                                               |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| ibmcloud_api_key            | The IBM Cloud platform API key needed to deploy IAM enabled resources.                                                                    |
| prefix                      | A unique identifier for resources. Must begin with a letter. This prefix will be prepended to any resources provisioned by this template. |
| region                      | Region where VPC will be created. To find your VPC region, use `ibmcloud is regions` command to find available regions.                   |
| resource_group              | Name of resource group where all infrastructure will be provisioned.                                                                      |
| tags                        | List of tags to apply to resources created by this module.                                                                                |
| vpcs                        | A map describing VPCs to be created in this repo.                                                                                         |
| flow_logs                   | List of variables for flow log to connect to each VSI instance. Set `use` to false to disable flow logs.                                  |
| enable_transit_gateway      | Create transit gateway                                                                                                                    |
| transit_gateway_connections | Transit gateway vpc connections. Will only be used if transit gateway is enabled.                                                         |
| ssh_keys                    | SSH Keys to use for VSI Provision. If `public_key` is not provided, the named key will be looked up from data.                            |
| vsi                         | A list describing VSI workloads to create                                                                                                 |
| security_groups             | Security groups for VPC                                                                                                                   |
| virtual_private_endpoints   | Object describing VPE to be created                                                                                                       |
| use_atracker                | Use atracker and route                                                                                                                    |
| atracker                    | atracker variables                                                                                                                        |
| resource_groups             | A list of existing resource groups to reference and new groups to create                                                                  |
| clusters                    | A list of clusters on vpc. Also can add list of worker_pools to the clusters                                                              |
| cos                         | Object describing the cloud object storage instance. Set `use_data` to false to create instance                                           |
| cos_resource_keys           | List of objects describing resource keys to create for cos instance                                                                       |
| cos_authorization_policies  | List of authorization policies to be created for cos instance                                                                             |
| cos_buckets                 | List of standard buckets to be created in desired cloud object storage instance                                                           |

---

## Contributing

Create feature branches to add additional components. To integrate code changes create a pull request and tag @Jennifer-Valle.

If additional variables or added or existing variables are changed, update the [Module Variables](##module-variables) table. To automate this process, use the nodejs package [tfmdcli](https://www.npmjs.com/package/tfmdcli)

Run `terraform fmt` on your codebase before opening pull requests

---

## Terraform Language Resources

- [Terraform Functions](https://www.terraform.io/language/functions)
- [Using the \* Operator (splat operator)](https://www.terraform.io/language/expressions/splat)
- [Custom Variable Validation Rules](https://www.terraform.io/language/values/variables#custom-validation-rules)
