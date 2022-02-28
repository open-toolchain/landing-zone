# Secure Landing Zone

This module creates a secure landing zone within a single region.

---

## Table of Contents

1. [VPC](#vpc)
2. [Flow Logs](#flow-Logs)
3. [Transit Gateway](#transit-gateway)
4. [Security Groups](#security-groups)
5. [Virtual Servers](#virtual-servers)
6. [Virtual Private Endpoints](#virtual-private-endpoints)
7. [Module Variables](#module-variables)
8. [Contributing](#contributing)

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
      use_manual_address_prefixes = optional(bool)    # Optionally assign prefixes to VPC manually. By default this is false, and prefixes will be created along with subnets
      classic_access              = optional(bool)    # Optionally allow VPC to access classic infrastructure network
      default_network_acl_name    = optional(string)  # Override default ACL name
      default_security_group_name = optional(string)  # Override default VPC security group name
      default_routing_table_name  = optional(string)  # Override default VPC routing table name

      ##############################################################################
      # Use `address_prefixes` only if `use_manual_address_prefixes` is true
      # otherwise prefixes will not be created
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

### Virtual Servers Variable

The virtual server variable type is as follows:

```terraform
list(
    object({
      name            = string                  # Name to be used for each VSI created 
      vpc_name        = string                  # Name of VPC from `vpcs` variable
      subnet_names    = list(string)            # Names of subnets where VSI will be provisioned
      ssh_key_name    = optional(string)        # Name of the SSH key for VSI creation
      image_name      = string                  # Name of the image for VSI, use `ibmcloud is images` to view
      machine_type    = string                  # Name of machine type. Use `ibmcloud is in-prs` to view 
      vsi_per_subnet  = number                  # Number of identical VSI to be created on each subnet
      user_data       = optional(string)        # User data to initialize instance
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

## Virtual Private Endpoints

Virtual Private endpoints can be created for any number of services. Virtual private endpoint components can be found in [vpe.tf](vpe.tf).

---

## Module Variables

Name                        | Type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | Description                                                                                                                               | Sensitive | Default
--------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
ibmcloud_api_key            | string                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | The IBM Cloud platform API key needed to deploy IAM enabled resources.                                                                    | true      | 
prefix                      | string                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | A unique identifier for resources. Must begin with a letter. This prefix will be prepended to any resources provisioned by this template. |           | gcat-multizone-schematics
region                      | string                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | Region where VPC will be created. To find your VPC region, use `ibmcloud is regions` command to find available regions.                   |           | us-south
resource_group              | string                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | Name of resource group where all infrastructure will be provisioned.                                                                      |           | 
tags                        | list(string)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | List of tags to apply to resources created by this module.                                                                                |           | []
vpcs                        | list( object({ prefix = string use_manual_address_prefixes = optional(bool) classic_access = optional(bool) default_network_acl_name = optional(string) default_security_group_name = optional(string) default_routing_table_name = optional(string) address_prefixes = optional( object({ zone-1 = optional(list(string)) zone-2 = optional(list(string)) zone-3 = optional(list(string)) }) ) network_acls = list( object({ name = string add_cluster_rules = optional(bool) rules = list( object({ name = string action = string destination = string direction = string source = string tcp = optional( object({ port_max = optional(number) port_min = optional(number) source_port_max = optional(number) source_port_min = optional(number) }) ) udp = optional( object({ port_max = optional(number) port_min = optional(number) source_port_max = optional(number) source_port_min = optional(number) }) ) icmp = optional( object({ type = optional(number) code = optional(number) }) ) }) ) }) ) use_public_gateways = object({ zone-1 = optional(bool) zone-2 = optional(bool) zone-3 = optional(bool) }) subnets = object({ zone-1 = list(object({ name = string cidr = string public_gateway = optional(bool) acl_name = string })) zone-2 = list(object({ name = string cidr = string public_gateway = optional(bool) acl_name = string })) zone-3 = list(object({ name = string cidr = string public_gateway = optional(bool) acl_name = string })) }) }) ) | A map describing VPCs to be created in this repo.                                                                                         |           | [<br>{<br>prefix = "management"<br>use_public_gateways = {<br>zone-1 = true<br>zone-2 = true<br>zone-3 = true<br>}<br>network_acls = [<br>{<br>name = "vpc-acl"<br>add_cluster_rules = true<br>rules = [<br>{<br>name = "allow-all-inbound"<br>action = "allow"<br>direction = "inbound"<br>destination = "0.0.0.0/0"<br>source = "0.0.0.0/0"<br>},<br>{<br>name = "allow-all-outbound"<br>action = "allow"<br>direction = "outbound"<br>destination = "0.0.0.0/0"<br>source = "0.0.0.0/0"<br>}<br>]<br>}<br>]<br>subnets = {<br>zone-1 = [<br>{<br>name = "subnet-a"<br>cidr = "10.10.10.0/24"<br>public_gateway = true<br>acl_name = "vpc-acl"<br>}<br>],<br>zone-2 = [<br>{<br>name = "subnet-b"<br>cidr = "10.20.10.0/24"<br>public_gateway = true<br>acl_name = "vpc-acl"<br>}<br>],<br>zone-3 = [<br>{<br>name = "subnet-c"<br>cidr = "10.30.10.0/24"<br>public_gateway = true<br>acl_name = "vpc-acl"<br>}<br>]<br>}<br>},<br>{<br>prefix = "workload"<br>use_public_gateways = {<br>zone-1 = true<br>zone-2 = true<br>zone-3 = true<br>}<br>network_acls = [<br>{<br>name = "vpc-acl"<br>add_cluster_rules = true<br>rules = [<br>{<br>name = "allow-all-inbound"<br>action = "allow"<br>direction = "inbound"<br>destination = "0.0.0.0/0"<br>source = "0.0.0.0/0"<br>},<br>{<br>name = "allow-all-outbound"<br>action = "allow"<br>direction = "outbound"<br>destination = "0.0.0.0/0"<br>source = "0.0.0.0/0"<br>}<br>]<br>}<br>]<br>subnets = {<br>zone-1 = [<br>{<br>name = "subnet-a"<br>cidr = "10.40.10.0/24"<br>public_gateway = true<br>acl_name = "vpc-acl"<br>}<br>],<br>zone-2 = [<br>{<br>name = "subnet-b"<br>cidr = "10.50.10.0/24"<br>public_gateway = true<br>acl_name = "vpc-acl"<br>}<br>],<br>zone-3 = [<br>{<br>name = "subnet-c"<br>cidr = "10.60.10.0/24"<br>public_gateway = true<br>acl_name = "vpc-acl"<br>}<br>]<br>}<br>}<br>]
flow_logs                   | object({ cos_bucket_name = string active = bool })                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | List of variables for flow log to connect to each VSI instance. Set `use` to false to disable flow logs.                                  |           | {<br>cos_bucket_name = "jv-dev-bucket"<br>active = true<br>}
enable_transit_gateway      | bool                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | Create transit gateway                                                                                                                    |           | true
transit_gateway_connections | list(string)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | Transit gateway vpc connections. Will only be used if transit gateway is enabled.                                                         |           | [<br>"management",<br>"workload"<br>]
ssh_public_key              | string                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | Public ssh key to use in VSI provision                                                                                                    |           | 
vsi                         | list( object({ name = string vpc_name = string subnet_names = list(string) ssh_key_name = optional(string) image_name = string machine_type = string vsi_per_subnet = number user_data = optional(string) security_groups = optional(list(string)) security_group = optional( object({ name = string rules = list( object({ name = string direction = string source = string tcp = optional( object({ port_max = number port_min = number }) ) udp = optional( object({ port_max = number port_min = number }) ) icmp = optional( object({ type = number code = number }) ) }) ) }) ) block_storage_volumes = optional(list( object({ name = string profile = string capacity = optional(number) iops = optional(number) encryption_key = optional(string) }) )) load_balancers = list( object({ name = string type = string listener_port = number listener_protocol = string connection_limit = number algorithm = string protocol = string health_delay = number health_retries = number health_timeout = number health_type = string pool_member_port = string security_group = optional( object({ name = string rules = list( object({ name = string direction = string source = string tcp = optional( object({ port_max = number port_min = number }) ) udp = optional( object({ port_max = number port_min = number }) ) icmp = optional( object({ type = number code = number }) ) }) ) }) ) }) ) }) )                                                              | A list describing VSI workloads to create                                                                                                 |           | [<br>{<br>name = "test-vsi"<br>vpc_name = "management"<br>subnet_names = ["subnet-a",<br>"subnet-c"]<br>image_name = "ibm-centos-7-6-minimal-amd64-2"<br>machine_type = "bx2-8x32"<br>vsi_per_subnet = 2<br>security_group = {<br>name = "test"<br>rules = [<br>{<br>name = "allow-all-inbound"<br>source = "0.0.0.0/0"<br>direction = "inbound"<br>},<br>{<br>name = "allow-all-outbound"<br>source = "0.0.0.0/0"<br>direction = "outbound"<br>}<br>]<br>}<br>block_storage_volumes = [{<br>name = "one"<br>profile = "general-purpose"<br>},<br>{<br>name = "two"<br>profile = "general-purpose"<br>}]<br>load_balancers = [<br>{<br>name = "test"<br>type = "public"<br>listener_port = 80<br>listener_protocol = "http"<br>connection_limit = 0<br>algorithm = "round_robin"<br>protocol = "http"<br>health_delay = 10<br>health_retries = 10<br>health_timeout = 5<br>health_type = "http"<br>pool_member_port = 80<br>}<br>]<br>}<br>]
security_groups             | list( object({ name = string vpc_name = string rules = list( object({ name = string direction = string source = string tcp = optional( object({ port_max = number port_min = number }) ) udp = optional( object({ port_max = number port_min = number }) ) icmp = optional( object({ type = number code = number }) ) }) ) }) )                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | Security groups for VPC                                                                                                                   |           | [<br>{<br>name = "workload-vpe"<br>vpc_name = "workload"<br>rules = [<br>{<br>name = "allow-all-inbound"<br>source = "0.0.0.0/0"<br>direction = "inbound"<br>},<br>{<br>name = "allow-all-outbound"<br>source = "0.0.0.0/0"<br>direction = "outbound"<br>}<br>]<br>}<br>]
virtual_private_endpoints   | list( object({ service_name = string service_crn = string cloud_object_storage = optional(bool) vpcs = list( object({ name = string subnets = list(string) security_group_name = optional(string) }) ) }) )                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | Object describing VPE to be created                                                                                                       |           | [<br>{<br>service_name = "dbaas"<br>service_crn = "1234"<br>vpcs = [<br>{<br>name = "management"<br>subnets = ["subnet-a",<br>"subnet-c"]<br>security_group_name = "workload-vpe"<br>},<br>{<br>name = "workload"<br>subnets = ["subnet-b"]<br>}<br>]<br>},<br>{<br>service_name = "rabbitmq"<br>service_crn = "1234"<br>vpcs = [<br>{<br>name = "management"<br>subnets = ["subnet-a",<br>"subnet-c"]<br>},<br>{<br>name = "workload"<br>subnets = ["subnet-b"]<br>}<br>]<br>}<br>]


---

## Contributing

Create feature branches to add additional components. To integrate code changes create a pull request and tag @Jennifer-Valle.

If additional variables or added or existing variables are changed, update the [Module Variables](##module-variables) table. To automate this process, use the nodejs package [tfmdcli](https://www.npmjs.com/package/tfmdcli)

Run `terraform fmt` on your codebase before opening pull requests