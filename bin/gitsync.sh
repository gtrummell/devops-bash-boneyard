#!/bin/bash

# First figure out if we're in the source directory, or if the user has a specific dir in mind.
if [[ -z "${1}" ]]; then
	SRC_ROOT=`pwd`
else
	SRC_ROOT="${1}"
fi

echo "Checking for git sources in ${SRC_ROOT}"

# Now look for git repos and make a list of them
REPOS=$(for REPO in `find ${SRC_ROOT} -name ".git"`; do echo ${REPO}|sed 's/\/\.git//g'; done)

# Go to each repo, get a list of branches, and pull each one
for REPO in ${REPOS}; do
	echo "Using repo ${REPO}"

	cd ${REPO}
	CUR_BRANCH=$(git status|grep "On branch"|sed 's/On\ branch\ //g')
	LOC_BRANCHES=$(git branch|sed 's/[\* ]//g')

	echo "Current branch is ${CUR_BRANCH}"
	for LOC_BR in ${LOC_BRANCHES}; do
		echo "Refreshing local branch ${LOC_BR}"
		git checkout ${LOC_BR}
		git pull
		echo "GOT RETURN CODE $?"
	done

	echo "Checking out branch we found checked out for this repo: ${CUR_BRANCH}"
	git checkout ${CUR_BRANCH}
done
