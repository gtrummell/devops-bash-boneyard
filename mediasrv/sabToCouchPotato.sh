#!/bin/bash
#
# sabToCouchPotato.sh
#
# A stoopid shell script to trigger CouchPotato's renamer and library updater.
# sabNZBdplus will trigger a renamer scan as soon as a file finishes downloading.  We keep an eye on the sabNZBdplus
# completed directory make sure to only fire off library updates when the renamer is finished.
# This script assumes firing off multiple rename operations won't adversely affect a rename-in-progress... but we're
# still testing that. :)

# Config stuffs
PATH=${PATH}:
CP_URL="http://gmedia:5050/api/9b78d1a6a74d40c592703d0189a935eb"
# Movie path, duh. Can be multiple movie paths.  Just escape spaces in titles, and leave spaces between paths.
DOWNLOAD_PATHS="/var/sabnzbdplus/complete/movies"

collision_check ()
{ # Sleep if another instance is running.
    if [ `ps -ef | grep $0 | grep -v grep | wc -l` -gt 2 ]; then
        logger -p  "CouchPotato: INFO: Another instance of the renamer is running.  Exiting this instance"
        exit 0
    fi
}

run_renamer()
{ # Run the file renamer, log errors and successes.
    RENAMER_RETURN=`curl -s ${CP_URL}/renamer.scan | awk -F\" '{print $2}'`
    if [ ${RENAMER_RETURN} != "success" ]; then
        logger -p user.info "CouchPotato: ERR:  Renamer failed to run!"
        exit 1
    else
        logger -p user.info "CouchPotato: INFO: Renamer was triggered successfully"
    fi
}

run_manager()
{ # Run manage/update function in couch potato.  Only run if there are no other updates in progres.
    MGR_RETURN=`curl -s "${CP_URL}/manage.update" | grep success | wc -l`
    if [ ${MGR_RETURN} -lt 1 ]; then
        logger -p user.err "CouchPotato: ERR:  Manager/update failed to run!"
        exit 1
    else
        logger -p user.info "CouchPotato: INFO: Manager/update was triggered successfully"
    fi
}

get_mgr_status()
{ # Figure out if manager is running or not.  0 is running, 1 is stopped.
    STAT_RETURN=`curl -s "${CP_URL}/manage.progress" | grep false | wc -l`
}

# OK, now we can get to work!  SabNZBdplus will call us after a movie finishes, so we'll start the renamer.
# Check for other processes
collision_check

# We were triggered, so run the renamer.
logger -p user.info "CouchPotato: INFO: Triggering renamer"
run_renamer

# Now that there are no more movies, it's time to run manage/update.  First check to see if other manage/update processes
# are running.  If they arey, wait INTERVAL seconds before retrying up to RETRIES times.  When there are no manage/update
# processes running, trigger one.
RETRIES=5
INTERVAL=300
get_mgr_status
while [ ${STAT_RETURN} -ne 1 ] && [ ${RETRIES} -ne 0 ]; do
    logger -p user.info "CouchPotato: INFO: Manager/update is running, sleeping for ${INTERVAL} seconds, retrying ${RETRIES} more times"
    sleep ${INTERVAL}
    get_mgr_status
    RETRIES=$[${RETRIES}-1]
done

if [ ${RETRIES} -ne 0 ]; then
    logger -p user.info "CouchPotato: INFO: Triggering Manager/update"
    run_manager
else
    logger -p user.err "CouchPotato: ERROR: Exceeded manager/update retries!"
    exit 1
fi
