##############################################################################
# Create F5 VSI
##############################################################################

locals {
  f5_vsi_map = module.dynamic_values.f5_vsi_map
}

##############################################################################

##############################################################################
# F5 Image IDs
##############################################################################

locals {
  # use the public image if the name is found
  # List of public images found in F5 schematics documentation
  # (https://github.com/f5devcentral/ibmcloud_schematics_bigip_multinic_public_images)
  public_image_map = {
    f5-bigip-15-1-2-1-0-0-10-all-1slot-1 = {
      "us-south" = "r006-96eff507-273e-48af-8790-74c74cf4cebd"
      "us-east"  = "r014-fb2140e2-97dd-4cfa-a480-49c36023169a"
      "eu-gb"    = "r018-797c97bd-a1b9-4e83-ba22-e557a8938cab"
      "eu-de"    = "r010-759f402f-da71-4719-bf9c-dec955610032"
      "jp-tok"   = "r022-16b8c452-3fa2-40b0-8ae9-8f1a3b1b9459"
      "au-syd"   = "r026-99c64581-ce8c-48a3-ae3a-7aba1e651344"
      "jp-osa"   = "r034-d8385b38-870f-453a-b33e-8b40ceec0450"
      "ca-tor"   = "r038-ef27dfd1-1564-48ff-af2a-d9092dd4ffb9"
    }
    f5-bigip-15-1-2-1-0-0-10-ltm-1slot-1 = {
      "us-south" = "r006-17a5e435-cfd6-44b5-9c52-1eabe26445af"
      "us-east"  = "r014-29af1cf4-9436-4934-a2c4-c7330d1f88cf"
      "eu-gb"    = "r018-d1add662-3591-40da-b80c-f62a191cb60a"
      "eu-de"    = "r010-5dc287cb-b9d5-4889-9a43-ca3a38c5b457"
      "jp-tok"   = "r022-76a7fcf7-df8d-452a-9e96-4c17ded591ae"
      "au-syd"   = "r026-6ae75968-955f-4b9b-9f2a-d5dcbccadd63"
      "jp-osa"   = "r034-7721a3b3-a5ec-4c7e-9420-c945ba56cbfe"
      "ca-tor"   = "r038-9da83b4a-eaeb-47d1-90c4-81b02c856bed"
    }
    f5-bigip-16-0-1-1-0-0-6-ltm-1slot-1 = {
      "us-south" = "r006-bc5a723a-752c-4fdb-b6c9-a8fd3c587bd3"
      "us-east"  = "r014-74c06b64-0b4a-4ad1-840b-16f67f566ad5"
      "eu-gb"    = "r018-446eb09c-a047-4644-8731-bc032bfb6f37"
      "eu-de"    = "r010-718b1266-a407-4d5b-8b08-93fd05fc1db6"
      "jp-tok"   = "r022-ff687ace-0325-4dd7-81d7-eaf0e5a378a5"
      "au-syd"   = "r026-4102137d-6abf-40e9-9d77-69c6f4cc5cc2"
      "jp-osa"   = "r034-ab405ea1-68a4-437c-b180-f2834ab14b16"
      "ca-tor"   = "r038-2d523ada-b257-4add-97fd-d084bc92ea42"
    }
    f5-bigip-16-0-1-1-0-0-6-all-1slot-1 = {
      "us-south" = "r006-fe9e266b-5f74-4809-a348-f779e70353cb"
      "us-east"  = "r014-84ed1e28-5bc0-4d3f-8de6-68d8a28327bb"
      "eu-gb"    = "r018-387d2b15-6958-424a-ab74-d6561dccef9f"
      "eu-de"    = "r010-50c6a70c-3222-4cd9-8cb9-5dc3bdef019c"
      "jp-tok"   = "r022-16f09456-9409-487e-b7ec-34f72a7db826"
      "au-syd"   = "r026-4c50432b-28c5-41ef-8031-b3104c46de77"
      "jp-osa"   = "r034-a3450582-5dd2-475c-a423-c18e1141df36"
      "ca-tor"   = "r038-c6ab2957-3937-4c63-a842-9c8aac9d502b"
    }
  }
}

##############################################################################


##############################################################################
# Create F5
##############################################################################

module "f5_vsi" {
  source                      = "./vsi"
  for_each                    = local.f5_vsi_map
  resource_group_id           = each.value.resource_group == null ? null : local.resource_groups[each.value.resource_group]
  create_security_group       = each.value.security_group == null ? false : true
  prefix                      = "${var.prefix}-${each.value.name}"
  vpc_id                      = module.vpc[each.value.vpc_name].vpc_id
  subnets                     = each.value.subnets
  secondary_subnets           = each.value.secondary_subnets
  secondary_allow_ip_spoofing = true
  secondary_security_groups = [
    for group in each.value.secondary_subnet_security_group_names :
    {
      security_group_id = ibm_is_security_group.security_group[group.group_name].id
      interface_name    = group.interface_name
    }
  ]
  image_id       = lookup(local.public_image_map[each.value.f5_image_name], var.region)
  user_data      = module.dynamic_values.f5_template_map[each.key].user_data
  machine_type   = each.value.machine_type
  vsi_per_subnet = 1
  security_group = each.value.security_group
  load_balancers = each.value.load_balancers == null ? [] : each.value.load_balancers
  # Get boot volume
  boot_volume_encryption_key = each.value.boot_volume_encryption_key_name == null ? "" : [
    for keys in module.key_management.keys :
    keys.id if keys.name == each.value.boot_volume_encryption_key_name
  ][0]
  # Get security group ids
  security_group_ids = each.value.security_groups == null ? [] : [
    for group in each.value.security_groups :
    ibm_is_security_group.security_group[group].id
  ]
  # Get ssh keys
  ssh_key_ids = [
    for ssh_key in each.value.ssh_keys :
    lookup(module.ssh_keys.ssh_key_map, ssh_key).id
  ]
  # Get block storage volumes
  block_storage_volumes = each.value.block_storage_volumes == null ? [] : [
    # For each block storage volume
    for volume in each.value.block_storage_volumes :
    # Merge volume and add encryption key
    {
      name     = volume.name
      profile  = volume.profile
      capacity = volume.capacity
      iops     = volume.iops
      encryption_key = lookup(volume, "encryption_key", null) == null ? null : [
        for key in module.key_management.keys :
        key.id if key.name == volume.encryption_key
      ][0]
    }
  ]
  enable_floating_ip     = each.value.enable_management_floating_ip == true ? true : false
  secondary_floating_ips = each.value.enable_external_floating_ip == true ? [each.value.secondary_subnets[0].name] : []
  depends_on             = [module.ssh_keys]
}

##############################################################################
