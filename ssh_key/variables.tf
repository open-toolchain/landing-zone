##############################################################################
# SSH Key Variables
##############################################################################

variable "ssh_keys" {
  description = "SSH Keys to use for VSI Provision. If `public_key` is not provided, the named key will be looked up from data."
  type = list(
    object({
      name       = string
      public_key = optional(string)
    })
  )
  default = [
    {
      name       = "dev-ssh-key"
      public_key = "<ssh public key>"
    }
  ]

  validation {
    error_message = "Each SSH key must have a unique name."
    condition     = length(distinct(var.ssh_keys.*.name)) == length(var.ssh_keys.*.name)
  }

  validation {
    error_message = "Each key using the public_key field must have a unique public key."
    condition = length(
      distinct(
        [
          for ssh_key in var.ssh_keys :
          ssh_key.public_key if ssh_key.public_key != null
        ]
      )
      ) == length(
      [
        for ssh_key in var.ssh_keys :
        ssh_key.public_key if ssh_key.public_key != null
      ]
    )
  }
}

##############################################################################