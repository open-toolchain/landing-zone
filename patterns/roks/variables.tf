##############################################################################
# Account Variables
##############################################################################

variable "ibmcloud_api_key" {
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources."
  type        = string
  sensitive   = true
}

variable "TF_VERSION" {
  default     = "1.0"
  type        = string
  description = "The version of the Terraform engine that's used in the Schematics workspace."
}

variable "prefix" {
  description = "A unique identifier for resources. Must begin with a letter. This prefix will be prepended to any resources provisioned by this template."
  type        = string

  validation {
    error_message = "Prefix must begin and end with a letter and contain only letters, numbers, and - characters."
    condition     = can(regex("^([A-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.prefix))
  }
}

variable "region" {
  description = "Region where VPC will be created. To find your VPC region, use `ibmcloud is regions` command to find available regions."
  type        = string
}

variable "tags" {
  description = "List of tags to apply to resources created by this module."
  type        = list(string)
  default     = []
}

##############################################################################


##############################################################################
# VPC Variables
##############################################################################

variable "vpcs" {
  description = "List of VPCs to create. The first VPC in this list will always be considered the `management` VPC, and will be where the VPN Gateway is connected."
  type        = list(string)
  default     = ["management", "workload"]
}

variable "enable_transit_gateway" {
  description = "Create transit gateway"
  type        = bool
  default     = true
}

##############################################################################


##############################################################################
# Key Management Variables
##############################################################################

variable "hs_crypto_instance_name" {
  description = "Optionally, you can bring you own Hyper Protect Crypto Service instance for key management. If you would like to use that instance, add the name here. Otherwise, leave as null"
  type        = string
  default     = null
}

variable "hs_crypto_resource_group" {
  description = "If you're using Hyper Protect Crypto services in a resource group other than `Default`, provide the name here."
  type        = string
  default     = null
}

##############################################################################


##############################################################################
# Cluster Variables
##############################################################################

variable "zones" {
  description = "Number of zones to provision clusters for each VPC. At least one zone is required. Can be 1, 2, or 3 zones."
  type        = number
  default     = 3

  validation {
    error_message = "Cluster can be provisioned only across 1, 2, or 3 zones."
    condition     = var.zones > 0 && var.zones < 4
  }
}

variable "flavor" {
  description = "Machine type for cluster. Use the IBM Cloud CLI command `ibmcloud ks flavors` to find valid machine types"
  type        = string
  default     = "bx2.16x64"
}

variable "workers_per_zone" {
  description = "Number of workers in each zone of the cluster. OpenShift requires at least 2 workers per sone for high availability."
  type        = number
  default     = 2
}

variable "wait_till" {
  description = "To avoid long wait times when you run your Terraform code, you can specify the stage when you want Terraform to mark the cluster resource creation as completed. Depending on what stage you choose, the cluster creation might not be fully completed and continues to run in the background. However, your Terraform code can continue to run without waiting for the cluster to be fully created. Supported args are `MasterNodeReady`, `OneWorkerNodeReady`, and `IngressReady`"
  type        = string
  default     = "IngressReady"

  validation {
    error_message = "`wait_till` value must be one of `MasterNodeReady`, `OneWorkerNodeReady`, or `IngressReady`."
    condition = contains([
      "MasterNodeReady",
      "OneWorkerNodeReady",
      "IngressReady"
    ], var.wait_till)
  }
}

variable "entitlement" {
  description = "If you do not have an entitlement, leave as null. Entitlement reduces additional OCP Licence cost in OpenShift clusters. Use Cloud Pak with OCP Licence entitlement to create the OpenShift cluster. Note It is set only when the first time creation of the cluster, further modifications are not impacted Set this argument to cloud_pak only if you use the cluster with a Cloud Pak that has an OpenShift entitlement."
  type        = string
  default     = "cloud_pak"
}

##############################################################################


##############################################################################
# Override JSON
##############################################################################

variable "override" {
  description = "Override default values with custom JSON template. This uses the file `override.json` to allow users to create a fully customized environment."
  type        = bool
  default     = false
}

##############################################################################