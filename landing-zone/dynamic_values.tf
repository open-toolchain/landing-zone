##############################################################################
# Create Dynamic Values
##############################################################################

module "dynamic_values" {
  source                    = "./dynamic_values"
  region                    = var.region
  prefix                    = var.prefix
  key_management            = var.key_management
  key_management_guid       = module.key_management.key_management_guid
  clusters                  = var.clusters
  vpcs                      = var.vpcs
  resource_groups           = local.resource_groups
  vpc_modules               = module.vpc
  cos                       = var.cos
  cos_data_source           = data.ibm_resource_instance.cos
  cos_resource              = ibm_resource_instance.cos
  cos_resource_keys         = ibm_resource_key.key
  ssh_keys                  = var.ssh_keys
  vsi                       = var.vsi
  virtual_private_endpoints = var.virtual_private_endpoints
  vpn_gateways              = var.vpn_gateways
  security_groups           = var.security_groups
  bastion_vsi               = var.teleport_vsi
  access_groups             = var.access_groups
  appid                     = var.appid
  appid_resource            = ibm_resource_instance.appid
  appid_data                = data.ibm_resource_instance.appid
}

##############################################################################


##############################################################################
# Unit Tests Module
##############################################################################

module "unit_tests" {
  source                    = "./dynamic_values"
  region                    = var.region
  prefix                    = "ut"
  vpcs                      = local.unit_test_config.vpcs
  clusters                  = local.unit_test_config.clusters
  vpc_modules               = local.unit_test_config.vpc_modules
  cos                       = local.unit_test_config.cos
  cos_data_source           = local.mock_cos_data_instances
  cos_resource              = local.mock_cos_instances
  cos_resource_keys         = local.mock_cos_resource_keys
  key_management            = local.unit_test_config.key_management
  key_management_guid       = "12KEY"
  resource_groups           = local.mock_resource_group_map
  virtual_private_endpoints = local.unit_test_config.virtual_private_endpoints
  vpn_gateways              = local.unit_test_config.vpn_gateways
  security_groups           = local.unit_test_config.security_groups
  vsi                       = local.unit_test_config.vsi
  ssh_keys                  = local.unit_test_config.ssh_keys
  appid_resource            = local.mock_appid_instance
  appid_data                = local.mock_appid_data_instance

  bastion_vsi = [
    {
      name               = "teleport"
      image_name         = "ubuntu"
      vpc_name           = "test"
      resource_group     = "default"
      subnet_name        = "ut-test-subnet-1"
      ssh_keys           = ["test-key"]
      machine_type       = "test-machine_type"
      teleport_license   = "yes"
      https_cert         = "yes"
      https_key          = "yes"
      hostname           = "yes"
      domain             = "yes"
      cos_bucket_name    = "yes"
      cos_key_name       = "yes"
      teleport_version   = "yes"
      message_of_the_day = "yes"
      claims_to_roles    = []
      app_id_key_name    = "test"
    }
  ]

  appid = {
    name           = "ut-appid"
    resource_group = "default"
    use_data       = true
    keys           = ["ut-teleport-key"]
    create_app_id  = true
  }

  access_groups = [
    {
      name = "test",
      policies = [
        {
          name = "policy"
        }
      ]
      dynamic_policies = [
        {
          name = "dynamic-policy"
        }
      ]
      account_management_policies = ["yes"]
      invite_users                = ["yes"]
    }
  ]
}

##############################################################################

##############################################################################
# Create Dynamic Values for Unit Tests
##############################################################################

locals {
  unit_test_config = {
    # Cluster List
    clusters = local.mock_cluster_map.cluster_list
    # Mock VPCs Variable
    vpcs = [
      {
        prefix                = "test"
        name                  = "test-vpc"
        resource_group        = "test-rg"
        flow_logs_bucket_name = "bucket"
      },
      {
        prefix = "no-flow-logs"
      }
    ]
    # Mock VPC Modules
    vpc_modules = {
      test = {
        vpc_id = "1234"
        subnet_zone_list = [
          {
            name = "ut-test-subnet-1"
            id   = "1-id"
            zone = "1-zone"
            cidr = "1"
          },
          {
            name = "ut-test-subnet-2"
            id   = "2-id"
            zone = "2-zone"
            cidr = "2"
          },
          {
            name = "ut-test-subnet-3"
            id   = "3-id"
            zone = "3-zone"
            cidr = "3"
          },
          {
            name = "ut-test-subnet-4"
            id   = "4-id"
            zone = "4-zone"
            cidr = "4"
          },
          {
            name = "ut-test-vpe-zone-1"
            id   = "vpe-id"
            zone = "vpe-zone"
            cidr = "vpe"
          },
          {
            name = "ut-test-vpn-zone-1"
            id   = "vpn-id"
            zone = "vpn-zone"
            cidr = "vpn"
        }]
      }
    }
    cos = [
      {
        name     = "data-cos"
        use_data = true
        buckets = [
          {
            name = "data-bucket"
          }
        ]
        keys = [
          {
            name        = "data-bucket-key"
            enable_HMAC = false
          },
          {
            name        = "teleport-key"
            enable_HMAC = true
          }
        ]
      },
      {
        name     = "test-cos"
        use_data = false
        buckets = [
          {
            name = "create-bucket"
          }
        ]
      }
    ]
    key_management = {
      use_hs_crypto = false
    }
    virtual_private_endpoints = [{
      service_name   = "test-cos",
      service_type   = "cloud-object-storage"
      resource_group = "test-rg"
      vpcs = [
        {
          name = "test"
          subnets = [
            "vpe-zone-1"
          ]
        }
      ]
    }]
    vpn_gateways = [
      {
        connections = [{
          peer_address   = "test-peer-address"
          preshared_key  = "preshared_key"
          local_cidrs    = ["cidr1"]
          peer_cidrs     = ["cidr2"]
          admin_state_up = true
        }]
        name           = "test-gateway",
        resource_group = "test-rg"
        subnet_name    = "vpn-zone-1"
        vpc_name       = "test"
        mode           = null
      }
    ]
    security_groups = [
      {
        name           = "test-sg"
        vpc_name       = "test"
        resource_group = "test-rg"
        rules = [
          {
            name      = "test-rule"
            source    = "0.0.0.0/0"
            direction = "inbound"
            tcp = {
              port_max = "1"
            }
          }
        ]
      }
    ]
    vsi = [
      {
        name         = "vsi"
        image_name   = "ubuntu"
        subnet_names = ["subnet-2", "subnet-4"]
        vpc_name     = "test"
      }
    ]
    ssh_keys = [{
      name           = "test-key"
      resource_group = "test-rg"
    }]
  }

  ##############################################################################
  # Mock Values used for testing
  # > To ensure values are passed into the `dynamic_values` modules only once
  #   these variables are added
  ##############################################################################

  # Mock vsi subnet map map
  mock_vsi_map_subnet_map = {
    for subnet in module.unit_tests.vsi_map["ut-vsi"].subnets :
    (subnet.name) => subnet
  }


  # Mock subnet map
  mock_cluster_map_subnet_map = {
    for subnet in local.actual_clusters_map["ut-test-cluster"].subnets :
    (subnet.name) => subnet
  }

  # Mock worker pool subnet map
  mock_worker_pool_map_subnet_map = {
    for subnet in local.actual_worker_pools_map["ut-test-cluster-logging-worker-pool"].subnets :
    (subnet.name) => subnet
  }

  # Mock Cluster Map
  mock_cluster_map = {
    cluster_list = [
      {
        name           = "test-cluster"
        vpc_name       = "test"
        subnet_names   = ["subnet-1", "subnet-3"]
        resource_group = "test-resource-group"
        kube_type      = "openshift"
        cos_name       = "data-cos"
        entitlement    = "cloud_pak"
        worker_pools = [
          {
            name               = "logging-worker-pool"
            vpc_name           = "test"
            subnet_names       = ["subnet-1", "subnet-3"]
            workers_per_subnet = 2
            flavor             = "spicy"
          }
        ]
      }
    ]
  }

  # Mock cos instance map
  mock_cos_instances = {
    test-cos = {
      name = "ut-test-cos"
      id   = ":::::::1234"
    }
  }

  # Mock cos data map
  mock_cos_data_instances = {
    data-cos = {
      name = "data-cos"
      id   = ":::::::5678"
    }
  }

  # Mock Resource Keys
  mock_cos_resource_keys = {
    data-bucket-key = {
      credentials = {
        apikey = "1234"
      }
    }
  }

  # Mock appid instance list
  mock_appid_instance = [{
    name = "ut-test-appid"
    id   = ":::::::2345"

  }]

  # Mock appid data list
  mock_appid_data_instance = [{
    name = "data-appid"
    id   = ":::::::6789"
    guid = ":::::::4321"

  }]


  # Mock Resource Group Map
  mock_resource_group_map = {
    test-rg = "2345"
  }

  ##############################################################################
}

##############################################################################


