##############################################################################
# Dynamically Create Default Configuration
##############################################################################

locals {
  # If override is true, parse the JSON from override.json otherwise parse empty string
  # Empty string is used to avoid type conflicts with unary operators
  override = jsondecode(var.override ? file("./override.json") : "{}")

  # Add HPCS resource group if included
  resource_group_list = (
    var.hs_crypto_resource_group == null
    ? ["Default", "service"]
    : ["Default", "service", var.hs_crypto_resource_group]
  )

  ##############################################################################
  # Dynamic configuration for landing zone environment
  ##############################################################################
  config = {
    ##############################################################################
    # Create a resource group for each group in the list, and for each VPC
    # get default, Default and hs crypto if included. 
    ##############################################################################
    resource_groups = [
      for group in distinct(concat(local.resource_group_list, var.vpcs)) :
      {
        name   = group == "Default" || group == "default" ? group : "${var.prefix}-${group}-rg"
        create = (group == "Default" || group == "default" || group == var.hs_crypto_resource_group) ? false : true
      }
    ]
    ##############################################################################

    ##############################################################################
    # Create one VPC for each name in VPC variable
    ##############################################################################
    vpcs = [
      for network in var.vpcs :
      {
        prefix                       = network
        resource_group               = "${var.prefix}-${network}-rg"
        flow_logs_bucket_name        = "${network}-bucket"
        default_security_group_rules = []
        network_acls = [
          {
            name              = "${network}-acl"
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
            for subnet in(network == var.vpcs[0] && zone == 1 ? ["vsi", "vpe", "vpn"] : ["vsi", "vpe"]) :
            {
              name           = "${subnet}-zone-${zone}"
              cidr           = "10.${zone + (index(var.vpcs, network) * 3)}0.${1 + index(["vsi", "vpe", "vpn"], subnet)}0.0/24"
              public_gateway = false
              acl_name       = "${network}-acl"
            }
          ]
        }
      }
    ]
    ##############################################################################

    ##############################################################################
    # Transit Gateway Variables
    ##############################################################################
    enable_transit_gateway         = true
    transit_gateway_resource_group = "${var.prefix}-service-rg"
    transit_gateway_connections    = var.vpcs
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
          name = "cos-bind-key"
          role = "Writer"
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
          for network in var.vpcs :
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
        for service in ["slz", "atracker", "vsi-volume", "roks"] :
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
        for network in var.vpcs :
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
    }
    ##############################################################################

    ##############################################################################
    # Cluster Config
    ##############################################################################
    clusters = [
      # Dynamically create identical cluster in each VPC
      for network in var.vpcs :
      {
        name     = "${network}-cluster"
        vpc_name = network
        subnet_names = [
          # For the number of zones in zones variable, get that many subnet names
          for zone in range(1, var.zones + 1) :
          "vsi-zone-${zone}"
        ]
        kms_config = {
          crk_name = "${var.prefix}-roks-key"
          private_endpoint = true
        }
        workers_per_subnet = var.workers_per_zone
        machine_type       = var.flavor
        kube_type          = "openshift"
        resource_group     = "${var.prefix}-${var.network}-rg"
        cos_name           = "cos"
        entitlement        = var.entitlement
        # By default, create dedicated pool for logging
        worker_pools = [
          {
            name     = "logging-worker-pool"
            vpc_name = network
            subnet_names = [
              for zone in range(1, var.zones + 1) :
              "vsi-zone-${zone}"
            ]
            entitlement        = var.entitlement
            workers_per_subnet = var.workers_per_zone
            flavor             = var.flavor
        }]
      }
    ]
    ##############################################################################

    ##############################################################################
    # VPN Gateway
    # > Create a gateway in first vpc
    ##############################################################################
    vpn_gateways = [
      {
        name           = "${var.vpcs[0]}-gateway"
        vpc_name       = "${var.vpcs[0]}"
        subnet_name    = "vpn-zone-1"
        resource_group = "${var.prefix}-${var.vpcs[0]}-rg"
        connections    = []
      }
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
    ssh_keys                       = lookup(local.override, "ssh_keys", [])
    vsi                            = lookup(local.override, "vsi", [])
    security_groups                = lookup(local.override, "security_groups", lookup(local.config, "security_groups", []))
    virtual_private_endpoints      = lookup(local.override, "virtual_private_endpoints", local.config.virtual_private_endpoints)
    cos                            = lookup(local.override, "cos", local.config.object_storage)
    service_endpoints              = lookup(local.override, "service_endpoints", "private")
    key_management                 = lookup(local.override, "key_management", local.config.key_management)
    atracker                       = lookup(local.override, "atracker", local.config.atracker)
    clusters                       = lookup(local.override, "clusters", local.config.clusters)
    wait_till                      = lookup(local.override, "wait_till", "IngressReady")
  }
  ##############################################################################

  string = "\"${jsonencode(local.env)}\""
}

##############################################################################

##############################################################################
# Convert Environment to escaped readable string
##############################################################################

data "external" "format_output" {
  program = ["python3", "../../scripts/output.py", local.string]
}

##############################################################################
