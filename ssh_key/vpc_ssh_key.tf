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
  resource_group = each.value.resource_group_id
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