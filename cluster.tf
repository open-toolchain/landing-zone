
##############################################################################
# Find valid IKS/Roks cluster version
##############################################################################
data "ibm_container_cluster_versions" "cluster_versions" {
  region = var.region
}

##############################################################################


##############################################################################
# Create IKS/ROKS on VPC Cluster
##############################################################################
locals {
  # Convert list to map
  clusters_map = {
    for cluster_group in var.clusters :
    (cluster_group.name) => merge(cluster_group, {
      # Add VPC ID
      vpc_id = module.vpc[cluster_group.vpc_name].vpc_id
      subnets = [
        # Add subnets to list if they are contained in the subnet list, prepends prefixes
        for subnet in module.vpc[cluster_group.vpc_name].subnet_zone_list :
        subnet if contains([
          # Create modified list of names
          for name in cluster_group.subnet_names :
          "${var.prefix}-${cluster_group.vpc_name}-${name}"
        ], subnet.name)
      ]
    })
  }
}

resource "ibm_container_vpc_cluster" "cluster" {
  for_each          = local.clusters_map
  name              = each.value.name
  vpc_id            = each.value.vpc_id
  resource_group_id = data.ibm_resource_group.resource_group.id
  flavor            = each.value.machine_type
  worker_count      = each.value.workers_per_subnet
  kube_version      = each.value.kube_type == "openshift" ? "${data.ibm_container_cluster_versions.cluster_versions.valid_openshift_versions[length(data.ibm_container_cluster_versions.cluster_versions.valid_openshift_versions) - 1]}_openshift" : data.ibm_container_cluster_versions.cluster_versions.valid_kube_versions[length(data.ibm_container_cluster_versions.cluster_versions.valid_kube_versions) - 1]
  tags              = var.tags
  wait_till         = var.wait_till
  entitlement       = each.value.entitlement
  cos_instance_crn  = each.value.kube_type == "openshift" ? each.value.cos_instance_crn : null
  pod_subnet        = each.value.pod_subnet
  service_subnet    = each.value.service_subnet

  dynamic "zones" {
    for_each = each.value.subnets
    content {
      subnet_id = zones.value["id"]
      name      = zones.value["zone"]
    }
  }

  disable_public_service_endpoint = true

}

##############################################################################


##############################################################################
# Worker Pool
##############################################################################
locals {
  # Convert list to map
  worker_pools_map = {
    for worker_pool_group in var.worker_pools :
    (worker_pool_group.name) => merge(worker_pool_group, {
      # Add VPC ID
      vpc_id = module.vpc[worker_pool_group.vpc_name].vpc_id
      subnets = [
        # Add subnets to list if they are contained in the subnet list, prepends prefixes
        for subnet in module.vpc[worker_pool_group.vpc_name].subnet_zone_list :
        subnet if contains([
          # Create modified list of names
          for name in worker_pool_group.subnet_names :
          "${var.prefix}-${worker_pool_group.vpc_name}-${name}"
        ], subnet.name)
      ]
    })
  }
}

resource "ibm_container_vpc_worker_pool" "pool" {
  for_each          = local.worker_pools_map
  vpc_id            = each.value.vpc_id
  resource_group_id = data.ibm_resource_group.resource_group.id
  entitlement       = each.value.entitlement
  cluster           = each.value.cluster_name
  worker_pool_name  = each.value.name
  flavor            = each.value.flavor
  worker_count      = each.value.workers_per_subnet

  dynamic "zones" {
    for_each = each.value.subnets
    content {
      subnet_id = zones.value["id"]
      name      = zones.value["zone"]
    }
  }
}

##############################################################################