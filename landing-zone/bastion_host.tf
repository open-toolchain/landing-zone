##############################################################################  
# Bastion Host Locals
##############################################################################

locals {
  bastion_vsi_map = module.dynamic_values.bastion_vsi_map
}

##############################################################################


##############################################################################
# Configure Teleport
##############################################################################

module "teleport_config" {
  for_each                  = module.dynamic_values.bastion_template_data_map
  source                    = "./teleport_config"
  TELEPORT_LICENSE          = base64encode(each.value.TELEPORT_LICENSE)
  HTTPS_CERT                = base64encode(each.value.HTTPS_CERT)
  HTTPS_KEY                 = base64encode(each.value.HTTPS_KEY)
  HOSTNAME                  = each.key
  DOMAIN                    = each.value.DOMAIN
  COS_BUCKET                = ibm_cos_bucket.buckets[each.value.COS_BUCKET].bucket_name
  COS_BUCKET_ENDPOINT       = ibm_cos_bucket.buckets[each.value.COS_BUCKET].s3_endpoint_public
  HMAC_ACCESS_KEY_ID        = ibm_resource_key.key[each.value.cos_key_name].credentials["cos_hmac_keys.access_key_id"]
  HMAC_SECRET_ACCESS_KEY_ID = ibm_resource_key.key[each.value.cos_key_name].credentials["cos_hmac_keys.secret_access_key"]
  APPID_CLIENT_ID           = ibm_resource_key.appid_key[each.value.app_id_key_name].credentials["clientId"]
  APPID_CLIENT_SECRET       = ibm_resource_key.appid_key[each.value.app_id_key_name].credentials["secret"]
  APPID_ISSUER_URL          = ibm_resource_key.appid_key[each.value.app_id_key_name].credentials["oauthServerUrl"]
  TELEPORT_VERSION          = each.value.TELEPORT_VERSION
  CLAIM_TO_ROLES            = each.value.CLAIM_TO_ROLES
  MESSAGE_OF_THE_DAY        = each.value.MESSAGE_OF_THE_DAY

  depends_on = [
    ibm_cos_bucket.buckets
  ]

}

##############################################################################


##############################################################################
# Create Bastion Host
##############################################################################

module "bastion_host" {
  source = "./vsi"

  for_each              = local.bastion_vsi_map
  resource_group_id     = each.value.resource_group == null ? null : local.resource_groups[each.value.resource_group]
  create_security_group = each.value.security_group == null ? false : true
  prefix                = "${var.prefix}-${each.value.name}"
  vpc_id                = module.vpc[each.value.vpc_name].vpc_id
  subnets               = each.value.subnets
  vsi_per_subnet        = 1
  boot_volume_encryption_key = each.value.boot_volume_encryption_key_name == null ? "" : [
    for keys in module.key_management.keys :
    keys.id if keys.name == each.value.boot_volume_encryption_key_name
  ][0]
  image_id  = data.ibm_is_image.image["${var.prefix}-${each.value.name}"].id
  user_data = module.teleport_config["${var.prefix}-${each.value.name}-${each.value.subnet_name}"].cloud_init
  security_group_ids = each.value.security_groups == null ? [] : [
    for group in each.value.security_groups :
    ibm_is_security_group.security_group[group].id
  ]
  ssh_key_ids = [
    for ssh_key in each.value.ssh_keys :
    lookup(module.ssh_keys.ssh_key_map, ssh_key).id
  ]
  machine_type       = each.value.machine_type
  security_group     = each.value.security_group
  enable_floating_ip = false
  depends_on         = [module.ssh_keys]
}

##############################################################################