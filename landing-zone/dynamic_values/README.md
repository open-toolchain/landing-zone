# Dynamic Values

This module compiles various dynamic values for components in `../landing-zone`. These values are compiled here to allow for the unit testing of each of these complex functions only referencing variables.

## Unit Tests

Unit tests are created in [dynamic_values.unit_tests.tf](../dynamic_values.unit_tests.tf)

## Variable Notes

Since inputs are all strongly typed, to prevent any issues with adding module and resource values, variables in this module are not typed.

## Module Variables

Name                      | Description
------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
prefix                    | A unique identifier for resources. Must begin with a letter and end with a letter or number. This prefix will be prepended to any resources provisioned by this template. Prefixes must be 16 or fewer characters.
region                    | Region where VPC will be created. To find your VPC region, use `ibmcloud is regions` command to find available regions.
vpc_modules               | Direct reference to VPC Modules
vpcs                      | Direct reference to vpcs variable
clusters                  | 
cos                       | 
cos_data_source           | 
cos_resource              | 
cos_resource_keys         | 
security_groups           | Security groups variable
resource_groups           | 
key_management            | 
key_management_guid       | 
virtual_private_endpoints | 
vpn_gateways              | VPN Gateways Variable Value
