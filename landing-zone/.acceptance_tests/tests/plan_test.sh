# Run terraform plan and return JSON

#!/bin/bash
export TF_VAR_ibmcloud_api_key=$1
FILE_PATH=$2
cd $FILE_PATH
QUIET=$(terraform init)
QUIET=$(terraform plan -out=tfplan)
terraform show -json tfplan | jq
QUIET=$(rm -rf tfplan .terraform/ .terraform.lock.hcl)