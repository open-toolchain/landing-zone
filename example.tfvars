prefix         = "gcat-multizone-schematics"
region         = "us-south"
resource_group = ""
vpcs = [
  {
    prefix = "management"
    use_public_gateways = {
      zone-1 = true
      zone-2 = true
      zone-3 = true
    }
    network_acls = [
      {
        name              = "vpc-acl"
        add_cluster_rules = true
        rules = [
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
    subnets = {
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
    prefix = "workload"
    use_public_gateways = {
      zone-1 = true
      zone-2 = true
      zone-3 = true
    }
    network_acls = [
      {
        name              = "vpc-acl"
        add_cluster_rules = true
        rules = [
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
    subnets = {
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
ssh_public_key = ""
vsi = [
  {
    name           = "test-vsi"
    vpc_name       = "management"
    subnet_names   = ["subnet-a", "subnet-c"]
    image_name     = "ibm-centos-7-6-minimal-amd64-2"
    machine_type   = "bx2-8x32"
    vsi_per_subnet = 2
    security_group = {
      name = "test"
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
    image_name     = "ibm-centos-7-6-minimal-amd64-2"
    machine_type   = "bx2-8x32"
    vsi_per_subnet = 1
    security_group = {
      name = "test"
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

#####################################################
# Atracker Variables
#####################################################

bucket_name = "<USER INPUT REQUIRED>"

location = "<USER INPUT REQUIRED>"
