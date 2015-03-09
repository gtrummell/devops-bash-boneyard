#!/bin/bash

# Set up some defaults
# ENVIRONMENT="{$1}"
# SERVER_ROLE="{$2}"
# SERVER_AMI="{$3}"

ENVIRONMENT="development"
SERVER_ROLE="api"
SERVER_AMI="ami-146e2a7c"

# Get availability zones for the configured region.
AVAILABILITY_ZONES=`aws ec2 describe-availability-zones | jq -r '.[][].ZoneName'`

# Set up our domain for the selected environment
case "${ENVIRONMENT}" in
"development")
	DOMAIN="bandpage-d.com"
	;;
"staging")
	DOMAIN="bandpage-s.com"
	;;
"production")
	DOMAIN="bandpage.com"
	;;
*)
	DOMAIN="bandpage-d.com"
	;;
esac

# Get all the AZ's in use by our instances of this role in this environment.
IN_USE_AZS=`knife search node "role:${SERVER_ROLE} AND chef_environment:${ENVIRONMENT}" -F json -a ec2.placement_availability_zone | jq -r '.[][][][]' | sort | uniq`

# We will launch into the first available AZ for this role in this environment.
for AVAILABILITY_ZONE in ${AVAILABILITY_ZONES}; do
	THIS_AZ_COUNT=0
	for IN_USE_AZ in ${IN_USE_AZS}; do
		if [[ "${AVAILABILITY_ZONE}" == "${IN_USE_AZ}" ]]; then
		THIS_AZ_COUNT=$((THIS_AZ_COUNT + 1))
		fi
	done

	if [[ ${THIS_AZ_COUNT} < 1 ]]; then
		SERVER_AZ="${AVAILABILITY_ZONE}"
	else
		continue
	fi
done

# Get next available name for this instance
LATEST_ORDINAL=`knife search node "role:${SERVER_ROLE} AND chef_environment:${ENVIRONMENT}" -F json -a name | jq -r '.rows[][][]' | sed 's/\..*//g' | sed 's/[a-z]//g' | sort -n | tail -n 1`

if [[ "${LATEST_ORDINAL}" < [1-9] ]]; then
	RAW_ORDINAL=$((LATEST_ORDINAL + 1))
	SERVER_ORDINAL="0${RAW_ORDINAL}"
else
	SERVER_ORDINAL=$((LATEST_ORDINAL + 1))
fi

# What are we doing?
echo "Launching ${SERVER_ROLE}${SERVER_ORDINAL}.${DOMAIN} using AMI ${SERVER_AMI} into ${ENVIRONMENT} AZ ${SERVER_AZ}"

# launch_api () {
# knife ec2 server create \
# --availability-zone us-east-1c \
# --distro chef-full \
# --ebs-size=24 \
# --environment production \
# --ephemeral /dev/sde \
# --flavor c3.xlarge \
# --groups production-api \
# --identity-file ${HOME}/.ssh/intern.pem \
# --image ami-146e2a7c \
# --node-name api25.bandpage.com \
# --run-list "role[api]" \
# --ssh-user ec2-user \
# --tags \
# "Environment=production,\
# Type=api,\
# Proxy_Role=api,\
# Name=api25.bandpage.com,
# Worker_Id=25,
# Datacenter_Id=0" \
# --yes
# }