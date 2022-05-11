##############################################################################
# Dynamically Create Default Configuration
##############################################################################

locals {
  # If override is true, parse the JSON from override.json otherwise parse empty string
  # Empty string is used to avoid type conflicts with unary operators
  override = jsondecode(var.override ? file("./override.json") : "{}")

  ##############################################################################
  # Dynamic configuration for landing zone environment
  ##############################################################################

  config = {

    ##############################################################################
    # Create a resource group for each group in the list, and for each VPC
    # get default, Default and hs crypto if included. 
    ##############################################################################

    resource_groups = [
      for group in distinct(concat(local.resource_group_list, local.vpc_list)) :
      {
        name   = contains(local.dynamic_rg_list, group) ? group : "${var.prefix}-${group}-rg"
        create = contains(local.dynamic_rg_list, group) ? false : true
      }
    ]

    ##############################################################################

    ##############################################################################
    # SSH Keys
    # > Add ssh public key to config
    ##############################################################################

    ssh_keys = [
      {
        name       = "ssh-key"
        public_key = var.ssh_public_key
      }
    ]

    ##############################################################################

    ##############################################################################
    # Create one VPC for each name in VPC variable
    ##############################################################################
    vpcs = [
      for network in local.vpc_list :
      {
        prefix                = network
        resource_group        = "${var.prefix}-${network}-rg"
        flow_logs_bucket_name = "${network}-bucket"
        address_prefixes = {
          # Address prefixes need to be set for edge vpc, otherwise will be empty array
          zone-1 = local.vpc_use_edge_prefixes[network]["zone-1"]
          zone-2 = local.vpc_use_edge_prefixes[network]["zone-2"]
          zone-3 = local.vpc_use_edge_prefixes[network]["zone-3"]
        }
        default_security_group_rules = []
        network_acls = [
          {
            name = "${network}-acl"
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
        use_public_gateways = {
          zone-1 = false
          zone-2 = false
          zone-3 = false
        }
        ##############################################################################
        # Dynamically create subnets for each VPC and each zone.
        # > if the VPC is first in the list, it will create a VPN subnet tier in
        #   zone 1
        # > otherwise two VPC tiers are created `vsi` and `vpe`
        # > subnet CIDRs are dynamically calculated based on the index of the VPC
        #   network, the zone, and the tier
        ##############################################################################
        subnets = {
          for zone in [1, 2, 3] :
          "zone-${zone}" => [
            for subnet in local.vpc_subnet_tiers[network]["zone-${zone}"] :
            {
              name = "${subnet}-zone-${zone}"
              cidr = (
                # If using bastion and is a bastion subnet in vpc 0
                local.use_bastion && contains(local.bastion_tiers, subnet) && network == local.vpc_list[0]
                # Create bastion CIDR
                ? "10.${zone + 4}.${1 + index(local.bastion_tiers, subnet)}0.0/24"
                # Otherwise create regular network CIDR
                : "10.${zone + (index(var.vpcs, network) * 3)}0.${1 + index(["vsi", "vpe", "vpn"], subnet)}0.0/24"
              )
              public_gateway = false
              acl_name       = "${network}-acl"
            }
          ]
        }
        ##############################################################################
      }
    ]
    ##############################################################################

    ##############################################################################
    # Transit Gateway Variables
    ##############################################################################
    enable_transit_gateway         = true
    transit_gateway_resource_group = "${var.prefix}-service-rg"
    transit_gateway_connections    = local.vpc_list
    ##############################################################################

    ##############################################################################
    # Object Storage Variables
    ##############################################################################
    object_storage = [
      # Activity Tracker COS instance
      {
        name           = "atracker-cos"
        use_data       = false
        resource_group = "${var.prefix}-service-rg"
        plan           = "standard"
        buckets = [
          {
            name          = "atracker-bucket"
            storage_class = "standard"
            endpoint_type = "public"
            kms_key       = "${var.prefix}-atracker-key"
            force_delete  = true
          }
        ]
        # Key is needed to initialize actibity tracker
        keys = [{
          name        = "cos-bind-key"
          role        = "Writer"
          enable_HMAC = false
        }]
      },
      # COS instance for everything else
      {
        name           = "cos"
        use_data       = false
        resource_group = "${var.prefix}-service-rg"
        plan           = "standard"
        buckets = [
          # Create one flow log bucket for each VPC network
          for network in local.vpc_list :
          {
            name          = "${network}-bucket"
            storage_class = "standard"
            kms_key       = "${var.prefix}-slz-key"
            endpoint_type = "public"
            force_delete  = true
          }
        ]
        keys = []
      }
    ]
    ##############################################################################

    ##############################################################################
    # Key Management variables
    ##############################################################################
    key_management = {
      name           = var.hs_crypto_instance_name == null ? "${var.prefix}-slz-kms" : var.hs_crypto_instance_name
      resource_group = var.hs_crypto_resource_group == null ? "${var.prefix}-service-rg" : var.hs_crypto_resource_group
      use_hs_crypto  = var.hs_crypto_instance_name == null ? false : true
      keys = [
        # Create encryption keys for landing zone, activity tracker, and vsi boot volume
        for service in ["slz", "atracker", "vsi-volume"] :
        {
          name     = "${var.prefix}-${service}-key"
          root_key = true
          key_ring = "${var.prefix}-slz-ring"
        }
      ]
    }
    ##############################################################################

    ##############################################################################
    # Virtual Private endpoints
    ##############################################################################
    virtual_private_endpoints = [{
      service_name = "cos"
      service_type = "cloud-object-storage"
      vpcs = [
        # Create VPE for each VPC in VPE tier
        for network in local.vpc_list :
        {
          name    = network
          subnets = ["vpe-zone-1", "vpe-zone-2", "vpe-zone-3"]
        }
      ]
    }]
    ##############################################################################

    ##############################################################################
    # Activity Tracker Config
    ##############################################################################
    atracker = {
      resource_group        = "${var.prefix}-service-rg"
      receive_global_events = true
      collector_bucket_name = "atracker-bucket"
      add_route             = var.add_atracker_route
    }
    ##############################################################################

    ##############################################################################
    # VSI Configuration
    ##############################################################################
    vsi = [
      # Create an identical VSI deployment in each VPC
      for network in var.vpcs :
      {
        name                            = "${network}-server"
        vpc_name                        = network
        resource_group                  = "${var.prefix}-${network}-rg"
        subnet_names                    = ["vsi-zone-1", "vsi-zone-2", "vsi-zone-3"]
        image_name                      = var.vsi_image_name
        vsi_per_subnet                  = 1
        machine_type                    = var.vsi_instance_profile
        boot_volume_encryption_key_name = "${var.prefix}-vsi-volume-key"
        security_group = {
          name     = network
          vpc_name = network
          rules = flatten([
            # Create single array from dynamically generated and static arrays
            [
              {
                name      = "allow-ibm-inbound"
                source    = "161.26.0.0/16"
                direction = "inbound"
              }
            ],
            # Dynamically create rule to allow inbound and outbound network traffic
            [
              for direction in ["inbound", "outbound"] :
              [
                {
                  name      = "allow-vpc-${direction}"
                  source    = "10.0.0.0/8"
                  direction = direction
                }

              ]
            ],
            # For each port in the list, create an inbound rule to allow traffic out to IBM CIDR
            [
              for port in [53, 80, 443] :
              {
                name      = "allow-ibm-tcp-${port}-outbound"
                source    = "161.26.0.0/16"
                direction = "outbound"
                tcp = {
                  port_min = port
                  port_max = port
                }
              }
            ]
          ])
        },
        ssh_keys = ["ssh-key"]
      }
    ]
    ##############################################################################

    ##############################################################################
    # VPN Gateway
    # > Create a gateway in first vpc if bastion not enabled    
    ##############################################################################

    vpn_gateways = !local.use_bastion ? [
      {
        name           = "${local.vpc_list[0]}-gateway"
        vpc_name       = "${local.vpc_list[0]}"
        subnet_name    = "vpn-zone-1"
        resource_group = "${var.prefix}-${local.vpc_list[0]}-rg"
        connections    = []
      }
    ] : []

    ##############################################################################

    ##############################################################################
    # F5 Deployment Instances
    ##############################################################################

    f5_deployments = [
      for instance in flatten([local.use_bastion ? [1, 2, 3] : []]) :
      {
        name                          = "f5-zone-${instance}"
        vpc_name                      = local.vpc_list[0]
        primary_subnet_name           = "f5-management-zone-${instance}"
        f5_image_name                 = var.f5_image_name
        machine_type                  = var.f5_instance_profile
        resource_group                = "${var.prefix}-${local.vpc_list[0]}-rg"
        domain                        = var.domain
        hostname                      = var.hostname
        ssh_keys                      = ["ssh-key"]
        enable_management_floating_ip = var.enable_f5_management_fip
        enable_external_floating_ip   = var.enable_f5_external_fip
        security_group = {
          name     = "f5-management-sg-${instance}"
          vpc_name = local.vpc_list[0]
          rules = flatten([
            # Create single array from dynamically generated and static arrays
            [
              {
                name      = "allow-ibm-inbound"
                source    = "161.26.0.0/16"
                direction = "inbound"
              }
            ],
            # Dynamically create rule to allow inbound and outbound network traffic
            [
              for direction in ["inbound", "outbound"] :
              [
                {
                  name      = "allow-vpc-${direction}"
                  source    = "10.0.0.0/8"
                  direction = direction
                }

              ]
            ],
            # For each port in the list, create an inbound rule to allow traffic out to IBM CIDR
            [
              for port in [53, 80, 443] :
              {
                name      = "allow-ibm-tcp-${port}-outbound"
                source    = "161.26.0.0/16"
                direction = "outbound"
                tcp = {
                  port_min = port
                  port_max = port
                }
              }
            ],
            # Add management group rules
            [
              for rule in local.f5_security_groups.f5-management.rules :
              rule
            ]
          ])
        },
        secondary_subnet_names = [
          for subnet in local.vpn_firewall_types[var.vpn_firewall_type] :
          "${subnet}-zone-${instance}" if subnet != "f5-management"
        ]
        secondary_subnet_security_group_names = [
          for subnet in local.vpn_firewall_types[var.vpn_firewall_type] :
          {
            group_name     = "${subnet}-sg"
            interface_name = "${var.prefix}-${local.vpc_list[0]}-${subnet}-zone-${instance}"
          } if subnet != "f5-management"
        ]
      }
    ]

    ##############################################################################


    ##############################################################################
    # IAM Account Settings
    ##############################################################################
    iam_account_settings = {
      enable = false
    }
    access_groups = [
      # for group in ["admin", "operate", "viewer"]:
      # {
      #   name = group
      #   description = "Template access group for ${group}"
      #   policies = [
      #     {
      #       name = "${group}-policy"
      #       roles = [
      #         lookup({
      #           admin = "Administrator"
      #           operate = "Operator"
      #           viewer = "Viewer"
      #         }, group)
      #       ]
      #       resources = {
      #         resource = "is"
      #       }
      #     }
      #   ]
      # }
    ]
    ##############################################################################

    ##############################################################################
    # F5 Security Groups
    ##############################################################################

    security_groups = [
      for tier in flatten([local.use_bastion ? local.vpn_firewall_types[var.vpn_firewall_type] : []]) :
      local.f5_security_groups[tier]
    ]

    ##############################################################################  
  }

  ##############################################################################
  # Compile Environment for Config output
  ##############################################################################
  env = {
    resource_groups                = lookup(local.override, "resource_groups", local.config.resource_groups)
    vpcs                           = lookup(local.override, "vpcs", local.config.vpcs)
    vpn_gateways                   = lookup(local.override, "vpn_gateways", local.config.vpn_gateways)
    enable_transit_gateway         = lookup(local.override, "enable_transit_gateway", local.config.enable_transit_gateway)
    transit_gateway_resource_group = lookup(local.override, "transit_gateway_resource_group", local.config.transit_gateway_resource_group)
    transit_gateway_connections    = lookup(local.override, "transit_gateway_connections", local.config.transit_gateway_connections)
    ssh_keys                       = lookup(local.override, "ssh_keys", local.config.ssh_keys)
    network_cidr                   = lookup(local.override, "network_cidr", var.network_cidr)
    vsi                            = lookup(local.override, "vsi", local.config.vsi)
    security_groups                = lookup(local.override, "security_groups", lookup(local.config, "security_groups", []))
    virtual_private_endpoints      = lookup(local.override, "virtual_private_endpoints", local.config.virtual_private_endpoints)
    cos                            = lookup(local.override, "cos", local.config.object_storage)
    service_endpoints              = lookup(local.override, "service_endpoints", "private")
    key_management                 = lookup(local.override, "key_management", local.config.key_management)
    atracker                       = lookup(local.override, "atracker", local.config.atracker)
    clusters                       = lookup(local.override, "clusters", [])
    wait_till                      = lookup(local.override, "wait_till", "IngressReady")
    iam_account_settings           = lookup(local.override, "iam_account_settings", local.config.iam_account_settings)
    access_groups                  = lookup(local.override, "access_groups", local.config.access_groups)
    f5_vsi                         = lookup(local.override, "f5_vsi", local.config.f5_deployments)
    f5_template_data = {
      tmos_admin_password     = lookup(local.override, "f5_template_data", null) == null ? var.tmos_admin_password : lookup(local.override.f5_template_data, "tmos_admin_password", var.tmos_admin_password)
      license_type            = lookup(local.override, "f5_template_data", null) == null ? var.license_type : lookup(local.override.f5_template_data, "license_type", var.license_type)
      byol_license_basekey    = lookup(local.override, "f5_template_data", null) == null ? var.byol_license_basekey : lookup(local.override.f5_template_data, "byol_license_basekey", var.byol_license_basekey)
      license_host            = lookup(local.override, "f5_template_data", null) == null ? var.license_host : lookup(local.override.f5_template_data, "license_host", var.license_host)
      license_username        = lookup(local.override, "f5_template_data", null) == null ? var.license_username : lookup(local.override.f5_template_data, "license_username", var.license_username)
      license_password        = lookup(local.override, "f5_template_data", null) == null ? var.license_password : lookup(local.override.f5_template_data, "license_password", var.license_password)
      license_pool            = lookup(local.override, "f5_template_data", null) == null ? var.license_pool : lookup(local.override.f5_template_data, "license_pool", var.license_pool)
      license_sku_keyword_1   = lookup(local.override, "f5_template_data", null) == null ? var.license_sku_keyword_1 : lookup(local.override.f5_template_data, "license_sku_keyword_1", var.license_sku_keyword_1)
      license_sku_keyword_2   = lookup(local.override, "f5_template_data", null) == null ? var.license_sku_keyword_2 : lookup(local.override.f5_template_data, "license_sku_keyword_2", var.license_sku_keyword_2)
      license_unit_of_measure = lookup(local.override, "f5_template_data", null) == null ? var.license_unit_of_measure : lookup(local.override.f5_template_data, "license_unit_of_measure", var.license_unit_of_measure)
      do_declaration_url      = lookup(local.override, "f5_template_data", null) == null ? var.do_declaration_url : lookup(local.override.f5_template_data, "do_declaration_url", var.do_declaration_url)
      as3_declaration_url     = lookup(local.override, "f5_template_data", null) == null ? var.as3_declaration_url : lookup(local.override.f5_template_data, "as3_declaration_url", var.as3_declaration_url)
      ts_declaration_url      = lookup(local.override, "f5_template_data", null) == null ? var.ts_declaration_url : lookup(local.override.f5_template_data, "ts_declaration_url", var.ts_declaration_url)
      phone_home_url          = lookup(local.override, "f5_template_data", null) == null ? var.phone_home_url : lookup(local.override.f5_template_data, "phone_home_url", var.phone_home_url)
      template_source         = lookup(local.override, "f5_template_data", null) == null ? var.template_source : lookup(local.override.f5_template_data, "template_source", var.template_source)
      template_version        = lookup(local.override, "f5_template_data", null) == null ? var.template_version : lookup(local.override.f5_template_data, "template_version", var.template_version)
      app_id                  = lookup(local.override, "f5_template_data", null) == null ? var.app_id : lookup(local.override.f5_template_data, "app_id", var.app_id)
      tgactive_url            = lookup(local.override, "f5_template_data", null) == null ? var.tgactive_url : lookup(local.override.f5_template_data, "tgactive_url", var.tgactive_url)
      tgstandby_url           = lookup(local.override, "f5_template_data", null) == null ? var.tgstandby_url : lookup(local.override.f5_template_data, "tgstandby_url", var.tgstandby_url)
      tgrefresh_url           = lookup(local.override, "f5_template_data", null) == null ? var.tgrefresh_url : lookup(local.override.f5_template_data, "tgrefresh_url", var.tgrefresh_url)
    }
  }
  ##############################################################################

  string = "\"${jsonencode(local.env)}\""
}

##############################################################################

##############################################################################
# Convert Environment to escaped readable string
##############################################################################

data "external" "format_output" {
  program = ["python3", "${path.module}/scripts/output.py", local.string]
}

##############################################################################