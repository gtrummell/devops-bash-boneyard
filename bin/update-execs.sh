#!/bin/bash

execs=`cat ../etc/sandbox-execs.conf`

for i in ${execs}; do
    echo "SSH to ${i}"
    ssh -o StrictHostKeyChecking=no ${i} "sudo gem install git"
done
