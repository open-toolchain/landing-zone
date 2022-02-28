ibmcloud_api_key=""
prefix="gcat-multizone-schematics"
region="us-south"
resource_group=""
tags=[]
vpcs=[ 
  { 
    prefix = "management" 
    use_public_gateways = { 
      zone-1 = true 
      zone-2 = true 
      zone-3 = true 
    } 
    network_acls = [ 
      { 
        name = "vpc-acl" 
        add_cluster_rules = true 
        rules = [ 
          { 
            name = "allow-all-inbound" 
            action = "allow" 
            direction = "inbound" 
            destination = "0.0.0.0/0" 
            source = "0.0.0.0/0" 
          }, 
          { 
            name = "allow-all-outbound" 
            action = "allow" 
            direction = "outbound" 
            destination = "0.0.0.0/0" 
            source = "0.0.0.0/0" 
          } 
        ] 
      } 
    ] 
    subnets = { 
      zone-1 = [ 
        { 
          name = "subnet-a"
          cidr = "10.10.10.0/24" 
          public_gateway = true 
          acl_name = "vpc-acl" 
        } 
      ], 
      zone-2 = [ 
        { 
          name = "subnet-b" 
          cidr = "10.20.10.0/24" 
          public_gateway = true 
          acl_name = "vpc-acl" 
        } 
      ], 
      zone-3 = [ 
        { 
          name = "subnet-c" 
          cidr = "10.30.10.0/24" 
          public_gateway = true 
          acl_name = "vpc-acl" 
        } 
      ] 
    } 
  }, 
  { 
    prefix = "workload" 
    use_public_gateways = { 
      zone-1 = true 
      zone-2 = true 
      zone-3 = true 
    } 
    network_acls = [ 
      { 
        name = "vpc-acl"
        add_cluster_rules = true 
        rules = [ 
          { 
            name = "allow-all-inbound" 
            action = "allow" 
            direction = "inbound" 
            destination = "0.0.0.0/0" 
            source = "0.0.0.0/0" 
          }, 
          { 
            name = "allow-all-outbound" 
            action = "allow" 
            direction = "outbound" 
            destination = "0.0.0.0/0" 
            source = "0.0.0.0/0" 
          } 
        ] 
      } 
    ] 
    subnets = { 
      zone-1 = [ 
        { 
          name = "subnet-a" 
          cidr = "10.40.10.0/24" 
          public_gateway = true 
          acl_name = "vpc-acl" 
        } 
      ], 
      zone-2 = [ 
        { 
          name = "subnet-b" 
          cidr = "10.50.10.0/24" 
          public_gateway = true 
          acl_name = "vpc-acl" 
        } 
      ], 
      zone-3 = [ 
        { 
          name = "subnet-c" 
          cidr = "10.60.10.0/24" 
          public_gateway = true 
          acl_name = "vpc-acl" 
        } 
      ] 
    } 
  } 
]
flow_logs={ 
  cos_bucket_name = "jv-dev-bucket" 
  active = true 
}
enable_transit_gateway=true
transit_gateway_connections=[ "management", "workload" ]
ssh_keys=[ 
  { 
    name = "dev-ssh-key" 
    public_key = "<ssh public key>" 
  } 
]
vsi=[ 
  { 
    name = "test-vsi" 
    vpc_name = "management" 
    subnet_names = ["subnet-a", "subnet-c"] 
    image_name = "ibm-centos-7-6-minimal-amd64-2" 
    machine_type = "bx2-8x32" 
    ssh_keys = [ "dev-ssh-key" ] 
    vsi_per_subnet = 1 
    security_group = { 
      name = "test" 
      rules = [ 
        { 
          name = "allow-all-inbound" 
          source = "0.0.0.0/0" 
          direction = "inbound" 
        }, 
        { 
          name = "allow-all-outbound" 
          source = "0.0.0.0/0" 
          direction = "outbound" 
        } 
      ] 
    } 
  } 
]
security_groups=[ 
  { 
    name = "workload-vpe" 
    vpc_name = "workload" 
    rules = [ 
      { 
        name = "allow-all-inbound" 
        source = "0.0.0.0/0" 
        direction = "inbound" 
      }, 
      { 
        name = "allow-all-outbound" 
        source = "0.0.0.0/0" 
        direction = "outbound" 
      } 
    ] 
  } 
]
virtual_private_endpoints=[ 
  { 
    service_name = "dbaas" 
    service_crn = "1234" 
    vpcs = [ 
      { 
        name = "management" 
        subnets = ["subnet-a", "subnet-c"]
        security_group_name = "workload-vpe" 
      },
      { 
        name = "workload" 
        subnets = ["subnet-b"] 
      } 
    ] 
  }, 
  { 
    service_name = "rabbitmq" 
    service_crn = "1234" 
    vpcs = [ 
      { 
        name = "management" 
        subnets = ["subnet-a", "subnet-c"] 
      }, 
      { 
        name = "workload" 
        subnets = ["subnet-b"] 
      } 
    ] 
  } 
]