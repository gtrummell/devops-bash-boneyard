#!/bin/bash

HOME=${HOME}

DATABAG=${1}
ITEM=${2}
SECRET="${HOME}/.chef/data_bag.secret"

for VAR in ${DATABAG} ${ITEM} ${HOME}; do
    if [ -z ${VAR} ]; then
        echo "All command-line arguments are required! Missing ${VAR}"
    fi
done

for SERVER in `knifeblock list`; do
    knifeblock use ${SERVER}
    knife _10.16.2_ data bag from file ${DATABAG} "`pwd`/${ITEM}.json" --secret-file ${SECRET}
    knife _10.16.2_ data bag show ${DATABAG} ${ITEM} -F json > ${SERVER}-${ITEM}-encrypted.json
    knife _10.16.2_ data bag show ${DATABAG} ${ITEM} -F json --secret-file ${SECRET} > ${SERVER}-${ITEM}-cleartext.json
done