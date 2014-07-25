#!/bin/bash

for i in c0m1 idx1 idx2 idx3; do
	curl -k -u <SPLUNK-USER>:<SPLUNK-PASSWORD> https://$i.stackwatchr.splunkcloud.com:8089/services/authorization/roles -d name=<INDEX_MANAGER_USER> -d capabilities=indexes_edit
	curl -k -u <SPLUNK-USER>:<SPLUNK-PASSWORD> https://$i.stackwatchr.splunkcloud.com:8089/services/authentication/users -d name=<INDEX_MANAGEMENT_ROLE> -d password=<PASSWORD> -d roles=<INDEX_MANAGEMENT_ROLE>
	ssh $i.stackwatchr.splunkcloud.com 'sudo su - splunk -c "/opt/splunk/bin/splunk list user -auth <SPLUNK-USER>:<SPLUNK-PASSWORD>"'
done
