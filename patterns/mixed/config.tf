##############################################################################
# Dynamically Create Default Configuration
##############################################################################

locals {
  override = jsondecode(var.override ? file("./override.json") : "{}")
  config = {
    resource_groups = [
      for group in ["Default", "management", "workload", "service", "transit-gateway"] :
      {
        name   = group == "Default" || group == "default" ? group : "${var.prefix}-${group}-rg"
        create = group == "Default" || group == "default" ? false : true
      }
    ]
    ssh_keys = [
      {
        name       = "${var.prefix}-ssh-key"
        public_key = var.ssh_public_key
      }
    ]
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
              cidr           = "10.${zone + (index(var.vpcs, network) * 3)}0.${zone + index(["vsi", "vpe", "vpn"], subnet)}0.0/24"
              public_gateway = false
              acl_name       = "${network}-acl"
            }
          ]
        }
        vpn_gateways = network == "management" ? [
          {
            name        = "vpn"
            subnet_name = "vpn-zone-1"
            connections = []
          }
          ] : [
          {
            name        = null
            subnet_name = null
            connections = []
          }
        ]
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
    vsi = [
      for network in var.vpcs :
      {
        name                            = "${network}-server"
        vpc_name                        = network
        subnet_names                    = ["vsi-zone-1", "vsi-zone-2", "vsi-zone-3"]
        image_name                      = var.vsi_image_name
        vsi_per_subnet                  = 1
        machine_type                    = var.vsi_instance_profile
        boot_volume_encryption_key_name = "${var.prefix}-vsi-volume-key"
        security_group = {
          name     = network
          vpc_name = network
          rules = flatten([
            [
              {
                name      = "allow-ibm-inbound"
                source    = "161.26.0.0/16"
                direction = "inbound"
              }
            ],
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
        ssh_keys = ["${var.prefix}-ssh-key"]
      }
    ]
    clusters = [
      for network in var.vpcs :
      {
        name     = "${network}-cluster"
        vpc_name = network
        subnet_names = [
          for zone in range(1, var.zones) :
          "vsi-zone-${zone}"
        ]
        workers_per_subnet = 2
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
            workers_per_subnet = 1
            flavor             = var.flavor
        }]
      }
    ]
  }
}

##############################################################################