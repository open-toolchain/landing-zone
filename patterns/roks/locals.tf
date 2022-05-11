##############################################################################
# Local Environment Configuration
# > Local blocks here are used to create config data
# > Separated to simplify use of `config.tf`
##############################################################################

locals {
  # Prepend edge to list if enabled
  vpc_list = (
    var.add_edge_vpc
    ? concat(["edge"], var.vpcs)
    : var.vpcs
  )

  # Create bastion subnet configuration
  use_bastion = var.add_edge_vpc || var.create_bastion_on_management_vpc

  # Reference to create an array containing value if not null
  # Future resource groups from data should use this as a template
  hs_crypto_rg = var.hs_crypto_resource_group == null ? [] : [var.hs_crypto_resource_group]

  # List of resource groups used by default
  resource_group_list = flatten([
    ["Default", "service"],
    local.hs_crypto_rg
  ])

  # Create reference list
  dynamic_rg_list = flatten([
    [
      "Default",
      "default",
    ],
    local.hs_crypto_rg
  ])

  # Static list for bastion tiers by type
  vpn_firewall_types = {
    full-tunnel = ["f5-management", "f5-external", "f5-bastion"]
    waf         = ["f5-management", "f5-external", "f5-workload"]
    vpn-and-waf = ["f5-management", "f5-external", "f5-workload", "f5-bastion"]
  }

  # Tiers for bastion
  bastion_tiers = flatten([
    ["vpn-1", "vpn-2"],
    [
      var.vpn_firewall_type != null && local.use_bastion # if using bastion
      ? local.vpn_firewall_types[var.vpn_firewall_type]  # lookup tiers
      : []                                               # default to empty
    ],
    ["bastion", "vpe"]
  ])

  subnet_tiers = ["vsi", "vpe", "vpn"] # Subnet tiers


  ##############################################################################
  # Create reference for adding address prefixes for each network and each
  # zone, where the zone is equal to the needed address prefixes
  ##############################################################################

  vpc_use_edge_prefixes = {
    for network in local.vpc_list :
    (network) => {
      for zone in [1, 2, 3] :
      "zone-${zone}" => (
        # If adding edge and is edge
        network == local.vpc_list[0] && var.add_edge_vpc
        ? ["10.${4 + zone}.0.0/16"]
        # If not adding edge and is management
        : network == var.vpcs[0] && var.create_bastion_on_management_vpc
        ? ["10.${4 + zone}.0.0/16", "10.${zone}0.10.0/24"]
        # default to empty
        : []
      )
    }
  }

  workload_subnets = ["10.10.10.0/24", "10.20.10.0/24", "10.30.10.0/24", "10.40.10.0/24", "10.50.10.0/24", "10.60.10.0/24"]

  ##############################################################################

  ##############################################################################
  # F5 Security Groups
  ##############################################################################

  f5_security_groups = {
    f5-management = {
      name     = "f5-management-sg"
      vpc_name = local.vpc_list[0]
      rules = flatten([
        for zone in [1, 2, 3] :
        [
          for port in [22, 443] :
          {
            name      = "allow-bastion-${zone}-inbound-${port}"
            direction = "inbound"
            source    = "10.${4 + zone}.${1 + index(local.bastion_tiers, "bastion")}0.0/24"
            tcp = {
              port_max = port
              port_min = port
            }
          }
        ]
      ])
    }
    f5-external = {
      name     = "f5-external-sg"
      vpc_name = local.vpc_list[0]
      rules = [
        {
          name      = "allow-inbound-443"
          direction = "inbound"
          source    = "0.0.0.0/0"
          tcp = {
            port_max = 443
            port_min = 443
          }
        }
      ]
    }
    f5-workload = {
      name     = "f5-workload-sg"
      vpc_name = local.vpc_list[0]
      rules = flatten([
        [
          for subnet in local.workload_subnets :
          {
            name      = "allow-workload-subnet-${index(local.workload_subnets, subnet) + 1}"
            source    = subnet
            direction = "inbound"
            tcp = {
              port_max = 443
              port_min = 443
            }
          } if contains(local.bastion_tiers, "f5-workload")
        ]
      ])
    }

    f5-bastion = {
      name     = "f5-bastion-sg"
      vpc_name = local.vpc_list[0]
      rules = flatten([
        for zone in [1, 2, 3] :
        [
          for ports in [[3023, 3025], [3080, 3080]] :
          {
            name      = "allow-zone-${zone}-inbound-${ports[0]}"
            direction = "inbound"
            source    = "10.${4 + zone}.${1 + index(local.bastion_tiers, "bastion")}0.0/24"
            tcp = {
              port_max = ports[0]
              port_min = ports[1]
            }
          }
        ] if contains(local.bastion_tiers, "f5-bastion")
      ])
    }
  }

  ##############################################################################


  ##############################################################################
  # Create map for each network and zone where each zone is a list of
  # subnet tiers to be created in that zone
  ##############################################################################

  vpc_subnet_tiers = {
    for network in local.vpc_list :
    (network) => {
      for zone in [1, 2, 3] :
      "zone-${zone}" => (
        # If using bastion and creating it on management tier
        local.use_bastion && var.create_bastion_on_management_vpc && network == var.vpcs[0]
        # Add vsi to list of bastion tiers
        ? concat(local.bastion_tiers, ["vsi"])
        # Otherwise if create bastion
        : local.use_bastion && network == local.vpc_list[0]
        # Use bastion tiers
        ? local.bastion_tiers
        # If not using bastion, vpc is management, and zone is 1
        : zone == 1 && network == var.vpcs[0] && !local.use_bastion
        ? ["vsi", "vpe", "vpn"] # Add vpn
        : ["vsi", "vpe"]        # otherwise send default                                 
      )
    }
  }

  ##############################################################################
}

##############################################################################


##############################################################################
# Conflicting Variable Failure States
##############################################################################

locals {
  # Prevent users from inputting conflicting variables by checking regex
  # causeing plan to fail when true. 
  # > if both are false will pass
  # > if only one is true will pass
  fail_with_conflicting_bastion = regex("false", tostring(
    var.add_edge_vpc == false && var.create_bastion_on_management_vpc == false
    ? false
    : var.add_edge_vpc == var.create_bastion_on_management_vpc
  ))

  # Prevent users from provisioning bastion subnets without a tier selected
  fail_with_no_vpn_firewall_type = regex("false", tostring(
    var.vpn_firewall_type == null && local.use_bastion
  ))

  # Prevent users from provisioning using both external and management fip
  # VSI can only have one floating IP per device
  fail_with_both_f5_fip = regex("false", tostring(
    var.enable_f5_management_fip == true && var.enable_f5_external_fip == true
  ))
}

##############################################################################