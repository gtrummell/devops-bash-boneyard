#!/bin/bash

# Deploy a file to a set of servers defined by Chef search syntax.
role=${1}
env=${2}
up_down=${3}
local_file=${4}
remote_file=${5}
perms=${6}
owner=${7}

# Other config stuff
ssh_user="root"
ssh_identity="${HOME}/.ssh/intern.pem"

# Give help to the user
help_text () {
	cat <<-EOF
knife-scp - a dirty hack to deploy files with chef search.

Syntax:
$0 <role> <environment> <up|down> <path_to_local_file> <path_to_remote_file> <permissions> <owner>

You gave us:
role=${1}
env=${2}
up_down=${3}
local_file=${4}
remote_file=${5}
perms=${6}
owner=${7}
EOF
}

# Find the servers requested bys the Chef search string.
find_servers () {
	servers=$(knife search node "role:${role} AND chef_environment:${env}" -a fqdn -F json | jq -r '.rows[][].fqdn' | sort)
}

# SCP the file to each of server.
file_upload () {
	for server in ${servers}; do
		scp -i ${ssh_identity} ${local_file} ${ssh_user}@${server}:${remote_file}
	done
}

# SCP the file from each server.
file_download () {
	for server in ${servers}; do
		scp -i ${ssh_identity} ${ssh_user}@{remote_file} ${local_file}
}

# SSH to each of them and change owner and permissions appropriately.
file_perms () {
	knife ssh --manual-list ${servers} "sudo chmod ${perms} ${remote_file}; sudo chown ${owner} ${remote_file}"
}

# Now do the work!
find_servers
case ${up_down} in
	"u")
		file_upload
		file_perms
		;;
	"d")
		file_download
esac
