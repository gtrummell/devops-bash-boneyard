#!/bin/bash

NODE=${1}

INSTANCE_ID=`knife search node "name:${NODE}" -F j -a ec2.instance_id | jq -r '.rows[][]."ec2.instance_id"'`

knife ec2 server delete ${INSTANCE_ID} --node-name ${NODE} --purge