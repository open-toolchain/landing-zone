# VPC Virtual Server Instance Image ID

If you bring your own image or if you use OS images that are publicly available, each OS has a defined image ID associated with it.  This image ID will be different for every image and every region.  Before you provision the toolchain, you must determine which OS you would like to run for your Virtual Server Instances.  This will be needed for the variables file later.   Please use the instructions below to get the image ID's.

## Image ID 

1. Install the [IBM Cloud CLI](https://cloud.ibm.com/docs/cli?topic=cli-install-ibmcloud-cli)
2. Log into IBM Cloud and target the region you are deploying your VPC.  Please add any additional parameters to the login command if needed.
   ```shell
   ibmcloud login -r <REGION>
   ```

3. Install the ibmcloud plugin
   ```shell
   ibmcloud plugin install vpc-infrastructure
   ```

4. Get the image ID of the OS you wish to provision with.  Make sure you do not use a deprecated image
   ```shell
   ibmcloud is images
   ```

Further documentation [here](https://cloud.ibm.com/docs/hp-virtual-servers?topic=hp-virtual-servers-byoi)