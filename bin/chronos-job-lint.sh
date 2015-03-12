#!/bin/bash

# Set the dir where we'll be doing the work. Hardcoded for now.
# Other config stuff... TODO: Make this switches or a config file.
#CHRONOS_JOBS_DIR=${1}
CHRONOS_JOBS_DIR="${HOME}/tmp/chronos-sunday"
CHRONOS_ROLE='mesos'
CHRONOS_SYNC_CMD=`which chronos-sync.rb`
ENVIRONMENT='production'

# Lint Key Value Defaults
DEFAULT_CPU='0.1'
DEFAULT_DISK='256'
DEFAULT_MEM='256'
DEFAULT_USER='root'

# Lint for keys: Look for defaults, and look for all keys that must be present
LINT_CRITICAL_KEYS='command disabled name retries owner schedule'
LINT_WARNING_KEYS='epsilon scheduleTimeZone async shell'

# Job run ID
JOB_RUN_ID=`date +%Y%m%dT%H%M%S`

# Verb should be in first position
VERB=${1}

help () {
	cat <<-EOF
	Help goes here
	EOF
}

get_chronos_server () {
	# First get a Chronos node and map it to a URI for our server value
	logger -sp user.info "[chronos-job-lint-run-${JOB_RUN_ID}] INFO - Searching for Chronos server on Role ${CHRONOS_ROLE} in environment ${ENVIRONMENT}..."
	CHRONOS_NODE=`knife search node "role:${CHRONOS_ROLE} AND chef_environment:${ENVIRONMENT}" -F json -a fqdn | jq -r '.rows[][].fqdn' | head -n 1`
	if [[ "${CHRONOS_NODE}" == "" ]]; then
		logger -sp user.crit "[chronos-job-lint-run-${JOB_RUN_ID}] CRITICAL - Validation failed for ${CHRONOS_SERVER} against ${CHRONOS_JOBS_DIR}"
	fi
	CHRONOS_SERVER="http://${CHRONOS_NODE}:4400"
	logger -sp user.info "[chronos-job-lint-run-${JOB_RUN_ID}] INFO - Accessing Chronos job data from ${CHRONOS_SERVER}"
}

get_chronos_job_files () {
	# Get a list of chronos jobs
	CHRONOS_JOBS=`find ${CHRONOS_JOBS_DIR} -type f -name "*yaml" | sort`
}

chronos_validate () {
	logger -sp user.info "[chronos-job-lint-run-${JOB_RUN_ID}] INFO - Validating ${CHRONOS_SERVER} against ${CHRONOS_JOBS_DIR}..."
	${CHRONOS_SYNC_CMD} -u ${CHRONOS_SERVER} -p ${CHRONOS_JOBS_DIR} -V --skip-sync
	if [[ "$?" -ne 0 ]]; then
		logger -sp user.crit "[chronos-job-lint-run-${JOB_RUN_ID}] CRITICAL - Validation failed for ${CHRONOS_SERVER} against ${CHRONOS_JOBS_DIR}"
		exit 1
	else
		logger -sp user.info "[chronos-job-lint-run-${JOB_RUN_ID}] INFO - Validation succeeded for ${CHRONOS_SERVER} against ${CHRONOS_JOBS_DIR}"
	fi
}

chronos_sync_from () {
# Sync with the Chronos server
	logger -sp user.info "[chronos-job-lint-run-${JOB_RUN_ID}] INFO - Synchronozing jobs from ${CHRONOS_SERVER} to ${CHRONOS_JOBS_DIR}..."

	${CHRONOS_SYNC_CMD} -u ${CHRONOS_SERVER} -p ${CHRONOS_JOBS_DIR} -c
	if [[ "$?" -ne 0 ]]; then
		logger -sp user.crit "[chronos-job-lint-run-${JOB_RUN_ID}] CRITICAL - Synchronization failed from ${CHRONOS_SERVER} to ${CHRONOS_JOBS_DIR}"
		exit 1
	else
		logger -sp user.info "[chronos-job-lint-run-${JOB_RUN_ID}] INFO - Synchronozation succeeded from ${CHRONOS_SERVER} to ${CHRONOS_JOBS_DIR}"
	fi
}

chronos_sync_to () {
# Sync with the Chronos server
	logger -sp user.info "[chronos-job-lint-run-${JOB_RUN_ID}] INFO - Synchronizing jobs to ${CHRONOS_SERVER} from ${CHRONOS_JOBS_DIR}..."

	${CHRONOS_SYNC_CMD} -u ${CHRONOS_SERVER} -p ${CHRONOS_JOBS_DIR}
	if [[ "$?" -ne 0 ]]; then
		logger -sp user.crit "[chronos-job-lint-run-${JOB_RUN_ID}] CRITICAL - Synchronization failed to ${CHRONOS_SERVER} from ${CHRONOS_JOBS_DIR}"
		exit 1
	else
		logger -sp user.info "[chronos-job-lint-run-${JOB_RUN_ID}] INFO - Synchronization succeeded to ${CHRONOS_SERVER} from ${CHRONOS_JOBS_DIR}"
	fi
}

lint_cpu () {
# Lint cpu.  Fail if it's not there, warn if it's default, otherwise info.
	CPU_KEY_VALUE=`cat ${CHRONOS_JOB} | yaml get cpus`
	case "${CPU_KEY_VALUE}" in
	"")
		logger -sp user.crit "[chronos-job-lint-run-${JOB_RUN_ID}] CRITICAL - ${CHRONOS_JOB_NAME} CPUs missing or unacceptable value \"${CPU_KEY_VALUE}\""
		FAIL_COUNT=$((FAIL_COUNT + 1))
		;;
	"${DEFAULT_CPU}")
		logger -sp user.warn "[chronos-job-lint-run-${JOB_RUN_ID}] WARNING - ${CHRONOS_JOB_NAME} CPUs settings are set to default \"${DEFAULT_CPU}\""
		WARN_COUNT=$((WARN_COUNT + 1))
		;;
	*)
		logger -sp user.info "[chronos-job-lint-run-${JOB_RUN_ID}] INFO - ${CHRONOS_JOB_NAME} CPUs settings are set to \"${CPU_KEY_VALUE}\""
		;;
	esac
}

lint_mem () {
# Lint memory.  Fail if it's not there, warn if it's default, otherwise info.
	MEM_KEY_VALUE=`cat ${CHRONOS_JOB} | yaml get mem`
	case "${MEM_KEY_VALUE}" in
	"")
		logger -sp user.crit "[chronos-job-lint-run-${JOB_RUN_ID}] CRITICAL - ${CHRONOS_JOB_NAME} Memory missing or unacceptable value \"${MEM_KEY_VALUE}\""
		FAIL_COUNT=$((FAIL_COUNT + 1))
		;;
	"${DEFAULT_MEM}")
		logger -sp user.warn "[chronos-job-lint-run-${JOB_RUN_ID}] WARNING - ${CHRONOS_JOB_NAME} Memory settings are set to default \"${DEFAULT_MEM}\""
		WARN_COUNT=$((WARN_COUNT + 1))
		;;
	*)
		logger -sp user.info "[chronos-job-lint-run-${JOB_RUN_ID}] INFO - ${CHRONOS_JOB_NAME} Memory settings are set to \"${MEM_KEY_VALUE}\""
		;;
	esac
}

lint_disk () {
# Lint disk.  Fail if it's not there, warn if it's default, otherwise info.
	DISK_KEY_VALUE=`cat ${CHRONOS_JOB} | yaml get disk`
	case "${DISK_KEY_VALUE}" in
	"")
		logger -sp user.crit "[chronos-job-lint-run-${JOB_RUN_ID}] CRITICAL - ${CHRONOS_JOB_NAME} Disk missing or unacceptable value \"${DISK_KEY_VALUE}\""
		FAIL_COUNT=$((FAIL_COUNT + 1))
		;;
	"${DEFAULT_DISK}")
		logger -sp user.info "[chronos-job-lint-run-${JOB_RUN_ID}] INFO - ${CHRONOS_JOB_NAME} Disk settings are set to default \"${DEFAULT_DISK}\""
		;;
	*)
		logger -sp user.info "[chronos-job-lint-run-${JOB_RUN_ID}] INFO - ${CHRONOS_JOB_NAME} Disk settings are set to \"${DISK_KEY_VALUE}\""
		;;
	esac
}

lint_user () {
# Lint memory.  Fail if it's not there, warn if it's default, otherwise info.
	USER_KEY_VALUE=`cat ${CHRONOS_JOB} | yaml get runAsUser`
	case "${USER_KEY_VALUE}" in
	"")
		logger -sp user.crit "[chronos-job-lint-run-${JOB_RUN_ID}] CRITICAL - ${CHRONOS_JOB_NAME} Memory missing or unacceptable value \"${USER_KEY_VALUE}\""
		FAIL_COUNT=$((FAIL_COUNT + 1))
		;;
	"${DEFAULT_USER}")
		logger -sp user.warn "[chronos-job-lint-run-${JOB_RUN_ID}] WARNING - ${CHRONOS_JOB_NAME} Memory settings are set to default \"${DEFAULT_USER}\""
		WARN_COUNT=$((WARN_COUNT + 1))
		;;
	*)
		logger -sp user.info "[chronos-job-lint-run-${JOB_RUN_ID}] INFO - ${CHRONOS_JOB_NAME} Memory settings are set to \"${USER_KEY_VALUE}\""
		;;
	esac
}

lint_critical () {
# Lint for the existence of desired keys and raise a warning if they don't exist.
	for CRITICAL_KEY in ${LINT_CRITICAL_KEYS}; do
		CRITICAL_KEY_VALUE=`cat ${CHRONOS_JOB} | yaml get ${CRITICAL_KEY}`
		if [[ "${CRITICAL_KEY_VALUE}" == "" ]]; then
			logger -sp user.crit "[chronos-job-lint-run-${JOB_RUN_ID}] CRITICAL - ${CHRONOS_JOB_NAME} required key ${CRITICAL_KEY} returned missing or unacceptable value \"${CRITICAL_KEY_VALUE}\""
			FAIL_COUNT=$((FAIL_COUNT + 1))
		else
			logger -sp user.info "[chronos-job-lint-run-${JOB_RUN_ID}] INFO - ${CHRONOS_JOB_NAME} required key ${CRITICAL_KEY} is present with value \"${CRITICAL_KEY_VALUE}\""
		fi
	done
}

lint_warning () {
# Lint for the existence of critical keys
	for WARNING_KEY in ${LINT_WARNING_KEYS}; do
		WARNING_KEY_VALUE=`cat ${CHRONOS_JOB} | yaml get ${WARNING_KEY}`
		if [[ "${WARNING_KEY_VALUE}" == "" ]]; then
			logger -sp user.warn "[chronos-job-lint-run-${JOB_RUN_ID}] WARNING - ${CHRONOS_JOB_NAME} recommended key ${WARNING_KEY} returned missing or unacceptable value \"${WARNING_KEY_VALUE}\""
			WARN_COUNT=$((WARN_COUNT + 1))
		else
			logger -sp user.info "[chronos-job-lint-run-${JOB_RUN_ID}] INFO - ${CHRONOS_JOB_NAME} recommended key ${WARNING_KEY} is present with value \"${WARNING_KEY_VALUE}\""
		fi
	done
}

lint_job () {
# Run all lint tests on this job
	lint_cpu
	lint_mem
	lint_disk
	lint_user
	lint_critical
	lint_warning
}


lint_all_jobs () {
# Run all lint tests on all jobs
	get_chronos_job_files
	logger -sp user.info "[chronos-job-lint-run-${JOB_RUN_ID}] INFO - Reconciling ${CHRONOS_SERVER} against ${CHRONOS_JOBS_DIR}"
	for CHRONOS_JOB in ${CHRONOS_JOBS}; do
		CHRONOS_JOB_NAME=`echo ${CHRONOS_JOB} | sed 's/^.*\///g' | sed 's/\.yaml//g'`
		lint_job
	done	
	logger -sp user.info "[chronos-job-lint-run-${JOB_RUN_ID}] INFO - Reconciled ${CHRONOS_SERVER} against ${CHRONOS_JOBS_DIR}"
}

setup_for_verbs () {
# Setup to be done prior to running any verb.  Get the server we want to talk to and validate the jobs we have on disk.
# Quit if validation fails - this means user intervention is needed.
	get_chronos_server
	chronos_validate
}

verb_lint_all_after_sync () {
# This verb does what it says - lint all jobs after syncing with the server.
	logger -sp user.info "[chronos-job-lint-run-${JOB_RUN_ID}] INFO - ${0} starting ${VERB} run at `date +%Y-%m-%d\ %H:%M:%S` against ${CHRONOS_JOBS_DIR}" 
	# Set the warn and fail counts to zero.
	WARN_COUNT=0
	FAIL_COUNT=0

	# Set up shop
	setup_for_verbs

	# Here's what this job does:
	chronos_sync_from
	lint_all_jobs

	if [[ "${FAIL_COUNT}" -ne "0" ]]; then
		logger -sp user.crit "[chronos-job-lint-run-${JOB_RUN_ID}] CRITICAL - ${0} FAILED ${VERB} run at `date +%Y-%m-%d\ %H:%M:%S` against ${CHRONOS_JOBS_DIR}. Warnings: ${WARN_COUNT} Failures: ${FAIL_COUNT}" 
		exit 1
	elif [[ "${WARN_COUNT}" -ne "0" ]]; then
		logger -sp user.warn "[chronos-job-lint-run-${JOB_RUN_ID}] CRITICAL - ${0} WARNING completed ${VERB} run with warnings at `date +%Y-%m-%d\ %H:%M:%S` against ${CHRONOS_JOBS_DIR}. Warnings: ${WARN_COUNT} Failures: ${FAIL_COUNT}" 
		exit 0
	else
		logger -sp user.warn "[chronos-job-lint-run-${JOB_RUN_ID}] CRITICAL - ${0} completed ${VERB} run at `date +%Y-%m-%d\ %H:%M:%S` against ${CHRONOS_JOBS_DIR}. Warnings: ${WARN_COUNT} Failures: ${FAIL_COUNT}" 
		exit 0		
	fi
}

# Check for empty args or a request for help
case "${VERB}" in
"lint-all")
	verb_lint_all_after_sync
	sudo grep ${JOB_RUN_ID} /var/log/syslog > ${HOME}/Downloads/chronos-lint.log
	;;
*)
	help
	exit 1
	;;
esac
