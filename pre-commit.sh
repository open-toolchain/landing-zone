#!/bin/sh
#
# A hook script to verify what is about to be committed.
# Called by "git commit" with no arguments.  The hook should
# exit with non-zero status after issuing an appropriate message if
# it wants to stop the commit.
#

if git rev-parse --verify HEAD >/dev/null 2>&1
then
	against=HEAD
else
	# Initial commit: diff against an empty tree object
	against=$(git hash-object -t tree /dev/null)
fi

# Redirect output to stderr.
exec 1>&2

TFLINT_RESULT=$(tflint .)

if [[ $(echo "$TFLINT_RESULT" | grep -i error) ]]; then 
	cat <<EOF
------------------------------------------------------------------------------------
Aborting commit. Please address the following errors and try again. 
------------------------------------------------------------------------------------

$TFLINT_RESULT

EOF
    exit 1
elif [[ $(echo "$TFLINT_RESULT" | grep -i warning) ]]; then 
	cat <<EOF
------------------------------------------------------------------------------------
Allowing commit. However, please note the following warnings. 
------------------------------------------------------------------------------------

$TFLINT_RESULT

EOF
    exit 0
fi