##############################################################################
# Variables
##############################################################################

variable "list" {
  description = "List of objects"
}

variable "prefix" {
  description = "Prefix to add to map keys"
  type        = string
  default     = ""
}

variable "key_name_field" {
  description = "Key inside each object to use as the map key"
  type        = string
  default     = "name"
}

##############################################################################

##############################################################################
# Output
##############################################################################

output "value" {
  description = "List converted into map"
  value = {
    for item in var.list :
    ("${var.prefix == "" ? "" : "${var.prefix}-"}${item[var.key_name_field]}") => (
      item
    )
  }
}

##############################################################################