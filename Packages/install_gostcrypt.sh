#!/bin/bash

#########################################################################
# TAILS installer script for Gostcrypt 1.3
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


# Script main line

clear
echo "This routine will non-persistently install Gostcrypt 1.3"
echo
echo "Source: https://www.gostcrypt.org/download.php"
echo
echo "1) You need to have TAILS persistence & root password set up."
echo "The script will exit gracefully if this is not the case."
echo "2) We will try to download the Gostcrypt .deb package."
echo "If download fails, the script exits gracefully."
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

# This script should not be run as root
if [[ $EUID -eq 0 ]]; then
        error_exit "Please do not run this script with sudo or as root"
fi

cd /home/amnesia/Persistent || error_exit "No persistence found. Aborting"

BIN_DIR=/live/persistence/TailsData_unlocked/dotfiles/bin

PERSISTENT=/home/amnesia/Persistent
REPO_DIR=$PERSISTENT/Packages/Repo
distfile=GostCrypt_1.3_Debian.i386.deb

cd $REPO_DIR
# Do we already have a copy of the distribution file?
if [ ! -f "$REPO_DIR/$distfile" ]; then
	echo "Trying to download the Gostcrypt package ..."
	wget -O $distfile https://www.gostcrypt.org/download/1.3/Linux/Deb/GostCrypt_1.3_Debian.i386.deb || error_exit "Unable to download Gostcrypt. Giving up."
	wait

        # Verifying checksum of distribution file
        checksum="eeb24c7ece21aab09403633c1a960d2b36b31f02e91ea9e55767f099f49e0916"
        calcval=`sha256sum ./GostCrypt_1.3_Debian.i386.deb | sed -e 's/\s.*$//'`
        if [ "$checksum" = "$calcval" ]; then
                echo "SHA-256 checksum OK!"
        else
                echo
                Confirm "WARNING: SHA-256 checksum value did not match downloaded file! Press y continue or n to abort installation." || error_exit "Gostcrypt installation aborted on user request." 
        fi
fi

echo
echo "Now installing Gostcrypt ..."
echo

if [ ! -d "$BIN_DIR" ]; then
	mkdir -p $BIN_DIR
	mkdir /home/amnesia/bin
fi
sudo dpkg -i GostCrypt_1.3_Debian.i386.deb

	#
	# Check for existence of previous Gostcrypt config directory in persistent volume (dotfiles)
	#
	confdir=/live/persistence/TailsData_unlocked/dotfiles/.GostCrypt
	if [ ! -d "$confdir" ]; then
        	# Create GostCrypt config directory & symlink
        	mkdir $confdir
        	chmod 700 $confdir
        	ln -s  $confdir /home/amnesia/.GostCrypt
	fi

echo
echo "Creating Gnome menu item ..."
echo
desktopdir=/live/persistence/TailsData_unlocked/dotfiles/.local/share/applications
if [ ! -d "$desktopdir" ]; then
	mkdir -p $desktopdir
fi

echo
Confirm "Type y if you wish to remove the distribution file" && rm $REPO_DIR/$distfile

/usr/bin/notify-send "Gostcrypt Installed" "Open with Applications > Encryption > Gostcrypt"

echo
read -n 1 -p "Gostcrypt has been installed. Press any key to launch now or Ctrl-C to finish up ..."

/usr/bin/gostcrypt &
