##############################################################################
# Create new resource groups and reference existing groups
# > Using `toset` allows for the resource groups to be assigned as 
#   `data.ibm_resource_group.resource_groups[<RESOURCE_GROUP_NAME>] for easy
#   reference
##############################################################################

data ibm_resource_group resource_groups {
  for_each = toset([for group in var.resource_groups : group.name if group.create_new != true])
  name     = each.key
}

resource ibm_resource_group resource_groups {
  for_each = toset([for group in var.resource_groups : group.name if group.create_new])
  name     = each.key
}

##############################################################################


##############################################################################
# Create a local map with resource group names as keys and ids as values
##############################################################################

locals {
  resource_groups = merge(
    {for group in data.ibm_resource_group.resource_groups :
      group.name => group.id},
    {for group in ibm_resource_group.resource_groups :
      group.name => group.id}
  )
}