#!/bin/bash

#########################################################################
# TAILS installer script for Duplicity/Horcrux backup
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
echo "This routine will persistently install Chris Poole's"
echo "Duplicity/rsync-based Horcrux backup script in ~/Persistent/"
echo "Horcrux."
echo
echo "Source: https://github.com/piffio/horcrux"
echo "        http://chrispoole.com/project/general/horcrux/"
echo
echo "1) You need to have TAILS persistence with dotfiles configured."
echo "The script will exit gracefully if this is not the case."
echo "2) We will try to download Horcrux from Github. If download"
echo "fails, the script exits gracefully."
echo "3) If the ~/Persistent/horcrux directory already exists,"
echo "we try to update the package with a git pull." 
echo "4) On first run, we create a ~/.horcrux config directory containing"
echo "the main config file as well as -config and -exclude files you need"
echo "to adjust to reflect your own backup needs."
echo
echo "5) As Horcrux requires Duplicity and some additional packages"
echo ", you need to re-run this script at every TAILS reboot."
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

# This script should be run as root
if [[ $EUID -ne 0 ]]; then
	echo
        error_exit "We need to run this script as root."
fi

cd /live/persistence/TailsData_unlocked/dotfiles || error_exit "Sorry, no dotfiles persistence found."

PERSISTENT=/home/amnesia/Persistent
INSTALL_DIR=$PERSISTENT/horcrux

# 
# Install Duplicity
#
echo "Installing Duplicity and dependencies ..."
dpkg -s duplicity  2>/dev/null >/dev/null || apt-get install duplicity librsync1 python-lockfile md5deep

if [ -d "$INSTALL_DIR" ]
then
        echo "Trying Horcrux update from Github ..."
        cd $INSTALL_DIR
        sudo -u amnesia git pull
        read -n 1 -p "Press any key to continue..."
else
	echo "Downloading Horcrux from Github ..."
	sudo -u amnesia mkdir $INSTALL_DIR
	sudo -u amnesia git clone https://www.github.com/piffio/horcrux.git $INSTALL_DIR || error_exit "Unable to download Horcrux. Bailing out ..."
fi

# Create menu icon
echo "Creating menu item ..."
desktopdir=/home/amnesia/.local/share/applications
if [ ! -d "$desktopdir" ] 
then
	sudo -u amnesia mkdir -p $desktopdir
fi
sudo -u amnesia /bin/cat <<EOT >> $desktopdir/horcrux.desktop
[Desktop Entry]
Version=1.0
Name=Horcrux Backup
Type=Application
Terminal=true
Path=/home/amnesia/Persistent/horcrux
Exec=/home/amnesia/Persistent/horcrux/horcrux auto persistent
Icon=grsync
Comment=Horcrux Backup
Categories=System;Security;
EOT

#
# Check for existence of previous Horcrux config directory in persistent volume (dotfiles)
#
confdir=/live/persistence/TailsData_unlocked/dotfiles/.horcrux
if [ ! -d "$confdir" ]
then
        # Create Horcrux config directory, symlink and basic config/exclude files
        sudo -u amnesia mkdir $confdir
        sudo -u amnesia chmod 700 $confdir
        sudo -u amnesia ln -s  $confdir /home/amnesia/.horcrux
	sudo -u amnesia cat <<EOT >> $confdir/persistent-config
destination_path="rsync://username@your_server//home/username/backup/"
#destination_path="file:///media/medianame/backup/"
EOT
	sudo -u amnesia cat <<EOT >> $confdir/persistent-exclude
+ /live/persistence
+ /home/amnesia/Persistent
 /home/amnesia/Persistent/Dropbox
**/*
EOT
	# Create configuration directory
	sudo -u amnesia /home/amnesia/Persistent/horcrux/horcrux
fi


sudo -u amnesia notify-send -i grsync "Horcrux backup Installed" "Open with Applications > System Tools > Horcrux Backup"

