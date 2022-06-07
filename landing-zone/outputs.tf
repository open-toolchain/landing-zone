##############################################################################
# Appid Outputs
##############################################################################

locals {
  appid_instance = (
    local.create_bastion_host == false # if no bastion host
    ? null                             # null
    : local.create_appid == "data"
    ? data.ibm_resource_instance.appid
    : ibm_resource_instance.appid
  )
}

output "appid_name" {
  description = "Name of the appid instance used."
  value       = local.appid_instance == null ? null : local.appid_instance[0].name
}

output "appid_key_names" {
  description = "List of appid key names created"
  value = [
    for instance in ibm_resource_key.appid_key :
    instance.name
  ]
}

output "appid_redirect_urls" {
  description = "List of appid redirect urls"
  value       = ibm_appid_redirect_urls.urls.*.urls
}

##############################################################################

##############################################################################
# Atracker Outputs
##############################################################################

output "atracker_target_name" {
  description = "Name of atracker target"
  value       = ibm_atracker_target.atracker_target.name
}

output "atracker_route_name" {
  description = "Name of atracker route"
  value       = ibm_atracker_route.atracker_route.*.name
}

##############################################################################

##############################################################################
# Bastion Host Outputs
##############################################################################

output "bastion_host_names" {
  description = "List of bastion host names"
  value = flatten([
    for instance in keys(module.bastion_host) :
    module.bastion_host[instance].list.*.name
  ])
}

##############################################################################

##############################################################################
# Cluster Outputs
##############################################################################

output "cluster_names" {
  description = "List of create cluster names"
  value = [
    for cluster in ibm_container_vpc_cluster.cluster :
    cluster.name
  ]
}

##############################################################################

##############################################################################
# COS Outputs
##############################################################################

output "cos_names" {
  description = "List of Cloud Object Storage instance names"
  value = flatten([
    [
      for instance in data.ibm_resource_instance.cos :
      instance.name
    ],
    [
      for instance in ibm_resource_instance.cos :
      instance.name
    ]
  ])
}

output "cos_key_names" {
  description = "List of names for created COS keys"
  value = [
    for instance in ibm_resource_key.key :
    instance.name
  ]
}

output "cos_bucket_names" {
  description = "List of names for COS buckets creaed"
  value = [
    for instance in ibm_cos_bucket.buckets :
    instance.bucket_name
  ]
}

##############################################################################

##############################################################################
# F5 Outputs
##############################################################################

output "f5_host_names" {
  description = "List of bastion host names"
  value = flatten([
    for instance in keys(module.f5_vsi) :
    module.f5_vsi[instance].list.*.name
  ])
}

##############################################################################