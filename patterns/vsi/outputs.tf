##############################################################################
# Output Configuration
##############################################################################

output "config" {
  description = "Output configuration as encoded JSON"
  value       = data.external.format_output.result.data
}

output "sgs" {
  value = module.dynamic_values.security_groups
}

##############################################################################