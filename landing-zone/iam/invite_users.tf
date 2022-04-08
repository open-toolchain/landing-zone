##############################################################################
# Add users to access group after invite
##############################################################################

locals {
  access_groups_with_invites = {
    for group in local.access_groups_object :
    group.name => group if group.invite_users != null
  }
}

resource "ibm_iam_access_group_members" "group_members" {
  for_each        = local.access_groups_with_invites
  access_group_id = ibm_iam_access_group.groups[each.key].id
  ibm_ids         = each.value.invite_users
}

##############################################################################
