#!/bin/bash

#########################################################################
# TAILS installer script for AESCrypt 3.10
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
echo "This routine will non-persistently install AESCrypt 3.10"
echo
echo "Source: https://www.aescrypt.com"
echo
echo "We will try to download the source package. If download"
echo "fails, the script exits gracefully."
echo
echo "You will need to re-run this script after every reboot."
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

# This script should not be run as root
if [[ $EUID -eq 0 ]]; then
        error_exit "Please do not run this script with sudo or as root"
fi

REPO_DIR=/home/amnesia/Persistent/Packages/Repo
distfile=AESCrypt-GUI-3.10-Linux-x86-Install.tgz
installer=AESCrypt-GUI-3.10-Linux-x86-Install

cd $REPO_DIR
# Do we already have a copy of the distribution files?
if [ ! -f "$REPO_DIR/$distfile" ]; then
	echo "Trying to download the AESCrypt source package ..."
	wget -O $distfile https://www.aescrypt.com/download/v3/linux/AESCrypt-GUI-3.10-Linux-x86-Install.tgz || error_exit "Unable to download AESCrypt. Giving up."
	wait
fi

echo "Unpacking distribution file ..."
tar -xzf $distfile
sudo ./$installer --mode silent
wait

echo
echo "Creating Gnome menu item ..."

desktopdir=/home/amnesia/.local/share/applications
if [ ! -d "$desktopdir" ]; then
	mkdir -p $desktopdir
fi

/bin/cat <<EOF > $desktopdir/AESCrypt.desktop
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=AESCrypt
Tooltip=Encrypt or Decrypt a file using AESCrypt 
Comment=Encrypt or Decrypt a file using AESCrypt
Exec=/usr/bin/aescrypt-gui %f
ExecutionMode=normal
Type=Application
Icon=gdu-encrypted-lock
Categories=Security;Encryption;
#MimeType=all/allfiles;
#Enabled=true
Hidden=true
EOF

# Remove installation & configuration source files?
echo
Confirm "Type y if you wish to remove the AESCrypt installer" && rm -rf $REPO_DIR/$installer
echo
Confirm "Type y if you wish to remove the AESCrypt distribution file" && rm $REPO_DIR/$distfile 
echo

/usr/bin/notify-send -i gdu-encrypted-lock "AESCrypt Installed" "Open with Applications > Encryption > AESCrypt"
