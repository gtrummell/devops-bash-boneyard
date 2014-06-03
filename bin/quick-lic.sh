#!/bin/bash

ITEM=${1}

ID=`grep '"id": "' ${ITEM}|awk -F\" '{print $4}'`

for server in sandboxdev corpdev; do
	knifeblock use ${server}
	knife _10.16.2_ data bag from file whisper ${ITEM} --secret-file ${HOME}/.chef/data_bag.secret
	knife _10.16.2_ data bag show whisper ${ID} -F json --secret-file ${HOME}/.chef/data_bag.secret
	knife _10.16.2_ data bag show whisper ${ID} -F json
done
