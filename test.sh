#!/bin/bash

ENVS='development production staging'
for ENV in ${ENVS}; do
	ENV_DETECT=`echo ${@} | grep -i ${ENV} | wc -l`
	if [[ "${ENV_DETECT}" == "1" ]]; then
		ENVIRONMENT=${ENV}
		break
	fi
done

if [[ -z ${ENVIRONMENT} ]]; then
	echo "No environment directive detected on the command line."
	exit 1
fi


echo ${ENVIRONMENT}