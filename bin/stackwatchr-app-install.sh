#!/bin/bash

# Format: $0 [path-to-app]
#
# 1. Upload the app
# 2. Place it in the correct directory
# 3. Unpackage it
# 4. Correct the permissions/ownership
# 5. Restart or apply-cluster-bundle

# Set up variables

APP=$1

# First we'll do the cluster master

scp $APP c0m1.stackwatchr.splunkcloud.com:~/

ssh c0m1.stackwatchr.splunkcloud.com "sudo tar xvzf $APP -C /opt/splunk/etc/master-apps/; sudo chown -R splunk.splunk /opt/splunk/etc/master-apps/"

# First we'll do the cluster master

scp $APP sh1.stackwatchr.splunkcloud.com:~/

ssh sh1.stackwatchr.splunkcloud.com "sudo tar xvzf $APP -C /opt/splunk/etc/apps/; sudo chown -R splunk.splunk /opt/splunk/etc/apps/"
