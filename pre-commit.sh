#!/bin/sh
#
# A hook script to verify what is about to be committed.
# Called by "git commit" with no arguments.  The hook should
# exit with non-zero status after issuing an appropriate message if
# it wants to stop the commit.
#

NC='\033[0m' # No Color
RED='\033[0;31m'
YELLOW='\033[1;33m'

if git rev-parse --verify HEAD >/dev/null 2>&1
then
	against=HEAD
else
	# Initial commit: diff against an empty tree object
	against=$(git hash-object -t tree /dev/null)
fi

TF_RESULT=$(terraform init 2>&1 && terraform plan 2>&1)

# Case 1: Error if either terraform init or terraform plan fails 
if [[ $(echo "$TF_RESULT" | grep -i error) ]]; then 
	# Redirect output to stderr.
	exec 1>&2
	echo "${RED}Aborting commit.${NC} Please address the following errors and try again."
	echo "------------------------------------------------------------------------------------\n"
	echo "$TF_RESULT"
    exit 1
fi

TFLINT_RESULT=$(tflint . 2>&1)

# Case 2: Error if code fails to meet tflint standards 
if [[ $(echo "$TFLINT_RESULT" | grep -i error) ]]; then 
	# Redirect output to stderr.
	exec 1>&2
	echo "${RED}Aborting commit.${NC} Please address the following errors and try again."
	echo "------------------------------------------------------------------------------------\n"
	echo "$TFLINT_RESULT"
	exit 1
elif [[ $(echo "$TFLINT_RESULT" | grep -i warning) ]]; then 
	echo "${YELLOW}Allowing commit.${NC} Please note the following warnings."
	echo "------------------------------------------------------------------------------------\n"
	echo "$TFLINT_RESULT"
	exit 0
fi