#!/bin/bash

SERVER=$1

ssh -i $HOME/.ssh/intern.pem ec2-user@${SERVER}
