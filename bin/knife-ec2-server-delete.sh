#!/bin/bash

NODE_NAME=${1}

KNIFE_EXEC=`which knife`
INSTANCE_ID=`${KNIFE_EXEC} search node "name:${NODE_NAME}" -a ec2.instance_id -F json | jq -r '.rows[][][]'`

echo "Deleting ${NODE_NAME} with instance id ${INSTANCE_ID}"
${KNIFE_EXEC} ec2 server delete ${INSTANCE_ID} --node-name ${NODE_NAME} --purge
