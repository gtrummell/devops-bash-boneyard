#!/bin/bash

SCRIPT_ARGS=${@}

setup_tools () {
    # Make sure all the OS tools we'll need are installed
    TOOLS='aws java jq sort uniq tail sed awk'
    for TOOL in ${TOOLS}; do
        TOOL_CHECK=`which ${TOOL}`
        if [[ "${TOOL_CHECK}" == '' ]]; then
            echo "Unable to run. ${TOOL} not present in path"
            exit 1
        fi
    done

    # Make sure we've got the YAML tool installed
    gem update yaml_command
}

setup_chef_env () {
    # Environment-based config stuff.
    ENVS='development production staging'
    for ENV in ${ENVS}; do
        ENV_DETECT=`echo ${SCRIPT_ARGS} | grep -i ${ENV} | wc -l`
        if [[ "${ENV_DETECT}" == "1" ]]; then
            ENVIRONMENT=${ENV}
            break
        fi
    done

    case "${ENVIRONMENT}" in
    'staging')
        DOMAIN='bandpage-s.com'
        DATACENTER_ID='1'
        SSH_KEY="${HOME}/.ssh/intern.pem"
        ;;
    'production')
        DOMAIN='bandpage.com'
        DATACENTER_ID='0'
        SSH_KEY="${HOME}/.ssh/intern.pem"
        ;;
    *)
        ENVIRONMENT='development'
        DOMAIN='bandpage-d.com'
        DATACENTER_ID='2'
        SSH_KEY="${HOME}/.ssh/intern.pem"
        ;;
    esac
}

setup_server_role () {
    # Role-based config stuff. NOTE: ORDER MATTERS! If you put es before mesos
    # you get "es" even if you ask for "mesos".
    SERVER_ROLES='api base cdn_redirector chef_server dba mesos ganglia graphite haproxy int_www jenkins_master loadtest node-admin php-admin php_www services socket solr vpn zookeeper es'
    for ROLE in ${SERVER_ROLES}; do
        ROLE_DETECT=`echo ${SCRIPT_ARGS} | grep -i ${ROLE} | wc -l`
        if [[ "${ROLE_DETECT}" == "1" ]]; then
            SERVER_ROLE=${ROLE}
            break
        fi
    done
}

setup_server_name () {
    # Get next available name for this instance
    LATEST_ORDINAL=`knife search node "role:${SERVER_ROLE} AND chef_environment:${ENVIRONMENT}" -F json -a name | jq -r '.rows[][][]' | sed 's/\..*//g' | sed 's/[a-z]//g' | sort -n | tail -n 1`

    if [[ "${LATEST_ORDINAL}" < [1-9] ]]; then
        RAW_ORDINAL=$((LATEST_ORDINAL + 1))
        SERVER_ORDINAL="0${RAW_ORDINAL}"
    else
        SERVER_ORDINAL=$((LATEST_ORDINAL + 1))
    fi
    SERVER_NAME="${SERVER_ROLE}${SERVER_ORDINAL}.${DOMAIN}"
}

setup_chef_role () {
    # Configure each role
    case ${SERVER_ROLE} in
    'api')
        EBS_SIZE='24'
        FLAVOR='c3.large'
        ROLE_SWITCHES=''
        ROL_TAGS="Datacenter_Id=${DATACENTER_ID},Worker_Id=${SERVER_ORDINAL}"
        RUN_LIST='role[api]'
        SG_LIST='intern-api'
        ;;
    'base')
        EBS_SIZE='24'
        FLAVOR='c3.large'
        ROLE_SWITCHES=''
        ROLE_TAGS=''
        RUN_LIST='role[base]'
        SG_LIST='intern'
        ;;
    'cdn_redirector')
        EBS_SIZE='24'
        FLAVOR='t1.micro'
        ROLE_SWITCHES=''
        ROLE_TAGS=''
        RUN_LIST='role[cdn_redirector]'
        SG_LIST='intern'
        ;;
    'chef_server')
        EBS_SIZE='24'
        FLAVOR='m1.small'
        ROLE_SWITCHES=''
        ROLE_TAGS=''
        RUN_LIST='role[chef_server]'
        SG_LIST='intern-chef'
        ;;
    'dba')
        EBS_SIZE='24'
        FLAVOR='t1.micro'
        ROLE_SWITCHES=''
        ROLE_TAGS=''
        RUN_LIST='role[dba]'
        SG_LIST='intern'
        ;;
    'es')
        EBS_SIZE='24'
        FLAVOR='m3.large'
        ROLE_SWITCHES=''
        ROLE_TAGS=''
        RUN_LIST='role[es]'
        SG_LIST='intern-services'
        ;;
    'ganglia')
        EBS_SIZE='24'
        FLAVOR='m3.medium'
        ROLE_SWITCHES=''
        ROL_TAGS="Datacenter_Id=${DATACENTER_ID},Worker_Id=${SERVER_ORDINAL}"
        RUN_LIST='role[ganglia]'
        SG_LIST='Monitor'
        ;;
    'graphite')
        EBS_SIZE='24'
        FLAVOR='m3.xlarge'
        ROLE_SWITCHES=''
        ROLE_TAGS=''
        RUN_LIST='role[graphite]'
        SG_LIST='intern-services'
        ;;
    'haproxy')
        EBS_SIZE='24'
        FLAVOR='c3.large'
        ROLE_SWITCHES=''
        ROLE_TAGS=''
        RUN_LIST='role[haproxy]'
        SG_LIST='production-dmz'
        ;;
    'int_www')
        EBS_SIZE='24'
        FLAVOR='m1.small'
        ROLE_SWITCHES=''
        ROLE_TAGS=''
        RUN_LIST='role[int_www]'
        SG_LIST='intern-www'
        ;;
    'jenkins_master')
        EBS_SIZE='24'
        FLAVOR='m1.large'
        ROLE_SWITCHES=''
        ROLE_TAGS=''
        RUN_LIST='role[jenkins_master]'
        SG_LIST='intern-jenkins'
        ;;
    'loadtest')
        EBS_SIZE='24'
        FLAVOR='t1.micro'
        ROLE_SWITCHES=''
        ROLE_TAGS=''
        RUN_LIST='role[loadtest]'
        SG_LIST='intern'
        ;;
    'mesos')
        EBS_SIZE='128'
        FLAVOR='r3.large'
        ROLE_SWITCHES=''
        ROLE_TAGS=''
        RUN_LIST='role[mesos]'
        SG_LIST='intern-services'
        ;;
    'node-admin')
        EBS_SIZE='24'
        FLAVOR='m1.medium'
        ROLE_SWITCHES=''
        ROLE_TAGS=''
        RUN_LIST='role[node-admin]'
        SG_LIST='production-admin'
        ;;
    'php-admin')
        EBS_SIZE='24'
        FLAVOR='m3.medium'
        ROLE_SWITCHES=''
        ROL_TAGS="Datacenter_Id=${DATACENTER_ID},Worker_Id=${SERVER_ORDINAL}"
        RUN_LIST='role[php-admin]'
        SG_LIST='production-api'
        ;;
    'php_www')
        EBS_SIZE='24'
        FLAVOR='c3.large'
        ROLE_SWITCHES=''
        ROLE_TAGS=''
        RUN_LIST='role[php_www]'
        SG_LIST='search,production-www'
        ;;
    'services')
        EBS_SIZE='64'
        FLAVOR='c3.xlarge'
        ROLE_SWITCHES=''
        ROLE_TAGS=''
        RUN_LIST='role[services]'
        SG_LIST='search' # Could also be intern-services?
        ;;
    'socket')
        EBS_SIZE='24'
        FLAVOR='c3.xlarge'
        ROLE_SWITCHES=''
        ROLE_TAGS=''
        RUN_LIST='role[socket]'
        SG_LIST='search'
        ;;
    'solr')
        EBS_SIZE='24'
        FLAVOR='c3.large'
        ROLE_SWITCHES=''
        ROLE_TAGS=''
        RUN_LIST='role[solr]'
        SG_LIST='event-api'
        ;;
    'vpn')
        EBS_SIZE='24'
        FLAVOR='c3.large'
        ROLE_SWITCHES=''
        ROLE_TAGS=''
        RUN_LIST='role[vpn]'
        SG_LIST='external'
        ;;
    'zookeeper')
        EBS_SIZE='24'
        FLAVOR='m1.small'
        ROLE_SWITCHES=''
        ROLE_TAGS=''
        RUN_LIST='role[zookeeper]'
        SG_LIST='intern-services'
        ;;
    *)
        echo "No role specified on the command line!"
        exit 1
        ;;
    esac
}

setup_ami () {
    # Set default AMI to Amazon Linux 2014.09
    AMI_COUNT=`echo ${SCRIPT_ARGS} | grep ami- | wc -l`
    if [[ "${AMI_COUNT}" -ne "1" ]]; then
        SERVER_AMI='ami-146e2a7c'
    else
        SERVER_AMI=`echo ${SCRIPT_ARGS} | sed 's/.* ami-/ami-/g' | sed 's/ .*//g'`
    fi
}

get_az () {
    # Get availability zones for the configured region.
    AVAILABILITY_ZONES=`aws ec2 describe-availability-zones | jq -r '.[][].ZoneName'`

    # Get all the AZ's in use by our instances of this role in this environment.
    IN_USE_AZS=`knife search node "role:${SERVER_ROLE} AND chef_environment:${ENVIRONMENT}" -F json -a ec2.placement_availability_zone | jq -r '.[][][][]' | sort | uniq`

    # We will launch into the first available AZ for this role in this environment.
    for AVAILABILITY_ZONE in ${AVAILABILITY_ZONES}; do
        THIS_AZ_COUNT=0
        for IN_USE_AZ in ${IN_USE_AZS}; do
            if [[ "${AVAILABILITY_ZONE}" == "${IN_USE_AZ}" ]]; then
            THIS_AZ_COUNT=$((THIS_AZ_COUNT + 1))
            fi
        done

        # Pick an AZ that doesn't have an instance.
        if [[ ${THIS_AZ_COUNT} < 1 ]]; then
            SERVER_AZ="${AVAILABILITY_ZONE}"
        else
            continue
        fi
    done
}

launch_server () {
    # Sanitize variables
    if [[ ! -z ${ROLE_SWITCHES} ]]; then
        CLEAN_ROLE_SWITCHES=" ${ROLE_SWITCHES}"
    else
        CLEAN_ROLE_SWITCHES=''
    fi

    if [[ ! -z ${ROLE_TAGS} ]]; then
        CLEAN_ROLE_TAGS=",${ROLE_TAGS}"
    else
        CLEAN_ROLE_TAGS=''
    fi
    
    # Launch a server into an appropriate AZ
    echo "Launching ${SERVER_ROLE} ${SERVER_NAME} using AMI ${SERVER_AMI} into ${ENVIRONMENT} AZ ${SERVER_AZ}"
    knife ec2 server create --availability-zone ${SERVER_AZ} --distro chef-full --ebs-size=${EBS_SIZE} --environment ${ENVIRONMENT} --ephemeral /dev/sde --flavor ${FLAVOR} --groups ${SG_LIST} --identity-file ${SSH_KEY} --image ${SERVER_AMI} --node-name ${SERVER_NAME} --run-list ${RUN_LIST} --ssh-key intern --ssh-user ec2-user${CLEAN_ROLE_SWITCHES} --tags \"Name=${SERVER_NAME},Environment=${ENVIRONMENT},Type=${ROLE},Proxy_Role=${ROLE}${CLEAN_ROLE_TAGS}\" --yes
}

# Do some work!
SETUP_CMD=`echo ${SCRIPT_ARGS} | grep -i setup | wc -l`
if [[ "${SETUP_CMD}" == "1" ]]; then
    setup_tools
fi
setup_chef_env
setup_server_role
setup_server_name
setup_chef_role
setup_ami
get_az
launch_server