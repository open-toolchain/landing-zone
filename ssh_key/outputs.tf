##############################################################################
# All SSH Keys
##############################################################################

output ssh_keys {
  description = "List of SSH keys from this module."
  value = flatten([
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
}

##############################################################################