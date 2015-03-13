#!/bin/bash

#AWS-KEY="${1}"

USERS=`aws iam list-users | jq -r '.Users[].UserName'`

for USER in ${USERS}; do
	aws iam list-access-keys --user-name ${USER} | jq '.AccessKeyMetadata[]'
done
