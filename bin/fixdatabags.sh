#!/bin/bash

for i in chef vpcprod; do
    knifeblock use $i
    knife _10.16.2_ data bag from file auth /Users/gtrummell/Source/whisper/chef/data_bags/prod/auth/aws-splunk-whisper-prod.json
    knife data bag show auth aws-splunk-whisper-prod --secret-file ~/.chef/data_bag.secret -F json
done