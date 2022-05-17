##############################################################################
# Static Local Values
##############################################################################

locals {
  # Static list for bastion tiers by type
  vpn_firewall_types = {
    full-tunnel = ["f5-management", "f5-external", "f5-bastion"]
    waf         = ["f5-management", "f5-external", "f5-workload"]
    vpn-and-waf = ["f5-management", "f5-external", "f5-workload", "f5-bastion"]
  }

  # Static reference for vpc with no gateways
  vpc_gateways = {
    zone-1 = false
    zone-2 = false
    zone-3 = false
  }

  # List of CIDR for workload subnets
  workload_subnets = [
    "10.10.10.0/24",
    "10.20.10.0/24",
    "10.30.10.0/24",
    "10.40.10.0/24",
    "10.50.10.0/24",
    "10.60.10.0/24"
  ]

}

##############################################################################


##############################################################################
# Static Security Groups
##############################################################################

locals {
  # Security group rules used for VSI
  default_vsi_sg_rules = flatten([
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
}

##############################################################################


##############################################################################
# Outputs
##############################################################################

output "default_vsi_sg_rules" {
  description = "Default rules added to VSI security groups"
  value       = local.default_vsi_sg_rules
}

##############################################################################