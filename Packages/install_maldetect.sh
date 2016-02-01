#!/bin/bash

#########################################################################
# TAILS installer script for Linux Malware Detect
#
# Part of "TAILS Candy" Project
# Version 0.2
# License: GPL v3 - Copy included with distribution
#
# By Dirk Praet - skylord@jedi.be
#########################################################################

# Function declarations

function error_exit
{
	echo "$1" 1>&2
	exit 1
}

Confirm() { read -sn 1 -p "$* [Y/N]? "; [[ ${REPLY:0:1} = [Yy] ]]; }

function install_clamav
{
	# Install Clamav
	apt-get -y install clamav
        grep -q "clamav" /live/persistence/TailsData_unlocked/live-additional-software.conf
        if [ ! $? -eq 0 ]; then
		echo
		Confirm "Type y if you wish to make Clamav installation persistent." && echo "clamav" >> /live/persistence/TailsData_unlocked/live-additional-software.conf
	fi
}

function patch_conf
{

# Set LMD monitor path to Persistent volume
echo "/home/amnesia/Persistent" > files/monitor_paths

# In-line diff with conf.maldet changes
cat <<EOF > conf.maldet.patch
--- conf.maldet	2015-10-30 13:50:20.165994276 +0100
+++ conf.maldet.tails	2015-10-30 13:51:12.861331806 +0100
@@ -13,12 +13,12 @@
 # alerts as well as automated/manual scan reports. On-demand reports
 # can still be sent using '--report SCANID user@domain.com'.
 # [0 = disabled, 1 = enabled]
-email_alert="0"
+email_alert="1"
 
 # The destination e-mail addresses for automated/manual scan reports
 # and application version alerts.
 # [ multiple addresses comma (,) spaced ]
-email_addr="you@domain.com"
+email_addr="amnesia@localhost"
 
 # Ignore e-mail alerts for scan reports in which all malware hits
 # have been automatically and successfully cleaned.
@@ -38,7 +38,7 @@
 # this be enabled to ensure the latest version, features and bug fixes
 # are always available.
 # [0 = disabled, 1 = enabled]
-autoupdate_version="1"
+autoupdate_version="0"
 
 # This controls validating the LMD executable MD5 hash with known
 # good upstream hash value. This allows LMD to replace the the
@@ -202,7 +202,7 @@
 # init based startup script. This value is ignored when '/etc/sysconfig/maldet'
 # is present with a defined value for $MONITOR_MODE.
 # default_monitor_mode="users"
-# default_monitor_mode="/usr/local/maldetect/monitor_paths"
+default_monitor_mode="/usr/local/maldetect/monitor_paths"
 
 # The base number of files that can be watched under a path,
 # this ends up being a relative value per-user in user mode.
@@ -224,7 +224,7 @@
 # This is the html/web root for users relative to homedir, when
 # this option is set, users will only have the webdir monitored
 # [ clear option to default monitor entire user homedir ]
-inotify_docroot="public_html"
+inotify_docroot=
 
 # Process CPU scheduling (nice) priority level for scan operations.
 # [ -19 = high prio , 19 = low prio, default = 19 ]
EOF

chown amnesia:amnesia conf.maldet.patch
patch -b -V numbered < conf.maldet.patch
chown amnesia:amnesia conf.maldet

# Replace maldet.sh init script file
cat <<EOF > $INSTALL_DIR/files/service/maldet.sh
#! /bin/sh
#
### BEGIN INIT INFO
# Provides:          maldet
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: LMD Monitoring
# Description:       Linux Malware Detect file monitoring
### END INIT INFO

PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="Linux Malware Detect file monitoring"
NAME=maldet
DAEMON=/usr/local/maldetect/$NAME
PIDFILE=/var/run/$NAME.pid
SCRIPTNAME=/etc/init.d/$NAME

# Exit if the package is not installed
[ -x "$DAEMON" ] || exit 0

# Read configuration variable file if it is present
#[ -r /etc/default/$NAME ] && . /etc/default/$NAME

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.2-14) to ensure that this file is present
# and status_of_proc is working.
. /lib/lsb/init-functions

if [ -f "/etc/default/$NAME" ]; then
        . /etc/default/$NAME
elif [ "$(egrep ^default_monitor_mode /usr/local/maldetect/conf.maldet 2> /dev/null)" ]; then
        . /usr/local/maldetect/conf.maldet
        if [ "$default_monitor_mode" ]; then
                MONITOR_MODE="$default_monitor_mode"
        fi
fi

if [ -z "$MONITOR_MODE" ]; then
        echo "Error: no default monitor mode defined, set \$MONITOR_MODE in /etc/default/maldet or \$default_monitor_mode in /usr/local/maldetect/conf.maldet"
        exit 1
fi

DAEMON_ARGS="--monitor $MONITOR_MODE"
RETVAL=0

#
# Function that starts the daemon/service
#
do_start()
{
        # Return
        #   0 if daemon has been started
        #   1 if daemon was already running
        #   2 if daemon could not be started
        start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $DAEMON --test > /dev/null \
                || return 1
        start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $DAEMON -- \
                $DAEMON_ARGS \
                || return 2
}

#
# Function that stops the daemon/service
#
do_stop()
{
        # Return
        #   0 if daemon has been stopped
        #   1 if daemon was already stopped
        #   2 if daemon could not be stopped
        #   other if a failure occurred
        start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile $PIDFILE --name $NAME
        RETVAL="$?"
        [ "$RETVAL" = 2 ] && return 2
        start-stop-daemon --stop --quiet --oknodo --retry=0/30/KILL/5 --exec $DAEMON
        [ "$?" = 2 ] && return 2
        # Many daemons don't delete their pidfiles when they exit.
        rm -f $PIDFILE
        return "$RETVAL"
}

#
# Function that sends a SIGHUP to the daemon/service
#
do_reload() {
        #
        start-stop-daemon --stop --signal 1 --quiet --pidfile $PIDFILE --name $NAME
        return 0
}

case "$1" in
  start)
        [ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC" "$NAME"
        do_start
        case "$?" in
                0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
                2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
        esac
        ;;
  stop)
        [ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME"
        do_stop
        case "$?" in
                0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
                2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
        esac
        ;;
  status)
        status_of_proc "$DAEMON" "$NAME" && exit 0 || exit $?
        #echo -n "Checking $NAME monitoring status: "
        #if [ "$(ps -A --user root -o "cmd" | grep maldetect | grep inotifywait)" ]; then
        #    echo "Running"
        #    exit 0
        #else
        #    echo "Not running"
        #    exit 1
        #fi
        ;;
  restart|force-reload)
        #
        # If the "reload" option is implemented then remove the
        # 'force-reload' alias
        #
        log_daemon_msg "Restarting $DESC" "$NAME"
        do_stop
        case "$?" in
          0|1)
                do_start
                case "$?" in
                        0) log_end_msg 0 ;;
                        1) log_end_msg 1 ;; # Old process is still running
                        *) log_end_msg 1 ;; # Failed to start
                esac
                ;;
          *)
                # Failed to stop
                log_end_msg 1
                ;;
        esac
        ;;
    *)
        echo "Usage: $SCRIPTNAME {start|stop|status|restart|force-reload}" >&2
        exit 3
        ;;
esac

:
EOF
chown amnesia:amnesia $INSTALL_DIR/files/service/maldet.sh

cat <<EOF > $INSTALL_DIR/files/perscan.sh
#!/bin/bash

# Wrapper for maldet persisten volume scan
/usr/local/maldetect/maldet -a /home/amnesia/Persistent
read -n 1 -p "Press any key to continue ..."
EOF
chown amnesia:amnesia $INSTALL_DIR/files/perscan.sh
chmod 700 $INSTALL_DIR/files/perscan.sh

}

# Script main line

if [[ $EUID -ne 0 ]]; then
    echo "You need to run this as root" 1>&2
    exit 1
fi

clear
echo "This routine will install & activate Linux Malware Detect,"
echo "a malware scanner for Linux by Ryan MacDonald."
echo
echo "Source: https://www.rfxn.com/projects/linux-malware-detect/"
echo
echo "1) You need to have TAILS persistence & root password set up."
echo "The script will exit gracefully if this is not the case."
echo "2) We will try to download the Malware Detect source package."
echo "If download fails, the script exits gracefully."
echo "3) Installation is saved in ~/Persistent/maldetect-1.5 ."
echo "4) After every TAILS reboot, reactivate by clicking the desktop icon."
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

cd /home/amnesia/Persistent || error_exit "No persistence found. Aborting"

PERSISTENT=/home/amnesia/Persistent
INSTALL_DIR=$PERSISTENT/maldetect-1.5
REPO_DIR=$PERSISTENT/Packages/Repo
distfile=$REPO/maldetect-current.tar.gz

if [ ! -d "$INSTALL_DIR" ]
then
        cd $REPO_DIR
	if [ ! -f "$distfile" ]; then
        	echo "Trying to download the Malware Detect source package ..."
		wget -O  maldetect-current.tar.gz http://www.rfxn.com/downloads/maldetect-current.tar.gz || error_exit "Unable to download Linux Malware Detect. Giving up."
		wait
		chown amnesia:amnesia maldetect-current.tar.gz
	fi
	tar -xzf maldetect-current.tar.gz
	mv maldetect-1* $PERSISTENT/
	chown -R amnesia:amnesia $PERSISTENT/maldetect-1*
	cd $INSTALL_DIR
	echo "Patching LMD configuration files for TAILS ..."
	patch_conf
fi

echo
echo "Checking for ed and Clamav ..."
echo
# LMD makes use of ed and the clamav scanning engine
dpkg -s ed 2>/dev/null >/dev/null || apt-get -y install ed
dpkg -s clamav 2>/dev/null >/dev/null || install_clamav
echo "Installing Linux Malware Detect ..."
cd $INSTALL_DIR
./install.sh
systemctl start maldet.service
echo "Creating Malware Detect Gnome menu item ..."
echo
desktopdir="/home/amnesia/.local/share/applications"
if [ ! -d "$desktopdir" ]
then
	mkdir -p $desktopdir
fi
/bin/cat <<EOF > $desktopdir/maldetect.desktop
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=LMD Scan Persistent Volume
Name[de]=LMD Scan Persistent Volume
Name[en_GB]=LMD Scan Persistent Volume
Name[fr]=LMD Scan Persistent Volume
Name[fr_CA]=LMD Scan Persistent Volume
Type=Application
Terminal=true
Path=/usr/local/maldetect
Exec=sudo /home/amnesia/Persistent/maldetect-1.5/files/perscan.sh
Icon=/home/amnesia/Persistent/Packages/Settings/Gnome/icons/Malware32.png
Categories=GTK;GNOME;Utility;
StartupNotify=false
EOF
chown amnesia:amnesia $desktopdir/maldetect.desktop

# Remove distribution file?
Confirm "Type y if you wish to remove the distribution file" && rm $REPO_DIR/maldetect-current.tar.gz
echo

sudo -u amnesia /usr/bin/notify-send -i /home/amnesia/Persistent/Packages/Settings/Gnome/icons/Malware64.png "Malware Detect Activated" "Use with Applications > Accessories > Malware Detect on Persistent Volume"

# Remove desktop icon if present
deskfile="/home/amnesia/Desktop/maldet.desktop"
if [ -f $deskfile ];then 
rm $deskfile
fi

echo "Linux Malware Detect has been installed."
echo
read -n 1 -p "Press any key to scan Persistent volume for malware now or Ctrl-C to finish up ..."
/usr/local/maldetect/maldet -a /home/amnesia/Persistent

echo
# Install Rootkit Hunter too ?
Confirm "Would you like to install Rootkit Hunter 1.4.2 too? " && /home/amnesia/Persistent/Packages/install_rkhunter.sh
echo
# Install AIDE ?
Confirm "Would you like to install AIDE 1.6 too? " && /home/amnesia/Persistent/Packages/install_aide.sh
echo

