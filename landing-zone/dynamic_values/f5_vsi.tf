##############################################################################
# F5 VSI Dynamic Values
##############################################################################

module "f5_vsi_map" {
  source = "./config_modules/list_to_map"
  list   = var.f5_vsi
}

module "f5_primary_subnets" {
  source           = "./config_modules/get_subnets"
  for_each         = module.f5_vsi_map.value
  subnet_zone_list = var.vpc_modules[each.value.vpc_name].subnet_zone_list
  regex            = "${var.prefix}-${each.value.vpc_name}-${each.value.primary_subnet_name}"
}

module "f5_secondary_subnets" {
  source           = "./config_modules/get_subnets"
  for_each         = module.f5_vsi_map.value
  subnet_zone_list = var.vpc_modules[each.value.vpc_name].subnet_zone_list
  regex            = join("|", each.value.secondary_subnet_names)
}

locals {
  # Convert list to map
  f5_vsi_map = {
    for vsi_group in var.f5_vsi :
    ("${var.prefix}-${vsi_group.name}") => merge(vsi_group, {
      # Add VPC ID
      vpc_id            = var.vpc_modules[vsi_group.vpc_name].vpc_id
      subnets           = module.f5_primary_subnets[vsi_group.name].subnets
      secondary_subnets = module.f5_secondary_subnets[vsi_group.name].subnets
      zone              = module.f5_primary_subnets[vsi_group.name].subnets[0].zone
    })
  }
}

module "f5_cloud_init" {
  for_each                = local.f5_vsi_map
  source                  = "../f5_config"
  region                  = var.region
  vpc_id                  = each.value.vpc_id
  zone                    = each.value.zone
  secondary_subnets       = each.value.secondary_subnets
  hostname                = each.value.hostname
  domain                  = each.value.domain
  tmos_admin_password     = lookup(var.f5_template_data, "tmos_admin_password", null) == null ? "null" : lookup(var.f5_template_data, "tmos_admin_password", null)
  license_type            = lookup(var.f5_template_data, "license_type", null) == null ? "null" : lookup(var.f5_template_data, "license_type", null)
  byol_license_basekey    = lookup(var.f5_template_data, "byol_license_basekey", null) == null ? "null" : lookup(var.f5_template_data, "byol_license_basekey", null)
  license_host            = lookup(var.f5_template_data, "license_host", null) == null ? "null" : lookup(var.f5_template_data, "license_host", null)
  license_username        = lookup(var.f5_template_data, "license_username", null) == null ? "null" : lookup(var.f5_template_data, "license_username", null)
  license_password        = lookup(var.f5_template_data, "license_password", null) == null ? "null" : lookup(var.f5_template_data, "license_password", null)
  license_pool            = lookup(var.f5_template_data, "license_pool", null) == null ? "null" : lookup(var.f5_template_data, "license_pool", null)
  license_sku_keyword_1   = lookup(var.f5_template_data, "license_sku_keyword_1", null) == null ? "null" : lookup(var.f5_template_data, "license_sku_keyword_1", null)
  license_sku_keyword_2   = lookup(var.f5_template_data, "license_sku_keyword_2", null) == null ? "null" : lookup(var.f5_template_data, "license_sku_keyword_2", null)
  license_unit_of_measure = lookup(var.f5_template_data, "license_unit_of_measure", null) == null ? "null" : lookup(var.f5_template_data, "license_unit_of_measure", null)
  do_declaration_url      = lookup(var.f5_template_data, "do_declaration_url", null) == null ? "null" : lookup(var.f5_template_data, "do_declaration_url", null)
  as3_declaration_url     = lookup(var.f5_template_data, "as3_declaration_url", null) == null ? "null" : lookup(var.f5_template_data, "as3_declaration_url", null)
  ts_declaration_url      = lookup(var.f5_template_data, "ts_declaration_url", null) == null ? "null" : lookup(var.f5_template_data, "ts_declaration_url", null)
  phone_home_url          = lookup(var.f5_template_data, "phone_home_url", null) == null ? "null" : lookup(var.f5_template_data, "phone_home_url", null)
  template_source         = lookup(var.f5_template_data, "template_source", null) == null ? "null" : lookup(var.f5_template_data, "template_source", null)
  template_version        = lookup(var.f5_template_data, "template_version", null) == null ? "null" : lookup(var.f5_template_data, "template_version", null)
  app_id                  = lookup(var.f5_template_data, "app_id", null) == null ? "null" : lookup(var.f5_template_data, "app_id", null)
  tgactive_url            = lookup(var.f5_template_data, "tgactive_url", null) == null ? "null" : lookup(var.f5_template_data, "tgactive_url", null)
  tgstandby_url           = lookup(var.f5_template_data, "tgstandby_url", null) == null ? "null" : lookup(var.f5_template_data, "tgstandby_url", null)
  tgrefresh_url           = lookup(var.f5_template_data, "tgrefresh_url", null) == null ? "null" : lookup(var.f5_template_data, "tgrefresh_url", null)
}


##############################################################################