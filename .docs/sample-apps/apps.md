# Sample Applications

## Table of Contents

1. [Private Only Openshift demo application](#private-only-openshift-demo-application)

## Private only Openshift demo application

This application is a simple webserver that can be deployed on a private-only OpenShift cluster that you can issue http requests to test out the ability to build and deploy an application.  Source for this is located [here](https://github.com/slzone/openshift-demo-app).

### Sample Application

When the manifest is deployed, it will automatically build and bring up a deployment of the application.  Once deployed, you will see the following pods

```bash
NAME                       READY   STATUS              RESTARTS   AGE
sample-webapp-1-deploy     0/1     Completed           0          15h
sample-webapp-1-gds9m      1/1     Running             0          15h
sample-webapp-bc-1-build   0/1     Completed           0          15h
```

By using the provisioned service, you can make http requests and get output like the following

```bash

nc sample-webapp  8080
HTTP/1.1 200 OK

Tue May 10 13:46:46 UTC 2022
```

### Toolchain

The sample application comes with an IBM Cloud DevOps Toolchain Template that can be used to provision an IBM Cloud DevOps Toolchain.   To get started, click the **Deploy to IBM Cloud** button.

[![Deploy to IBM Cloud](https://cloud.ibm.com/devops/setup/deploy/button_x2.png)](https://cloud.ibm.com/devops/setup/deploy?repository=https://github.com/slzone/openshift-demo-app.git&env_id=ibm:yp:us-south&pipeline_type=tekton)

This toolchain template will allow you to either clone the source repository to a given provider of your choice or provide a defined repository.  Also, you will provide the container service details for your OpenShift cluster along with a namespace to deploy the application.  

#### Toolchain Triggers

You can trigger the toolchain via one of three ways:

1. Manual Trigger - The toolchain will execute when you click the **Run Pipeline** button within the toolchain
2. Github Tigger - The toolchain will execute when a Github action is done.  By default, all actions are set to disabled.
3. Webhook Trigger - The toolchain will execute when the webhook is invoked.  *In order to use this trigger, you will need to set a secret within the configuration for this trigger.*  Default settings configured but can be changed accordingly:
  - Webhook URL: Generated URL at toolchain creation 
  - Token Source: *Header*
  - Header Key Name: *webhookToken*

You can edit these triggers by going to the toolchain and clicking the *Delivery Pipeline* and the **Triggers** on the left hand navigation.