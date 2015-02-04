#!/bin/bash

SERVER=$1

ssh -i $HOME/.ssh/intern.pem root@$SERVER
