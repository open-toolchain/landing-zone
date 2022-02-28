##############################################################################
# SSH key for creating VSI
##############################################################################

locals {
  # Map of SSH Keys to Create
  create_ssh_keys = {
    for ssh_key in var.ssh_keys :
    (ssh_key.name) => ssh_key if ssh_key.public_key != null
  }

  # Map of SSH Keys to fetch
  data_ssh_keys = {
    for ssh_key in var.ssh_keys :
    (ssh_key.name) => ssh_key if ssh_key.public_key == null
  }
}

##############################################################################


##############################################################################
# Create New SSH Key
##############################################################################

resource "ibm_is_ssh_key" "ssh_key" {
  for_each       = local.create_ssh_keys
  name           = "${var.prefix}-${each.value.name}"
  public_key     = each.value.public_key
  resource_group = data.ibm_resource_group.resource_group.id
  tags           = var.tags
}

##############################################################################


##############################################################################
# Get SSH Key From Data
##############################################################################

data "ibm_is_ssh_key" "ssh_key" {
  for_each = local.data_ssh_keys
  name     = each.value.name
}

##############################################################################


##############################################################################
# All SSH Keys
##############################################################################

locals {
  ssh_key_list = flatten([
    [
      for ssh_key in local.create_ssh_keys :
      {
        name = ssh_key.name
        id   = ibm_is_ssh_key.ssh_key[ssh_key.name].id
      }
    ],
    [
      for ssh_key in local.data_ssh_keys :
      {
        name = ssh_key.name
        id   = data.ibm_is_ssh_key.ssh_key[ssh_key.name].id
      }
    ]
  ])
  ssh_keys = {
    for ssh_key in local.ssh_key_list :
    (ssh_key.name) => ssh_key.id
  }
}

##############################################################################