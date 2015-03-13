#!/bin/bash

# Collection point
DB_DIR='~/tmp/data_bags'

# Collect data from data bags

for BAG in `knife data bag list`; do
	echo "Showing data bag ${BAG}:"
	mkdir -p ${DB_DIR}/${BAG}
	for ITEM in `knife data bag show ${BAG}`; do
		echo "Showing encyrpted data in data bag item ${ITEM}:"
		knife data bag show ${BAG} ${ITEM} -F json > ${DB_DIR}/${BAG}/${ITEM}.json
		cat ${DB_DIR}/${BAG}/${ITEM}.json | jq '.'
	done
done
