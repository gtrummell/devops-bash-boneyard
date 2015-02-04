#!/bin/bash
set -e

# First set defaults
compression_type="gzip"
delete_days="0"
logfiles=""
verbose_mode="false"

# Set up functions
usage () {
	cat <<-EOF
logrotator - a command-line log rotator script.  Usage:

logrotate [options] file [file [file...]]

Arguments:

file 		The name of the logfile or files to rotate.

Options:

-c=type		Compression Type. Compress the backup copies of logs with <type>. Defaults to gzip.
-d=days		Delete old. Delete files older than <days>. Defaults to 3 days.
-v		Verbose mode.
EOF
}

backup-copy () {
	rotated_logfile="${logfile}-manually-rotated-`/bin/date +%Y%m%dT%H%M`"
	if [[ "${verbose_mode}" == "true" ]]; then
		echo "Rotating ${logfile} to ${rotated_logfile}..."
	fi
	cp -af ${logfile} ${rotated_logfile}
}

compress-backup () {
	if [[ "${verbose_mode}" == "true" ]]; then
		echo "Compression type ${compression_type} specified for compression on ${rotated_logfile}..."
	fi
	case ${compression_type} in
	"none" )
		touch "${rotated_logfile}"
		;;
	"gzip" )
		gzip -f "${rotated_logfile}"
		;;
	"7z" )
		7z -d "${rotated_logfile}"
		;;
	* )
		"${compression_type}: unknown compression type"
		;;
	esac
}

clear-current () {
	if [[ "${verbose_mode}" == "true" ]]; then
		echo "Clearing current log file ${logfile}..."
	fi
	cat /dev/null > ${logfile}
}

delete-old () {
	if [[ "${verbose_mode}" == "true" ]]; then
		echo "Deleting ${logfile} backups older than ${delete_days} days..."
	fi
	find ./ -type f -name "${logfile}*" -mtime +"${delete_days}" -exec ls -lah {} \;
}

show-env () {
	echo "Rotating logfiles:"
	for logfile in ${logfiles}; do
		echo "${logfile}"
	done
	cat <<-EOF
Using defaults:
Compression Type:	${compression_type}
Delete <days> old:	${delete_days}
Verbose Mode:		${verbose_mode}
EOF
}

# First check to see if command line arguments are empty.
if [[ -z "$@" ]]; then
	usage
	exit 1
fi

# Iterate through arguments to get options and input files.
for var in "$@"; do
	# Check to see if it's a file
	if [[ -f "${var}" ]]; then
		if [[ "${verbose_mode}" == "true" ]]; then
			echo "Adding file for rotation: ${var}"
		fi
		logfiles="${var} ${logfiles}"
	# If it's not a file, process variables
	else
		# First find out what options we got and the settings that came with them
		opt_key="`echo ${var} | sed 's/^\-//g' | sed 's/\=.*$//g'`"
		opt_val="`echo ${var} | sed 's/^.*\=//g'`"
		# Now set up what's needed for each option
		case "${opt_key}" in
		"c" )
			compression_type="${opt_val}"
			;;
		"d" )
			if [[ "${opt_val}" == "-d" ]]; then
				delete_days="3"
			else
				delete_days="`echo ${var} | sed 's/^.*\=//g'`"
			fi
			;;
		"v" )
			verbose_mode="true"
			;;
		* )
			usage
			exit 1
			;;
		esac
	fi
done

# We can work without options, but not without input files!  Quit if there are none.
if [[ -z "${logfiles}" ]]; then
	echo "No input files!"
	usage
	exit 1
fi 

# Now do the work!
for logfile in "${logfiles}"; do
	logfile="`echo ${logfile} | tr -d ''`"
	if [[ "${verbose_mode}" == "true" ]]; then
		show-env
	fi
	backup-copy
	compress-backup
	clear-current
	if [[ "${delete_days}" > "0" ]]; then
		delete-old
	fi
done
