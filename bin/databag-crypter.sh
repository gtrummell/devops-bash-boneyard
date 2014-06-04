#!/bin/bash

DATABAG=${1}
ITEM=${2}
HOME=${HOME}

for SERVER in `knifeblock which`; do
    knifeblock use ${SERVER}
    knife data bag from file ${DATABAG} ${ITEM}.json --secret-file ${HOME}/.chef/data-bag.secret
    knife data bag show ${DATABAG} ${ITEM} -F json --secret-file ${HOME}/.chef/data-bag.secret > ${SERVER}-${ITEM}.json
done