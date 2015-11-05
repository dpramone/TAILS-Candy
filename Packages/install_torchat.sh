#!/bin/bash

#########################################################################
# TAILS installer script for Torchat
#
# Part of "TAILS Candy" Project
# Version 0.1a
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
    echo "You need to run this as root. sudo ./install_torchat.sh" 1>&2
    exit 1
fi

clear
echo "This routine non-persistently installs TorChat and dependencies"
echo "from standard Debian package(s)."
echo
echo "Source: https://github.com/prof7bit/TorChat "
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

# Install TorChat & dependencies
# This can also be done from Synaptic but I like it better like this
clear
/usr/bin/apt-get install python-wxversion python-wxgtk2.8 torchat
/usr/bin/sudo -u amnesia /usr/bin/notify-send "TorChat Installed" "Open with Applications > Internet > TorChat"

if [ ! -d /home/amnesia/.torchat ]; then
	sudo -u amnesia mkdir -p /live/persistence/TailsData_unlocked/dotfiles/.torchat 1>&2
	sudo -u amnesia ln -sf /live/persistence/TailsData_unlocked/dotfiles/.torchat /home/amnesia/.torchat 1>&2
else
	echo 
	echo "If you wish to keep your Torchat settings persistent, copy the contents of the /home/amnesia/.torchat directory to /live/persistence/TailsData_unlocked/dotfiles/ before system shutdown."
	echo 
fi

read -n 1 -p "Press any key to launch Torchat now or Ctrl-C to finish up..."
torchat &

