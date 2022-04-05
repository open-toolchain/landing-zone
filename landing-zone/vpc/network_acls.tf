##############################################################################
# Network ACL
##############################################################################

locals {
  cluster_rules = module.dynamic_values.cluster_rules
  acl_object    = module.dynamic_values.acl_map
}

resource "ibm_is_network_acl" "network_acl" {
  for_each       = local.acl_object
  name           = "${var.prefix}-${each.key}"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = var.resource_group_id

  # Create ACL rules
  dynamic "rules" {
    for_each = each.value.rules
    content {
      name        = rules.value.name
      action      = rules.value.action
      source      = rules.value.source
      destination = rules.value.destination
      direction   = rules.value.direction

      dynamic "tcp" {
        for_each = rules.value.tcp == null ? [] : [rules.value]
        content {
          port_min        = lookup(rules.value.tcp, "port_min", null)
          port_max        = lookup(rules.value.tcp, "port_max", null)
          source_port_min = lookup(rules.value.tcp, "source_port_min", null)
          source_port_max = lookup(rules.value.tcp, "source_port_min", null)
        }
      }

      dynamic "udp" {
        for_each = rules.value.udp == null ? [] : [rules.value]
        content {
          port_min        = lookup(rules.value.udp, "port_min", null)
          port_max        = lookup(rules.value.udp, "port_max", null)
          source_port_min = lookup(rules.value.udp, "source_port_min", null)
          source_port_max = lookup(rules.value.udp, "source_port_min", null)
        }
      }

      dynamic "icmp" {
        for_each = rules.value.icmp == null ? [] : [rules.value]
        content {
          type = rules.value.icmp.type
          code = rules.value.icmp.code
        }
      }
    }
  }
}

##############################################################################