#!/bin/bash

# Set up variables
let root_size=`sudo df -l --output=size / | sed '1d' | tr -d ' '`
let file_size=${root_size}*100/30/100
let file_age=7
hostname="`sudo hostname -f`"
mail_from="disk-cleanup@#{hostname}"
mail_to="graham@bandpage.com"
log_strings='*.gz *201*'
log_activity=""

# Report on some large files in the overall filesystem, but take not action
find_big_old_files () {
	big_old_files=`sudo find / -xdev -type f -mtime +${file_age} -size +${file_size}k`
}

# Clear Screen Logs
clear_screenlogs () {
	echo "Clearing Screenlogs:"
	
	# Find the live ones; rotate and then clear.
	for screen_log in `sudo find / -type f -name "screenlog.0"`; do
		cp ${screen_log} ${screen_log}-`date +%Y%m%d`
		cat /dev/null > screen_log
		echo "Backed up ${screen_log} to ${screen_log}-`date +%Y%m%d`" >> ${log_activity}
	done

	# Now delete all the old ones.
	for old_screen_log in `sudo find / -type f -name "screenlog.0-* -mtime +{file_age}`; do
		sudo rm -f ${old_screen_log}
		echo "${log_activity}+${old_screen_log}"
	done
}

# Delete old log files
del_old_logs () {
	echo "Deleting log files older than ${file_age} and greater than ${file_size} kilobytes:"
	for log_string in ${log_strings}; do
		sudo find /var/log -type f -mtime +${file_age} -name ${log_string} -exec sudo rm -fv {} \;
		echo "Deleted ${log_string}" >> ${log_activity}
	done
}

disk_message () {
cat <<-EOF
from:    ${mail_from}
to:      ${mail_to}
subject: Files older than ${file_age} days and larger than ${file_size} kilobytes on ${hostname}"

Total disk size: ${root_size}

Here's what we did:
${log_activity}

EOF
}

find_big_old_files
del_old_logs
clear_screenlogs
disk_message

# echo ${disk_message} | sudo mail -s 'Big old files from ${hostname}' -r roombadisk@${hostname} graham@bandpage.com
