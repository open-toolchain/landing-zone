##############################################################################
# Dynamically Create Default Configuration
##############################################################################

locals {
  override = jsondecode(var.override ? file("./override.json") : "{}")
  config = {
    resource_groups = [
      for group in concat(["Default", "service", "transit-gateway"], var.vpcs) :
      {
        name   = group == "Default" || group == "default" ? group : "${var.prefix}-${group}-rg"
        create = group == "Default" || group == "default" ? false : true
      }
    ]
    ssh_keys = []
    vpcs = [
      for network in var.vpcs :
      {
        prefix                = network
        resource_group        = "${var.prefix}-${network}-rg"
        flow_logs_bucket_name = "${network}-bucket"
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
        subnets = {
          for zone in [1, 2, 3] :
          "zone-${zone}" => [
            for subnet in(network == "management" && zone == 1 ? ["vsi", "vpe", "vpn"] : ["vsi", "vpe"]) :
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
    vpn_gateways = [
      {
        name           = "management-gateway"
        vpc_name       = "management"
        subnet_name    = "vpn-zone-1"
        resource_group = "${var.prefix}-management-rg"
        connections    = []
      }
    ]
    enable_transit_gateway         = true
    transit_gateway_resource_group = "${var.prefix}-service-rg"
    transit_gateway_connections    = var.vpcs
    object_storage = [
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
        keys = [{
          name = "cos-bind-key"
          role = "Writer"
        }]
      },
      {
        name           = "cos"
        use_data       = false
        resource_group = "${var.prefix}-service-rg"
        plan           = "standard"
        buckets = [
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
    key_management = {
      name           = "${var.prefix}-slz-kms"
      resource_group = "${var.prefix}-service-rg"
      use_hs_crypto  = var.hs_crypto_instance_name == null ? false : true
      keys = [
        for service in ["slz", "atracker", "vsi-volume"] :
        {
          name     = "${var.prefix}-${service}-key"
          root_key = true
          key_ring = "${var.prefix}-slz-ring"
        }
      ]
    }
    virtual_private_endpoints = [{
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
    atracker = {
      resource_group        = "Default"
      receive_global_events = true
      collector_bucket_name = "atracker-bucket"
    }
    vsi = []
    clusters = [
      for network in var.vpcs :
      {
        name     = "${network}-cluster"
        vpc_name = network
        subnet_names = [
          for zone in range(1, var.zones) :
          "vsi-zone-${zone}"
        ]
        workers_per_subnet = var.workers_per_zone
        machine_type       = var.flavor
        kube_type          = "openshift"
        resource_group     = "Default"
        cos_name           = "cos"
        worker_pools = [
          {
            name     = "logging-worker-pool"
            vpc_name = network
            subnet_names = [
              for zone in range(1, var.zones) :
              "vsi-zone-${zone}"
            ]
            workers_per_subnet = var.workers_per_zone
            flavor             = var.flavor
        }]
      }
    ]
  }
  env = {
    resource_groups                = lookup(local.override, "resource_groups", local.config.resource_groups)
    vpcs                           = lookup(local.override, "vpcs", local.config.vpcs)
    vpn_gateways                   = lookup(local.override, "vpn_gateways", local.config.vpn_gateways)
    enable_transit_gateway         = lookup(local.override, "enable_transit_gateway", local.config.enable_transit_gateway)
    transit_gateway_resource_group = lookup(local.override, "transit_gateway_resource_group", local.config.transit_gateway_resource_group)
    transit_gateway_connections    = lookup(local.override, "transit_gateway_connections", local.config.transit_gateway_connections)
    ssh_keys                       = lookup(local.override, "ssh_keys", local.config.ssh_keys)
    vsi                            = lookup(local.override, "vsi", local.config.vsi)
    security_groups                = lookup(local.override, "security_groups", lookup(local.config, "security_groups", []))
    virtual_private_endpoints      = lookup(local.override, "virtual_private_endpoints", local.config.virtual_private_endpoints)
    cos                            = lookup(local.override, "cos", local.config.object_storage)
    service_endpoints              = lookup(local.override, "service_endpoints", "private")
    key_management                 = lookup(local.override, "key_management", local.config.key_management)
    atracker                       = lookup(local.override, "atracker", local.config.atracker)
    clusters                       = lookup(local.override, "clusters", local.config.clusters)
    wait_till                      = lookup(local.override, "wait_till", "IngressReady")
  }
}

##############################################################################