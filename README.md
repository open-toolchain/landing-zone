# IBM Secure Landing Zone

## Table of Contents

1. [Prerequisites](#prerequisites)
    1. [Setting Up an IBM Cloud Account](#setting-up-an-ibm-cloud-account)
    2. [Setup IBM Cloud Account for Secure Landing Zone](#setup-ibm-cloud-account-for-secure-landing-zone)
    3. [Setup Account Access (Cloud IAM)](#setup-account-access-cloud-iam)
    4. [Repository Authorization](#repository-authorization)
    5. [(Optional) Setting Up Hyper Protect Crypto Services](#optional-setting-up-hyper-protect-crypto-services)
2. [Patterns](#patterns)
3. [Default Landing Zone Configuration](#default-landing-zone-configuration)
    - [Resource Groups](#resoure-groups)
    - [Cloud Services](#cloud-services)
    - [VPC Infrastructure](#vpc-infrastructure)
3. [Customizing Your Environment](#customizing-your-environment)
---

## Prerequisites

To ensure that Secure Landing Zone can be deployed, esure that the following steps have been completed before deployment.

---

### Setting Up an IBM Cloud Account

An IBM Cloud account is required. An Enterprise account is recommended but Pay as you Go account suffices to deploy secure landing zone cloud resources. 

If you do not already have an account, follow instructions [to create the account](https://cloud.ibm.com/docs/account?topic=account-account-getting-started#account-gs-createlite) and [upgrade to Pay-as-you-Go](https://cloud.ibm.com/docs/account?topic=account-account-getting-started#account-gs-upgrade)

- Have access to an [IBM Cloud account](https://cloud.ibm.com/docs/account?topic=account-account-getting-started). An Enterprise account is recommended but a Pay as you Go account should also work with this automation.

---

### Setup IBM Cloud Account for Secure Landing Zone

1. Log into IBM Cloud [console](https://cloud.ibm.com) using the IBMid you used to setup the account. This IBMid user is the account __owner__ and has all the IAM accesses.

2. [Complete the company profile and contacts information](https://cloud.ibm.com/docs/account?topic=account-contact-info) for the account. This is required to stay in compliance with IBM Cloud Financial Service profile.

3. [Enable the flag](https://cloud.ibm.com/docs/account?topic=account-enabling-fs-validated) to designate your IBM Cloud account to be Financial Services Validated.

4. Enable VRF and Service Endpoints. This requires creating a support case. Follow [instructions](https://cloud.ibm.com/docs/account?topic=account-vrf-service-endpoint#vrf) carefully.

---

### Setup Account Access (Cloud IAM)

1. [Create an IBM Cloud API Key](https://cloud.ibm.com/docs/account?topic=account-userapikey#create_user_key). User owning this key should be part of __admins__ group. **Necessary if manually provisioning**

2. [Setup MFA for all IBM Cloud IAM users](https://cloud.ibm.com/docs/account?topic=account-account-getting-started#account-gs-mfa).

3. [Setup Cloud IAM Access Groups](https://cloud.ibm.com/docs/account?topic=account-account-getting-started#account-gs-accessgroups). User access to cloud resources will be controlled using the Access Policies assigned to Access Groups. IBM Cloud Financial Services profile requires that all IAM users do not get assigned any accesses directly to any cloud resources. When assigning Access policies, Click "All Identity Access Enabled Services" from drop down menu.

---

### (Optional) Setting Up Hyper Protect Crypto Services

For Key Management services, user can optionally use Hyper Protect Crypto Services. This instance will need to be created before creating the Secure Landing Zone.

#### Hyper Crypto Service and Initialization

##### Creating HPCS Using the IBM Cloud CLI

To provision an instance of Hyper Protect Crypto Services IBM Cloud Console, complete the following steps:

1. Log in to your [IBM Cloud account](https://cloud.ibm.com).
2. Click Catalog to view the list of services that are available on IBM Cloud.
3. From the Catalog navigation pane, click Services. And then, under Category, select Security.
4. From the list of services displayed, click the Hyper Protect Crypto Services tile.
5. On the service page, select the pricing plan of choice.
6. Fill in the form with the details that are required.

##### Initializing HPCS

To initialize the provisioned Hyper Protect Crypto Service instance, we recommend to follow the product docs to perform the quick initialization.  

[Hyper Protect Cyrpto Service Documentation](https://cloud.ibm.com/docs/hs-crypto?topic=hs-crypto-get-started)

For proof of technology environments we recommend using the `auto-init` feature. [Auto Init Documentation](https://cloud.ibm.com/docs/hs-crypto?topic=hs-crypto-initialize-hsm-recovery-crypto-unit)  

-----

### Repository Authorization

The toolchain requires authorization to access your repository.  If it does not have access, the toolchain will request that you authorize access.  Below shows you how you can create a personal access token for your repository

- [GitHub and GitHub Enterprise](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [GitLab](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html)
- [Bitbucket](https://confluence.atlassian.com/bitbucketserver/personal-access-tokens-939515499.html)

You can manage your authorizations via [Manage Git Authorizations](https://cloud.ibm.com/devops/git)

---

## Patterns

The [landing zone module](./landing-zone/) can be used to create a fully cusomizable VPC environment. The three patterns below are each starting templates that can be used to quickly get started with Landing Zone. These patterns can be found in the [patterns](./patterns/) directory.

Each of these patterns creates:
- A resource group for cloud services and for each VPC.
- Object storage instances for flow logs and activity tracker
- Encryption keys in either a Key Protect or Hyper Protect Crypto Services instance
- A management and workload VPC connected by a transit gateway
- A flow log collector for each VPC
- All nessecary networking rules to allow communication
- Virtual Private endpoints for Cloud Object storage in each VPC
- A VPN Gateway in the Management VPC

Each pattern will create an identical deployment on the VPC
- Virtual Server (VSI) Pattern will deploy identical virtual servers across the VSI subnet tier in each VPC
- Red Hat OpenShift Kubernetes (ROKS) Pattern will deploy identical clusters across the VSI subnet tier in each VPC
- The Mixed pattern will provision both of the above

### Virtual Server Pattern

![vsi](./.docs/vsi.png)

### Red Hat OpenShift Pattern

![vsi](./.docs/roks.png)

### Mixed Pattern

![vsi](./.docs/mixed.png)

--- 

## Default Landing Zone Configuration

---

### Resource Groups

Each of these resource groups will have the `prefix` variable and a hyphen prepended to the name

Name            | Description
----------------|------------------------------------------------
`management-rg` | Management Virtual Infrastructure Components
`workload-rg`   | Workload Virtual Infrastructure Components
`service-rg`    | Cloud Service Instances

---

### Cloud Services

#### Key Management

By default a Key Protect instance is created unless the `hs_crypto_instance_name` variable is provided. Key Protect instances by default will be provisioned in the `service-rg` resource group.

##### Keys

Name            | Description
----------------|------------------------------------------------
`atracker-key`  | Encryption key for Activity Tracker Instance
`slz-key`       | Landing Zone services encryption key

---

#### Cloud Object Storage

Two Cloud Object Storage instances are created in the `service-rg` by default

Name            | Description
----------------|------------------------------------------------
`atracker-cos`  | Object storage for Activity Tracker
`cos`           | Object storage

##### Object Storage Buckets

Name                | Instance       | Encryption Key | Description
--------------------|----------------|----------------|---------------------------------------------
`atracker-bucket`   | `atracker-cos` | `atracker-key` | Bucket for activity tracker logs
`management-bucket` | `cos`          | `slz-key`      | Bucket for flow logs from Management VPC
`workload-bucket`   | `cos`          | `slz-key`      | Bucket for flow logs from Workload VPC

##### Object Storage API Keys

An API key is automatially generated for the `atracker-cos` instance to allow Activity Tracker to connect successfully to Cloud Object Storage

---

#### Activity Tracker

An [Activity Tracker](url-here) instance is provisioned for this architecture.

---

### VPC Infrastructure

By default, two VPCs ae created `management` and `workload`. All the components for the management VPC are provisioned in the `management-rg` resource group and the workload VPC components are all provisioned in the `workload-rg` resource group.

---

#### Network Access Control Lists

An [Access Control List](url-goes-here) is created for each VPC to allow inbound communiction within the network, inbound communication from IBM services, and to allow all outbound traffic.

Rule                        | Action | Direction | Source        | Destination 
----------------------------|--------|-----------|---------------|----------------
`allow-ibm-inbound`         | Allow  | Inbound   | 161.26.0.0/16 | 10.0.0.0/8
`allow-all-network-inbound` | Allow  | Inbound   | 10.0.0.0/8    | 10.0.0.0/8
`allow-all-outbound`        | Allow  | Outbound  | 0.0.0.0/0     | 0.0.0.0/0

---

#### Subnets

Each VPC creates two tiers of subnets, each attached to the Network ACL created for that VPC. The Management VPC also has a subnet created for creation of the VPN Gateway

##### Management VPC Subnets

Name         | Zone | Subnet CIDR
-------------|------|-------------
`vsi-zone-1` | 1    | 10.10.10.0/24
`vpe-zone-1` | 1    | 10.10.20.0/24
`vpn-zone-1` | 1    | 10.10.30.0/24
`vsi-zone-2` | 2    | 10.20.10.0/24
`vpe-zone-2` | 2    | 10.20.20.0/24
`vsi-zone-3` | 3    | 10.30.10.0/24
`vpe-zone-3` | 3    | 10.30.20.0/24

##### Workload VPC Subnets

Name         | Zone | Subnet CIDR
-------------|------|-------------
`vsi-zone-1` | 1    | 10.40.10.0/24
`vpe-zone-1` | 1    | 10.40.20.0/24
`vsi-zone-2` | 2    | 10.50.10.0/24
`vpe-zone-2` | 2    | 10.50.20.0/24
`vsi-zone-3` | 3    | 10.60.10.0/24
`vpe-zone-3` | 3    | 10.60.20.0/24

---

#### Flow Logs

Using the COS bucket provisioned for each VPC network, a flow log collector is created.

----

#### Virtual Private Endpoints

Each VPC dyamically has a Virtual Private Endpoint addess for the `cos` instance created in each zone of that VPC's `vpe` subnet tier.