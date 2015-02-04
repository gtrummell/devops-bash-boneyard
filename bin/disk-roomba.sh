#!/bin/bash

# Set up variables
root_size=`df -h / | tail -1 | awk '{print $2}' | sed 's/[a-zA-Z]//'`
let file_size=${root_size}*100/30/100
    file_size=${file_size}
let file_age=3
    file_age=${file_age}
hostname="`sudo hostname -f`"
mail_from="disk-cleanup@#{hostname}"
mail_to="graham@bandpage.com"
log_strings='*.gz *201*'
log_activity=""

# Report on some large files in the overall filesystem, but take not action
find_big_old_files () {
        echo "Found some big 'ol files:"
        sudo find / -xdev -type f -mtime +${file_age} -size +${file_size}
}

# Clear Screen Logs
clear_screenlogs () {
        # Now delete all the old ones.
        echo "Clearing archived screenlogs:"
        sudo find / -type f -name "screenlog.0-*" -mtime +${file_age} -exec sudo rm -f {} \;

        echo "Rotating live screenlogs:"
        # Find the live ones; rotate and then clear.
        for screen_log in `sudo find / -type f -name "screenlog.0"`; do
                cp ${screen_log} ${screen_log}-`date +%Y%m%d`
                cat /dev/null > screen_log
                echo "Rotated ${screen_log} to ${screen_log}-`date +%Y%m%d`"
        done
}

# Delete old log files
del_old_logs () {
        echo "Deleting log files older than ${file_age} days and greater than ${file_size} kilobytes:"
        for log_string in ${log_strings}; do
                sudo find /var/log -type f -mtime +${file_age} -name ${log_string} -exec sudo rm -fv {} \;
        done
}

find_big_old_files
del_old_logs
clear_screenlogs
