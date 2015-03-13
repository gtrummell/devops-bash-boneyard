#!/bin/bash

SERVER=${1}
PK="${HOME}/.ssh/intern.pem"
EDBS_LOCAL="${HOME}/.chef/encrypted_data_bag_secret"
EDBS_REMOTE="/etc/chef/encrypted_data_bag_secret"

scp -i ${PK} ${EDBS_LOCAL} ec2-user@{SERVER}:~/
ssh -i ${PK} ec2-user@${SERVER} "sudo mkdir -pv /etc/chef; sudo chmod 0755 /etc/chef; sudo mv ~/encrypted_data_bag_secret ${EDBS_REMOTE}; sudo chmod 0750 ${EDBS_REMOTE}"
