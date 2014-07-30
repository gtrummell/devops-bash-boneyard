#!/bin/bash

subcmd=${1}
pickserv=${2}

chefdir=${HOME}/.chef
knifeconf=${chefdir}/knife.rb
chefconf=${chefdir}/client.rb
secretfile=${chefdir}/data_bag.secret
chefservs=`ls -1 ${chefdir}|grep knife-|sed 's/knife-//g'|sed 's/\.rb//g'`

function list () {
	# List the chef servers found in the $chefdir
	for i in ${chefservs}
	do
		echo ${i}
	done
	exit 0
}

function which () {
	# Tell us which chef server we are using now.
	if [ -f ${knifeconf} ]
	then
		echo "`ls -lah ${knifeconf}|sed 's/.*-//g'|sed 's/\.rb//g'`"
	else
		echo "knifeblock: Knife configuration file not found!"
	fi
	exit 0
}

function use () {
	# Quit if we can't find a knife config file matching the alias.
	#echo -n "Requested chef server is ${pickserv}... "
	if [ `ls -1 ${chefdir}/knife-${pickserv}.rb|wc -l` -ne 1 ]
	then
		echo "knifeblock: No chef server found matching the alias ${pickserv}"
		exit 1
	fi

	# Remove existing symlinks for knife.rb and client.rb
	if [ -L ${knifeconf} ]
	then
		#echo -n "Deleting existing symlink at ${knifeconf}... "
		rm -f ${knifeconf}
		rm -f ${chefconf}
	fi

	# Now link from the picked server to knife.rb
	ln -s knife-${pickserv}.rb ${knifeconf}
	ln -s knife-${pickserv}.rb ${chefconf}
	echo "knifeblock: selected ${pickserv}"

	# Quit if we can't find a secret file matching the alias.
	#echo -n "Requested chef server is ${pickserv}... "
	if [ `ls -1 ${chefdir}/data_bag-${pickserv}.secret|wc -l` -ne 1 ]
	then
		#echo "No secret file found matching the alias ${pickserv}"
		exit 1
	fi
	# Remove existing symlinks for the secret file
	if [ -L ${secretfile} ]
	then
		#echo -n "Deleting existing symlink at ${secretfile}... "
		rm -f ${secretfile}
	fi
	# Now link from the picked server to data_bag.secret
	ln -s data_bag-${pickserv}.secret ${secretfile}
	#echo "Now using secret file data_bag-${pickserv}.secret"
}

case ${subcmd} in
which)
    which
    ;;
list)
    list
	;;
use)
    use
    ;;
*)
	echo "Helps you manage your knife.rb and data bag secret files."
	echo "knifeblock.sh [ list | use [serveralias] | which ]"
	;;
esac
