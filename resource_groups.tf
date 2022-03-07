##############################################################################
# Create new resource groups and reference existing groups
# > Using `toset` allows for the resource groups to be assigned as 
#   `data.ibm_resource_group.resource_groups[<RESOURCE_GROUP_NAME>] for easy
#   reference
##############################################################################

data "ibm_resource_group" "resource_groups" {
  for_each = {
    for group in var.resource_groups :
    (group.name) => group if group.create != true
  }
  name = each.value.use_prefix == true ? "${var.prefix}-${each.key}" : each.key
}

resource "ibm_resource_group" "resource_groups" {
  for_each =  {
    for group in var.resource_groups :
    (group.name) => group if group.create == true
  }
  name = each.value.use_prefix == true ? "${var.prefix}-${each.key}" : each.key
}

##############################################################################


##############################################################################
# Create a local map with resource group names as keys and ids as values
##############################################################################

locals {
  resource_groups = merge(
    {
      for group in data.ibm_resource_group.resource_groups :
      group.name => group.id
    },
    {
      for group in ibm_resource_group.resource_groups :
      group.name => group.id
    }
  )
}

##############################################################################