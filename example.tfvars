##############################################################################
# Account Variables
# > These will apply to any resources created using this template
##############################################################################

ibmcloud_api_key = "< ibmcloud platform api key >"
prefix           = "slz"
region           = "us-south"
tags             = ["slz-example"]
##############################################################################

##############################################################################
# Resource Groups
##############################################################################

resource_groups = [
  {
    name = "default"
  }
]

##############################################################################

##############################################################################
# IBM Managed Services
##############################################################################

kms = {
  name           = "dev-kms"
  resource_group = "default"
  keys = [
    {
      name     = "root"
      root_key = true
      key_name = "dev-ring"
    }
  ]
}

##############################################################################


##############################################################################
# VPC Networks
##############################################################################

vpcs = [
  {
    prefix = "management"
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
    prefix = "workload"
    use_public_gateways = {
      zone-1 = false
      zone-2 = false
      zone-3 = false
    }
    network_acls = [
      {
        name = "workload-acl"
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
          name           = "vpn-zone-2"
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
          name           = "vpn-zone-3"
          cidr           = "10.60.20.0/24"
          public_gateway = true
          acl_name       = "workload-acl"
        }
      ]
    }
  },
]

enable_transit_gateway      = true
transit_gateway_connections = ["management", "workload"]

##############################################################################


##############################################################################
# Virtual Servers
##############################################################################

ssh_keys = [
  {
    name       = "management"
    public_key = "<ssh public key>"
  }
]


vsi = [
  {
    name           = "management-server"
    vpc_name       = "management"
    vsi_per_subnet = 1
    subnet_names   = ["vsi-zone-1", "vsi-zone-2", "vsi-zone-3"]
    image_name     = "ibm-ubuntu-16-04-5-minimal-amd64-1"
    machine_type   = "cx2-2x4"
    security_group = {
      name     = "management"
      vpc_name = "management"
      rules = [
        {
          name      = "allow-ibm-inbound"
          source    = "161.26.0.0/16"
          direction = "inbound"
        },
        {
          name      = "allow-sg-outbound"
          source    = "mgmt-base-security-group"
          direction = "outbound"
        },
        {
          name      = "allow-ibm-tcp-80-outbound"
          source    = "161.26.0.0/16"
          direction = "outbound"
          tcp = {
            port_min = 80
            port_max = 80
          }
        },
        {
          name      = "allow-ibm-tcp-443-outbound"
          source    = "161.26.0.0/16"
          direction = "outbound"
          tcp = {
            port_min = 443
            port_max = 443
          }
        },
        {
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
    ssh_keys = ["management"]
  },
  {
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
        },
        {
          name      = "allow-sg-outbound"
          source    = "mgmt-base-security-group"
          direction = "outbound"
        },
        {
          name      = "allow-ibm-tcp-80-outbound"
          source    = "161.26.0.0/16"
          direction = "outbound"
          tcp = {
            port_min = 80
            port_max = 80
          }
        },
        {
          name      = "allow-ibm-tcp-443-outbound"
          source    = "161.26.0.0/16"
          direction = "outbound"
          tcp = {
            port_min = 443
            port_max = 443
          }
        },
        {
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
    ssh_keys = ["management"]
  }
]

security_groups = []

##############################################################################


##############################################################################
# NOT YET IMPLEMENTED
##############################################################################

flow_logs = {
  cos_bucket_name = "jv-dev-bucket"
  active          = true
}



virtual_private_endpoints = [/*
  commented out until vpe enabled services are added
  {
    service_name = "dbaas"
    service_crn  = "1234"
    vpcs = [
      {
        name                = "management"
        subnets             = ["subnet-a", "subnet-c"]
        security_group_name = "workload-vpe"
      },
      {
        name    = "workload"
        subnets = ["subnet-b"]
      }
    ]
  },
  {
    service_name = "rabbitmq"
    service_crn  = "1234"
    vpcs = [
      {
        name    = "management"
        subnets = ["subnet-a", "subnet-c"]
      },
      {
        name    = "workload"
        subnets = ["subnet-b"]
      }
    ]
  }*/
]

##############################################################################