#!/bin/bash

# Set the the command line argument to a script variable.
TARGET=${1}


# Function to set up exit code tests.
function testwarn {
    if [ $? -ne 0 ]; then
        echo "Invalid input. Usage:"
        echo "$0 [HOST|FILENAME]"
    fi
}

function testfail {
    testwarn
    exit 1
}

# Function to get up ip addresses for hosts and the VPN gateway
function getvpn {
    VPN=`ifconfig|grep inet|grep 10.160|awk '{print $2}'` || testwarn
}

function gethost {
    HOST=`nslookup ${ENTRY}|grep Address\:\ [1-9]|awk '{print $2}'` || testwarn
}

# Function to set a single host
function sethost {
    sudo route add -host ${HOST} ${VPN} || testfail
}

# Get VPN IP
getvpn

# Begin route add operations
if [ -f ${TARGET} ]; then
    for ENTRY in `cat ${TARGET}|grep -v ^\#`; do
        gethost
        echo "adding route to ${ENTRY}"
        sethost
    done
    testfail
else
    ENTRY=${TARGET}
    gethost
    echo "adding route to ${ENTRY}"
    sethost
fi
