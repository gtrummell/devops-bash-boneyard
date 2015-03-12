#!/bin/bash

EXPORT_DIR="${1}"
DATA_BAGS=`knife data bag list`

for DATA_BAG in ${DATA_BAGS}; do
	ITEMS=`knife data bag show ${DATA_BAG}`
	mkdir -p "${EXPORT_DIR}/$DATA_BAG"
	for ITEM in ${ITEMS}; do
		knife data bag show ${DATA_BAG} ${ITEM} -F json | jq '.' > ${EXPORT_DIR}/${DATA_BAG}/${ITEM}.json
	done
done
