#!/bin/bash

# Stub for testing

ENVIRONMENT=${1}

# SET MEMCACHED CONFIG
case $ENVIRONMENT in
"production" )
    MEMCACHE_IPS=$(for i in prodapi-1c.xxnqmj.0001.use1.cache.amazonaws.com prodapi-1d.xxnqmj.0001.use1.cache.amazonaws.com; do nslookup $i | tail -n 2 | grep Address | cut -f 2 -d ' '; done)
    ;;
"staging" )
    MEMCACHE_IPS=$(for i in stageapi.xxnqmj.0001.use1.cache.amazonaws.com; do nslookup $i | tail -n 2 | grep Address | cut -f 2 -d ' '; done)
	;;
"development" )
    MEMCACHE_IPS=$(for i in devapi.xxnqmj.0001.use1.cache.amazonaws.com; do nslookup $i | tail -n 2 | grep Address | cut -f 2 -d ' '; done)
	;;
* )
	echo "Invalid enviroment supplied: ${ENVIRONMENT}"
	exit 1
esac

echo ${MEMCACHE_IPS}