# Landing Zone VSI Pattern 

This template allows a user to create a landing zone


![mixed](../../.docs/roks.png)

## Module Variables

Name                    | Type         | Description                                                                                                                                                                     | Sensitive | Default
----------------------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ----------------------------------
ibmcloud_api_key        | string       | The IBM Cloud platform API key needed to deploy IAM enabled resources.                                                                                                          | true      | 
TF_VERSION              | string       | The version of the Terraform engine that's used in the Schematics workspace.                                                                                                    |           | 1.0
prefix                  | string       | A unique identifier for resources. Must begin with a letter. This prefix will be prepended to any resources provisioned by this template.                                       |           | 
region                  | string       | Region where VPC will be created. To find your VPC region, use `ibmcloud is regions` command to find available regions.                                                         |           | 
tags                    | list(string) | List of tags to apply to resources created by this module.                                                                                                                      |           | []
vpcs                    | list(string) | List of VPCs to create                                                                                                                                                          |           | ["management", "workload"]
enable_transit_gateway  | bool         | Create transit gateway                                                                                                                                                          |           | true
hs_crypto_instance_name | string       | Optionally, you can bring you own Hyper Protect Crypto Service instance for key management. If you would like to use that instance, add the name here. Otherwise, leave as null |           | null
ssh_public_key          | string       | Public SSH Key for VSI creation.                                                                                                                                                |           | 
vsi_image_name          | string       | VSI image name. Use the IBM Cloud CLI command `ibmcloud is images` to see availabled images.                                                                                    |           | ibm-ubuntu-16-04-5-minimal-amd64-1
vsi_instance_profile    | string       | VSI image profile. Use the IBM Cloud CLI command `ibmcloud is instance-profiles` to see available image profiles.                                                               |           | cx2-2x4
vsi_per_subnet          | number       | Number of Virtual Servers to create on each VSI subnet.                                                                                                                         |           | 1
override                | bool         | Override default values with custom JSON template. This uses the file `override.json` to allow users to create a fully customized environment.                                  |           | false

## Using override.json

To create a fully customized environment based on the starting template, users can use [override.json](./override.json) by setting the template `override` variable to `true`.

### Variable Definitions

By using the variable deifnitions found in our [landing zone module](../../landing-zone/) any number and custom configuration of VPC components, VSI workoads, and clusters can be created. Currently `override.json` is set to contain the default environment configuration.

### Getting Your Environment

This module outputs `config`, a JSON encoded definition of your environment based on the defaults for Landing Zone and any variables changed using `override.json`. By using this output, it's easy to configure multiple additional workloads, VPCs, or subnets in existing VPCs to the default environment.

### Overriding Only Some Veriables

`override.json` does not need to contain all elements. As an example override.json could be:
```json
{
    "enable_transit_gateway": false
}
```

In this use case, each other value would be the default configuration, just with a transit gateway disabled.

# Technical Docs go here