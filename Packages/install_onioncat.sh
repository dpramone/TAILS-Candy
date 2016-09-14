#!/bin/bash

#########################################################################
# TAILS installer script for OnionCat
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

# Script main line
if [[ $EUID -ne 0 ]]; then
    echo "You need to run this as root. sudo ./install_onioncat.sh" 1>&2
    exit 1
fi

clear
echo "This routine non-persistently installs OnionCat 0.2.2"
echo "from standard Debian package(s)."
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

# Install OnionCat
# This can also be done from Synaptic but I like it better like this
clear
/usr/bin/apt-get install onioncat
/usr/bin/sudo -u amnesia /usr/bin/notify-send "OnionCat Service Installed" "Start with sudo /etc/init.d/onioncat start"

#if [ ! -d /home/amnesia/.onioncat ]; then
#	sudo -u amnesia mkdir -p /live/persistence/TailsData_unlocked/dotfiles/.onioncat 1>&2
#	sudo -u amnesia ln -sf /live/persistence/TailsData_unlocked/dotfiles/.onioncat /home/amnesia/.onioncat 1>&2
#else
#	echo 
#	echo "If you wish to keep your OnionCat settings persistent, copy the contents of the /home/amnesia/.onioncat directory to /live/persistence/TailsData_unlocked/dotfiles/ before system shutdown."
#	echo 
#fi
echo ""
echo "Getting onioncat running on TAILS"
echo "=================================="
echo ""
echo "1. Create a Tor hidden service listening on port 8060 and pointing to"
echo "127.0.0.1:8060."
echo "2. In /etc/default/onioncat, pass the hidden service hostname via DAEMON_OPTS."
echo "3. In /etc/default/onioncat, uncomment ENABLED=yes."
echo "4. Start the service with the -sudo service onioncat start- command."
echo ""

read -n 1 -p "Press any key to launch OnionCat Service now or Ctrl-C to finish up..."
/etc/init.d/onioncat start

