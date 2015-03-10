#!/bin/bash

# Hardcode input positions for simplicity
VERB=${1}
FQDN=${2}
IP_ADDRESS=${3}

# Config Stuff
UNBOUND_CONFIGS='/etc/unbound/local.d'

help_text () {
    cat <<-EOF
    update-unbound verb [zone|server ipaddress]
EOF
}

parse_verb () {
    case "${VERB}" in
    "add")
        get_domain
        get_zone_head
        get_zone_data
        backup_zone
        add_record
        get_domain
        get_zone_head
        get_zone_data
        show_zone
        ;;
    "rm")
        get_domain
        get_zone_head
        get_zone_data
        backup_zone
        rm_record
        get_domain
        get_zone_head
        get_zone_data
        show_zone
        ;;
    "show")
        get_domain
        get_zone_head
        get_zone_data
        show_zone
        ;;
    "update")
        get_domain
        get_zone_head
        get_zone_data
        backup_zone
        update_from_chef
        get_domain
        get_zone_head
        get_zone_data
        show_zone
        ;;
    "backup")
        backup_zone
        ;;
    *)
        help_text
        ;;
    esac
}

get_domain () {
# We're just making assumptions that zone files will be there.
	DOMAIN=`echo "${FQDN}" | awk -F\. '{print $(NF-1)"."$NF}'`
	ZONE_FILE="${UNBOUND_CONFIGS}/${DOMAIN}.conf"
	echo "Domain is ${DOMAIN}"
	echo "Zone file is ${ZONE_FILE}"
}

get_zone_head () {
	ZONE_HEAD=`cat ${ZONE_FILE} | grep -v local-data`
	echo -e "Head of zone ${DOMAIN} from ${ZONE_FILE}:\n${ZONE_HEAD}\n"
}

get_zone_data () {
	ZONE_DATA=`cat ${ZONE_FILE} | grep local-data | sort`
	echo -e "Data from zone ${DOMAIN} from ${ZONE_FILE}:\n${ZONE_DATA}\n"
}

show_zone () {
    echo -e "Showing Zone file ${ZONE_FILE}:\n"
    echo -e "${ZONE_HEAD}\n${ZONE_DATA}\n"
}

backup_zone () {
    ZONE_BACKUP=${ZONE_FILE}.`date +%Y%m%dT%H%M%S`
    cp ${ZONE_FILE} ${ZONE_BACKUP}
    if [[ $? -ne 0 ]]; then
        echo "Backup of ${ZONE_FILE} failed!"
    else
        ls -lah ${ZONE_BACKUP}
        echo "Backup of ${ZONE_FILE} succeeded"
    fi
}

add_record () {
	echo -e "Adding ${FQDN} with address ${IP_ADDRESS} to ${ZONE_FILE}"
    ZONE_UPDATE=`echo -e "${ZONE_DATA}\n\tlocal-data: \"${FQDN}. 3600 IN A ${IP_ADDRESS}\"" | sort`
    echo -e "${ZONE_HEAD}\n${ZONE_UPDATE}" > ${ZONE_FILE}
}

rm_record () {
	echo -e "Removing ${FQDN} from zone ${DOMAIN} in file ${ZONE_FILE}"
	sed -i "/${FQDN}/d" ${ZONE_FILE}
}

update_from_chef () {
	knife search node "fqdn:*.${DOMAIN}" -F json -a fqdn -a ipaddress | jq '.'
}

try_restart_unbound () {
	sudo service unbound restart
}

parse_verb
