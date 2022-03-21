# Key Management Services
<br/>

For Key Management services, user will need to provision Hyper Crypto Services or Keyprotect (optional) before deployment of the environment. 

## Hyper Crypto Service and Initialization
### To provision an instance of Hyper Protect Crypto Services IBM Cloud Console, complete the following steps:

1. Log in to your [IBM Cloud account](https://cloud.ibm.com).
2. Click Catalog to view the list of services that are available on IBM Cloud.
3. From the Catalog navigation pane, click Services. And then, under Category, select Security.
4. From the list of services displayed, click the Hyper Protect Crypto Services tile.
5. On the service page, select the pricing plan of choice.
6. Fill in the form with the details that are required.

### To initialize the provisioned Hyper Protect Crypto Service instance, we recommend to follow the product docs to perform the quick initialization.  

[Hyper Protect Cyrpto Service Documentation](https://cloud.ibm.com/docs/hs-crypto?topic=hs-crypto-get-started)

For proof of technology environments we recommend using the `auto-init` feature. [Auto Init Documentation](https://cloud.ibm.com/docs/hs-crypto?topic=hs-crypto-initialize-hsm-recovery-crypto-unit)  


## Key Protect (optional)
### To provision an instance of Key Protect from the IBM Cloud console, complete the following steps.

1. Log in to your [IBM Cloud account](https://cloud.ibm.com).
2. Click Catalog to view the list of services that are available on IBM Cloud.
3. Search for "Key Protect" in the Search the catalog... field and click ```Key Protect```.
4. Select a service plan, and click Create to provision an instance of Key Protect in the account, region, and resource group where you are logged in.


#### ** The provisioned instance information will be added to ```terraform.tfvars``` or uploaded within the schematics environment before deployment.***
