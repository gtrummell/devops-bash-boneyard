#!/bin/bash

SERVER=$1

ssh -i $HOME/.ssh/root.intern.bandpage.com.id_rsa.priv root@${SERVER}
