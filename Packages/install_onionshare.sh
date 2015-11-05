#!/bin/bash

#########################################################################
# TAILS installer script for OnionShare
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

clear
echo "This routine will persistently install an Onionshare"
echo "git clone in ~/Persistent/onionshare."
echo
echo "Source: https://onionshare.org/ "
echo
echo "1) You need to have TAILS persistence configured."
echo "The script will exit gracefully if this is not the case."
echo "2) We will try to download Onionshare from Github. If the"
echo "download fails, the script exits gracefully."
echo "3) If the ~/Persistent/onionshare directory already exists,"
echo "you can (optionally) request a git pull (package update)." 
echo
echo "4)ATTENTION: To access Onionshare in TAILS, you need to"
echo "execute this script after every TAILS (re)boot."
echo
echo "5)CAVEAT: Onionshare contains a fatal bug in current TAILS!"
echo "Work-around: before launching, set Sandbox 1 -> 0 in /etc/tor/torrc"
echo ", restart Tor with sudo /etc/init.d/tor restart."
echo "After completion: reset Sandbox to '1' and restart Tor."
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

cd /live/persistence/TailsData_unlocked/dotfiles || error_exit "Sorry, no TAILS dotfiles persistence found"

PERSISTENT=/home/amnesia/Persistent
INSTALL_DIR=$PERSISTENT/onionshare

# This script should not be run as root
if [[ $EUID -eq 0 ]]; then
	echo
        error_exit "Please do not run this script with sudo or as root"
fi

if [ -d "$INSTALL_DIR" ]
then
        # Shall we do a git pull?
        while true; do
        read -p "Do you wish to update (git pull) Onionshare? y/n " yesno
        case $yesno in
        [Nn]* ) break;;
        [Yy]* ) 
        	echo "Trying Onionshare update from Github ..."
        	cd $INSTALL_DIR
        	git pull || break
        	read -n 1 -p "Press any key to continue..."
		break ;;
        * ) echo "Please answer (y)es or (n)o.";;
        esac
        done

	echo 
	echo "Installing ..."
	sudo $PERSISTENT/.onionshare_install/install.sh
else
	echo "Downloading Onionshare from Github ..."
	# mkdir $INSTALL_DIR
	git clone https://github.com/micahflee/onionshare.git $INSTALL_DIR || error_exit "Unable to download OnonShare. Bailing out ..."
	cd $PERSISTENT
	echo "Installing ..."
	sudo onionshare/tails/install_in_persistent_volume.sh
fi

