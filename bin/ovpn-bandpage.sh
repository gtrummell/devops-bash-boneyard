#! /bin/bash

### BEGIN INIT INFO
# Provides:		openvpn
# Required-Start:	$remote_fs $syslog
# Required-Stop:	$remote_fs $syslog
# Default-Start:	2 3 4 5
# Default-Stop:		
# Short-Description:	OpenVPN SSL VPN
### END INIT INFO

# /etc/init.d/openvpn: start and stop the OpenVPN SSL VPN Client
# Not super client-ey and friendly for a no-privilege end user.
# Must have sudo to start/stop this service!

# Fail fast
set -xe

# Test for OpenVPN executable
test -x /usr/sbin/openvpn || exit 0
( /usr/sbin/openvpn --help 2>&1 | grep -q OpenVPN ) 2>/dev/null || exit 0

# Set uMask
umask 022

# If there is a defaults file in /etc/default, load it.
if test -f /etc/default/openvpn; then
    . /etc/default/openvpn
fi

# Source LSB Init functions.
. /lib/lsb/init-functions

# Specify a default VPN configuration.  Exit if there is none
if [[ -z "${2}" ]]; then
	ovpn_opts="${ovpn_opts} /etc/openvpn/default.ovpn"
else
	ovpn_opts="${ovpn_opts} ${2}"
fi

# Are we running from init?
run_by_init() {
    ([ "$previous" ] && [ "$runlevel" ]) || [ "$runlevel" = S ]
}

# Are we running from Upstart?
check_for_upstart() {
    if init_is_upstart; then
	exit $1
    fi
}

# Quit if we're trying to start and /etc/openvpn/openvpn_not_to_be_run exists
check_for_no_start() {
    if [ -e /etc/openvpn/openvpn_not_to_be_run ]; then 
	if [ "$1" = log_end_msg ]; then
	    log_end_msg 0 || true
	fi
	if ! run_by_init; then
	    log_action_msg "OpenVPN SSL VPN Client and Server not in use (/etc/openvpn/openvpn_not_to_be_run)" || true
	fi
	exit 0
    fi
}

# Handling for /dev/null.  Init requires that /dev/null be a character device.
check_dev_null() {
    if [ ! -c /dev/null ]; then
	if [ "$1" = log_end_msg ]; then
	    log_end_msg 1 || true
	fi
	if ! run_by_init; then
	    log_action_msg "/dev/null is not a character device!" || true
	fi
	exit 1
    fi
}

# Create the PrivSep empty dir if necessary
check_privsep_dir() {
    if [ ! -d /var/run/openvpn ]; then
	mkdir /var/run/openvpn
	chmod 0755 /var/run/openvpn
    fi
}

# Check to see if OpenVPN has been disabled.
check_config() {
    if [ ! -e /etc/openvpn/openvpn_not_to_be_run ]; then
	/usr/sbin/openvpn $ovpn_opts -t || exit 1
    fi
}

export PATH="${PATH:+$PATH:}/usr/sbin:/sbin"

case "$1" in
  start)
	check_for_upstart 1
	check_privsep_dir
	check_for_no_start
	check_dev_null
	log_daemon_msg "Starting OpenVPN SSL VPN" "openvpn" || true
	if start-stop-daemon --start --quiet --oknodo --pidfile /var/run/openvpn.pid --exec /usr/sbin/openvpn $ovpn_opts; then
	    log_end_msg 0 || true
	else
	    log_end_msg 1 || true
	fi
	;;
  stop)
	check_for_upstart 0
	log_daemon_msg "Stopping OpenVPN SSL VPN" "openvpn" || true
	if start-stop-daemon --stop --quiet --oknodo --pidfile /var/run/openvpn.pid; then
	    log_end_msg 0 || true
	else
	    log_end_msg 1 || true
	fi
	;;

  restart)
	check_for_upstart 1
	check_privsep_dir
	check_config
	log_daemon_msg "Restarting OpenVPN SSL VPN" "openvpn" || true
	start-stop-daemon --stop --quiet --oknodo --retry 30 --pidfile /var/run/openvpn.pid
	check_for_no_start log_end_msg
	check_dev_null log_end_msg
	if start-stop-daemon --start --quiet --oknodo --pidfile /var/run/openvpn.pid --exec /usr/sbin/openvpn $ovpn_opts; then
	    log_end_msg 0 || true
	else
	    log_end_msg 1 || true
	fi
	;;

  status)
	check_for_upstart 1
	status_of_proc -p /var/run/openvpn.pid /usr/sbin/openvpn openvpn && exit 0 || exit $?
	;;

  *)
	log_action_msg "Usage: /etc/init.d/ssh {start|stop|restart|status}" || true
	exit 1
esac

exit 0
