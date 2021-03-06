#!/bin/bash

#########################################################################
# TAILS installer script for Shamir's Secret Share Scheme GUI
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

# Main line

clear
echo "This routine will persistently install Samir Shakimov's"
echo "Python GUI for SSSS-Shamir's Secret Sharing Scheme in"
echo "~/Persistent/Git/SSSS."
echo "Source: https://github.com/skhakimov/secret-sharing"
echo
echo "1) You need to have TAILS persistence with dotfiles configured."
echo "The script will exit gracefully if this is not the case."
echo "2) We will try to download Python SSSS from Github. If download"
echo "fails, the script exits gracefully."
echo "3) If the ~/Persistent/Git/SSSS directory already exists,"
echo "we try to update the package with a git pull." 
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

# This script should not be run as root
if [[ $EUID -eq 0 ]]; then
	echo
        error_exit "Please do not run this script with sudo or as root"
fi

cd /live/persistence/TailsData_unlocked/dotfiles || error_exit "Sorry, no dotfiles persistence found."

PERSISTENT=/home/amnesia/Persistent
INSTALL_DIR=$PERSISTENT/Git/SSSS

if [ -d "$INSTALL_DIR" ]
then
        echo "Trying Python SSSS GUI update from Github ..."
        cd $INSTALL_DIR
        git pull
        read -n 1 -p "Press any key to continue..."
else
	echo "Downloading Python SSSS from Github ..."
	mkdir $INSTALL_DIR
	git clone https://github.com/skhakimov/secret-sharing.git $INSTALL_DIR || error_exit "Unable to download SSSS Python GUI. Bailing out ..."
	# Create persistent menu icon
	echo "Creating persistent menu item ..."
	desktopdir=/live/persistence/TailsData_unlocked/dotfiles/.local/share/applications
	if [ ! -d "$desktopdir" ] 
	then
		mkdir -p $desktopdir
	fi
	/bin/cat <<EOT >> $desktopdir/SSSS.desktop
[Desktop Entry]
Version=1.0
Name=SSSS
Type=Application
Terminal=false
Path=/home/amnesia/Persistent/Git/SSSS
Exec=/usr/bin/python /home/amnesia/Persistent/Git/SSSS/GUI.py
Icon=SSSS
Comment=Shamir's Secret Sharing Scheme
Categories=Encryption;Security;
EOT
	if [ ! -d "/home/amnesia/.local/share/applications" ] 
	then
		mkdir -p /home/amnesia/.local/share/applications
	fi
	ln -sf $desktopdir/SSSS.desktop /home/amnesia/.local/share/applications/SSSS.desktop
	/usr/bin/notify-send -i SSSS "Python SSSS Installed" "Open with Applications > Encryption > SSSS"
fi

