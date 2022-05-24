##############################################################################
# Values used in VPC configuration
##############################################################################

locals {
  ##############################################################################
  # Prepend edge to list if enabled
  ##############################################################################

  vpc_list = (
    var.add_edge_vpc
    ? concat(["edge"], var.vpcs)
    : var.vpcs
  )

  ##############################################################################

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
        : network == var.vpcs[0] && var.create_f5_network_on_management_vpc
        ? ["10.${4 + zone}.0.0/16", "10.${zone}0.10.0/24"]
        # default to empty
        : []
      )
    }
  }

  ##############################################################################

  ##############################################################################
  # Create map for each network and zone where each zone is a list of
  # subnet tiers to be created in that zone
  ##############################################################################

  vpc_subnet_tiers = {
    # for each network in vpc list
    for network in local.vpc_list :
    (network) => {
      for zone in [1, 2, 3] :
      "zone-${zone}" => (
        var.create_f5_network_on_management_vpc && local.use_teleport && network == var.vpcs[0] && zone == 1
        ? concat(local.f5_tiers, ["vsi", "vpn"])
        : var.create_f5_network_on_management_vpc && local.use_teleport && network == var.vpcs[0]
        # if creating f5 on management, using teleport, and network is management
        ? concat(local.f5_tiers, ["vsi"]) # Add vsi to tier
        : var.add_edge_vpc && network == local.vpc_list[0]
        # if creating edge vpc and network is edge
        ? local.f5_tiers
        : var.teleport_management_zones > 0 && network == var.vpcs[0] && zone == 1
        # if using bastion on management, network is management, and zone is 1
        ? ["vsi", "vpe", "vpn", "bastion"]
        : var.teleport_management_zones > 0 && network == var.vpcs[0] && zone <= var.teleport_management_zones
        # if teleport on management, network is management, and zone is less than or equal to total number of zones
        ? ["vsi", "vpe", "bastion"]
        : zone == 1 && network == var.vpcs[0]
        # if network is management, zone is 1, and not teleport
        ? ["vsi", "vpe", "vpn"]
        : ["vsi", "vpe"]
      )
    }
  }

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
        for network_acl in flatten(
          [
            # Flatten array of network name
            [network],
            # if using teleport and network is where bastion is provisioned, add bastion acl
            local.use_teleport && network == local.bastion_vpc ? ["bastion"] : []
          ]
        ) :
        {
          name              = "${network_acl}-acl"
          add_cluster_rules = var.add_cluster_encryption_key
          rules = flatten([
            {
              name        = "allow-ibm-inbound"
              action      = "allow"
              direction   = "inbound"
              destination = "10.0.0.0/8"
              source      = "161.26.0.0/16"
              tcp = {
                port_min = null
                port_max = null
              }
            },
            {
              name        = "allow-all-network-inbound"
              action      = "allow"
              direction   = "inbound"
              destination = "10.0.0.0/8"
              source      = "10.0.0.0/8"
              tcp = {
                port_min = null
                port_max = null
              }
            },
            {
              name        = "allow-all-outbound"
              action      = "allow"
              direction   = "outbound"
              destination = "0.0.0.0/0"
              source      = "0.0.0.0/0"
              tcp = {
                port_min = null
                port_max = null
              }
            },
            [
              # If this is bastion vpc and teleport is enabled, add 443 inbound rule to bastion vsi acl
              for bastion_rule in(local.use_teleport && network == local.bastion_vpc ? ["bastion"] : []) :
              {
                name        = "allow-bastion-443-inbound"
                action      = "allow"
                direction   = "inbound"
                destination = "10.0.0.0/8"
                source      = "0.0.0.0/0"
                tcp = {
                  port_min = 443
                  port_max = 443
                }
              }
            ]
          ])
        }
      ]
      # Use Public Gateways
      use_public_gateways = (
        # If network is edge, use teleport and no teleport zones OR teleport zones is greater than 0 && management
        (network == local.vpc_list[0] && local.use_teleport && var.teleport_management_zones == 0) || (var.teleport_management_zones > 0 && network == var.vpcs[0])
        ? local.bastion_gateways
        : local.vpc_gateways
      )

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
              # if f5 is being used, network is f5 network, and network is in f5 tiers
              var.vpn_firewall_type != null && network == local.vpc_list[0] && contains(local.f5_tiers, subnet) && local.use_f5
              ? "10.${zone + 4}.${1 + index(local.f5_tiers, subnet)}0.0/24"
              # Otherwise create regular network CIDR
              : "10.${zone + (index(var.vpcs, network) * 3)}0.${1 + index(["vsi", "vpe", "vpn", "bastion"], subnet)}0.0/24"
            )
            public_gateway = subnet == "bastion" ? true : null
            acl_name       = subnet == "bastion" ? "bastion-acl" : "${network}-acl"
          }
        ]
      }
      ##############################################################################
    }
  ]

  ##############################################################################

  ##############################################################################
  # Security Groups
  ##############################################################################

  security_groups = [
    for tier in flatten(
      [
        local.use_teleport && local.use_f5
        # if using teleport and use f5 add bastion vsi group
        ? concat(local.vpn_firewall_types[var.vpn_firewall_type], ["bastion-vsi"])
        : local.use_f5
        # if using f5 and not teleport list of security groups
        ? local.vpn_firewall_types[var.vpn_firewall_type]
        : var.teleport_management_zones > 0
        # if using teleport and not f5, use bastion security group
        ? ["bastion-vsi"]
        : []
      ]
    ) :
    local.f5_security_groups[tier]
  ]

  ##############################################################################
}

##############################################################################