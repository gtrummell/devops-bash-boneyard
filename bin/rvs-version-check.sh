#!/bin/bash

repo_base="/mnt/data/repo"

bp_packages=$(find ${repo_base} -type f -name "*.rpm" | sed 's/^.*\///g' | sed 's/-[0-9].*$//g' | sort | uniq)

for pkg in ${bp_packages}; do
    # Find all the RPM packages named ${pkg}. Sort numerically and get the latest build.
    full_pkg=`find ${repo_base} -type f -name "${pkg}-[0-9]*.rpm" | sed 's/^.*\///g' | tail -n 1`

    # Get the package name and version
    pkg_name=`echo ${full_pkg} | sed 's/-[0-9].*//g'`
    pkg_ver=`echo ${full_pkg} | sed 's/[a-zA-Z_-]*//g' | awk -F\. '{print $1"."$2"."$3}'`
    pkg_major=`echo ${pkg_ver} | awk -F\. '{print $1}'`
    pkg_minor=`echo ${pkg_ver} | awk -F\. '{print $2}'`

    # Get RVS full, major, and minor version numbers.
    rvs_ver=`rvs get ${pkg_name} full`
    rvs_major=`rvs get ${pkg_name} major`
    rvs_minor=`rvs get ${pkg_name} minor`

    # Compare versions and increment as needed
    # If the major version in RVS is less than the major version on disk, increment until RVS is equal or greater than disk.
    echo "${pkg_name} on disk is at version ${pkg_ver} and in RVS at version ${rvs_ver}"
    if [[ ${rvs_major} -lt ${pkg_major} ]]; then
        echo "Inrementing RVS major version ${rvs_major} to match or exceed ${pkg_name} major version ${pkg_major}"
        rvs set ${pkg_name} major ${pkg_major}
    fi

    # If the major version is the same, then increment the minor version
    if [[ ${rvs_minor} -lt ${pkg_minor} ]]; then
        echo "Inrementing RVS minor version ${rvs_minor} to exceed ${pkg_name} minor version ${pkg_minor}"
        rvs set ${pkg_name} minor $(expr ${pkg_minor} + 1)
    fi
done
