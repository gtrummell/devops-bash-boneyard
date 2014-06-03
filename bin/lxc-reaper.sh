#!/bin/bash

export STACKID=$1
export LXCLIST=`grep -R ${STACKID} /var/lib/lxc/info/*|sed 's/^.*info_//g'|sed 's/\.json.*//g'`

for IMG in ${LXCLIST}
do
        lxc-stop --name ${IMG}
        lxc-destroy --name ${IMG}
        rm -f /var/lib/lxc/info/*${IMG}*
        rm -rf /var/lib/lxc/*${IMG}*
done