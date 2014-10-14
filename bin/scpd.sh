#!/bin/bash

SRC=$1
DEST=$2

scp -i $HOME/.ssh/root.intern.bandpage.com.id_rsa.priv root@${SRC} ${DEST}
