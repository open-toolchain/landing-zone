##############################################################################
# F5 Values
##############################################################################

locals {
  # Use F5
  use_f5 = var.add_edge_vpc || var.create_f5_network_on_management_vpc

  # Tiers for F5
  f5_tiers = flatten([
    ["vpn-1", "vpn-2"],
    [
      var.vpn_firewall_type != null                     # if using F5
      ? local.vpn_firewall_types[var.vpn_firewall_type] # lookup tiers
      : []                                              # default to empty
    ],
    concat(var.provision_teleport_in_f5 == true ? ["bastion"] : [], ["vpe"])
  ])

  ##############################################################################
  # Static groups for each F5 interface
  ##############################################################################
  f5_security_groups = {

    f5-management = {
      name           = "f5-management-sg"
      vpc_name       = local.vpc_list[0]
      resource_group = "${var.prefix}-${local.vpc_list[0]}-rg"
      rules = flatten([
        [
          for zone in(var.teleport_management_zones <= 0 && local.use_f5 ? [1, 2, 3] : []) :
          [
            for port in [22, 443] :
            {
              name      = "${zone}-inbound-${port}"
              direction = "inbound"
              source    = "10.${4 + zone}.${1 + index(local.f5_tiers, "bastion")}0.0/24"
              tcp = {
                port_max = port
                port_min = port
              }
            } if local.use_teleport
          ]
        ],
        [
          for rule in local.default_vsi_sg_rules :
          merge(rule, {
            tcp = {
              port_min = null
              port_max = null
            }
          })
        ]
      ])
    }

    f5-external = {
      name           = "f5-external-sg"
      vpc_name       = local.vpc_list[0]
      resource_group = "${var.prefix}-${local.vpc_list[0]}-rg"
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
      name           = "f5-workload-sg"
      vpc_name       = local.vpc_list[0]
      resource_group = "${var.prefix}-${local.vpc_list[0]}-rg"
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
          } if local.use_teleport
        ],
        [
          for rule in local.default_vsi_sg_rules :
          merge(rule, {
            tcp = {
              port_min = null
              port_max = null
            }
          })
        ]
      ])
    }

    f5-bastion = {
      name           = "f5-bastion-sg"
      vpc_name       = local.vpc_list[0]
      resource_group = "${var.prefix}-${local.vpc_list[0]}-rg"
      rules = flatten([
        for zone in(var.teleport_management_zones <= 0 && local.use_f5 ? [1, 2, 3] : []) :
        [
          for ports in [[3023, 3025], [3080, 3080]] :
          {
            name      = "${zone}-inbound-${ports[0]}"
            direction = "inbound"
            source    = "10.${4 + zone}.${1 + index(local.f5_tiers, "bastion")}0.0/24"
            tcp = {
              port_min = ports[0]
              port_max = ports[1]
            }
          }
        ] if local.use_teleport
      ])
    }

    bastion-vsi = {
      name = "bastion-vsi-sg"
      # if teleport on management, management, otherwise edge
      vpc_name       = var.teleport_management_zones > 0 ? var.vpcs[0] : local.vpc_list[0]
      resource_group = "${var.prefix}-${var.teleport_management_zones > 0 ? var.vpcs[0] : local.vpc_list[0]}-rg"
      rules = flatten([
        [
          for rule in local.default_vsi_sg_rules :
          merge(rule, {
            tcp = {
              port_min = null
              port_max = null
            }
          })
        ],
        [
          {
            name      = "allow-inbound-443"
            direction = "inbound"
            source    = "0.0.0.0/0"
            tcp = {
              port_max = 443
              port_min = 443
            }
          },
          {
            name      = "allow-all-outbound"
            direction = "outbound"
            source    = "0.0.0.0/0"
            tcp = {
              port_max = null
              port_min = null
            }
          }
        ]
      ])
    }
  }

  ##############################################################################

  ##############################################################################
  # F5 Deployment Instances
  ##############################################################################

  f5_deployments = [
    for instance in(var.vpn_firewall_type != null ? [1, 2, 3] : []) :
    {
      name                            = "f5-zone-${instance}"
      vpc_name                        = local.vpc_list[0]
      primary_subnet_name             = "f5-management-zone-${instance}"
      f5_image_name                   = var.f5_image_name
      machine_type                    = var.f5_instance_profile
      resource_group                  = "${var.prefix}-${local.vpc_list[0]}-rg"
      domain                          = var.domain
      hostname                        = var.hostname
      ssh_keys                        = ["ssh-key"]
      enable_management_floating_ip   = var.enable_f5_management_fip
      enable_external_floating_ip     = var.enable_f5_external_fip
      boot_volume_encryption_key_name = "${var.prefix}-vsi-volume-key"
      security_groups                 = ["f5-management-sg"]

      secondary_subnet_names = [
        for subnet in local.vpn_firewall_types[var.vpn_firewall_type] :
        "${subnet}-zone-${instance}" if subnet != "f5-management"
      ]
      secondary_subnet_security_group_names = [
        for subnet in local.vpn_firewall_types[var.vpn_firewall_type] :
        {
          group_name     = "${subnet}-sg"
          interface_name = "${var.prefix}-${local.vpc_list[0]}-${subnet}-zone-${instance}"
        } if subnet != "f5-management"
      ]
    } if local.use_f5
  ]

  ##############################################################################
}

##############################################################################