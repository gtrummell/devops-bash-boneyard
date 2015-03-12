#!/bin/bash

EXPORT_DIR="${1}"
ENVIRONMENTS=`knife environment list`

mkdir -p ${EXPORT_DIR}
for ENVIRONMENT in ${ENVIRONMENTS}; do
	knife environment show ${ENVIRONMENT} -F json > ${EXPORT_DIR}/${ENVIRONMENT}.json
done
