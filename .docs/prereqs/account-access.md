### Setup Account Access (Cloud IAM)

1. [Create an IBM Cloud API Key](https://cloud.ibm.com/docs/account?topic=account-userapikey#create_user_key). User owning this key should be part of __admins__ group. **Necessary if manually provisioning**

2. [Setup MFA for all IBM Cloud IAM users](https://cloud.ibm.com/docs/account?topic=account-account-getting-started#account-gs-mfa).

3. [Setup Cloud IAM Access Groups](https://cloud.ibm.com/docs/account?topic=account-account-getting-started#account-gs-accessgroups). User access to cloud resources will be controlled using the Access Policies assigned to Access Groups. IBM Cloud Financial Services profile requires that all IAM users do not get assigned any accesses directly to any cloud resources. When assigning Access policies, Click "All Identity Access Enabled Services" from drop down menu.
