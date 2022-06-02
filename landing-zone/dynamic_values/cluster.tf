##############################################################################
# Cluster Map Function
##############################################################################

module "cluster_map" {
  source = "./config_modules/list_to_map"
  list   = var.clusters
}

module "cluster_subnets" {
  source           = "./config_modules/get_subnets"
  for_each         = module.cluster_map.value
  subnet_zone_list = var.vpc_modules[each.value.vpc_name].subnet_zone_list
  regex            = join("|", each.value.subnet_names)
}

locals {
  clusters_map = {
    for cluster_group in var.clusters :
    ("${var.prefix}-${cluster_group.name}") => merge(cluster_group, {
      vpc_id           = var.vpc_modules[cluster_group.vpc_name].vpc_id
      subnets          = module.cluster_subnets[cluster_group.name].subnets
      cos_instance_crn = cluster_group.kube_type == "openshift" ? local.cos_instance_ids[cluster_group.cos_name] : null
    })
  }

  # Create list of worker pools
  worker_pools_list = flatten([
    # For each cluster
    for cluster_group in var.clusters : [
      # For each worker pool associated with that cluster
      for worker_pool_group in cluster_group.worker_pools :
      merge(worker_pool_group, {
        # Add Cluster Name
        cluster_name = "${var.prefix}-${cluster_group.name}"
        # Add entitlement for openshift workers
        entitlement = cluster_group.kube_type == "iks" ? null : cluster_group.entitlement
        # resource group
        resource_group = cluster_group.resource_group
        # Add VPC ID
        vpc_id = var.vpc_modules[worker_pool_group.vpc_name].vpc_id
        subnets = [
          # Add subnets to list if they are contained in the subnet list, prepends prefixes
          for subnet in var.vpc_modules[cluster_group.vpc_name].subnet_zone_list :
          subnet if contains([
            # Create modified list of names
            for name in worker_pool_group.subnet_names :
            "${var.prefix}-${worker_pool_group.vpc_name}-${name}"
          ], subnet.name)
        ]

      }) if worker_pool_group != null
    ] if cluster_group.worker_pools != null
  ])

  # Covert worker pools
  worker_pools_map = {
    for pool_map in local.worker_pools_list :
    ("${pool_map.cluster_name}-${pool_map.name}") => pool_map
  }
}

##############################################################################


