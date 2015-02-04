#!/bin/bash

# Find files greater than 3% of the filesystem
root_size=`df --output=size -h / | sed '1d'`
root_units=$((${#root_size}-1))
echo "${root_size}"
echo "${root_units}"

#find / -type f -mtime +30 -size +

#sudo find /var/log -type f -name "*.gz"

#find / -type f -name "*screenlog*-*"