#!/bin/bash

FIND_KEY=${1}

help () {
	echo <<-EOF
	This is the help text.
	EOF
}

find_key () {
	for USER in `aws iam list-users | jq -r '.Users[].UserName'`; do
		ACCESS_KEY=`aws iam list-access-keys --user-name ${USER} | jq -r '.AccessKeyMetadata[].AccessKeyId'`
		if [[ "${FIND_KEY}" == "${ACCESS_KEY}" ]]; then
			echo "Key ${ACCESS_KEY} belongs to user ${USER}"
			exit 0
		else
			continue
		fi
	done
}

if [[ -z ${1} ]]; then
	help
	exit 1
else
	find_key
fi
