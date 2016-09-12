#!/bin/bash

#########################################################################
# TAILS installer script for Zulucrypt 5.0.1
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

# Main line

# This script should be run as root
if [[ $EUID -ne 0 ]]; then
        error_exit "This script needs to be run as root."
fi

clear
echo 
echo "This script will non-persistenly install Zulucrypt 5.0.1"
echo "It will create a dotfiles .ZuluCrypt directory to"
echo "persistently store settings."
echo
echo "Re-run this script on every boot when you need Zulucrypt."
echo
echo "Source: https://mhogomchungu.github.io/zuluCrypt/"
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

DOT_DIR=/live/persistence/TailsData_unlocked/dotfiles
cd $DOT_DIR || error_exit "No dotfiles persistence found. Aborting"

REPO_DIR=/home/amnesia/Persistent/Packages/Repo
ZULU_DIR=$REPO_DIR/zuluCrypt-5.0.1-debian-8-Jessie

# Do we already have a copy of the Zulucrypt installer ?
cd $REPO_DIR
installfile=$ZULU_DIR/i386/zulucrypt-gui_5.0.1.1472658443.fafef92_i386.deb
if [ ! -f "$installfile" ]; then
	rm -rf $REPO_DIR/zulu* 2>/dev/null >/dev/null
	curl --socks5-hostname 127.0.0.1:9050 -k -L -J -O https://github.com/mhogomchungu/zuluCrypt/releases/download/5.0.1/zuluCrypt-5.0.1-debian-8-Jessie.tar.xz || error_exit "Unable to download Zulucrypt installer. Bailing out."
	wait
	tar -xJvf zuluCrypt-5.0.1-debian-8-Jessie.tar.xz
	# We don't need the x64 stuff on this platform
	rm -rf $ZULU_DIR/amd64
	chown -R amnesia:amnesia $ZULU_DIR
fi
# Installing dependencies
echo "Installing Qt5 dependencies ..."
apt-get install libqt5core5a libqt5gui5 libqt5network5 libqt5widgets5 libqt5clucene5 libqt5dbus5 libqt5designer5 libqt5help5 libqt5printsupport5 libqt5sql5 libqt5test5 libqt5xml5 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-render-util0
# Install .deb files
echo "Now installing Zulucrypt ..."
cd $ZULU_DIR/i386
dpkg -s zulucrypt-gui  2>/dev/null >/dev/null || dpkg -i *zulu*i386.deb
clear

echo
Confirm "Do you wish to keep the downloaded/saved distribution file?" || rm $REPO_DIR/zuluCrypt-5.0.1-debian-8-Jessie.tar.xz
echo

#
# Check for existence of previous Zulucrypt config directory in persistent volume (dotfiles)
#
confdir=/live/persistence/TailsData_unlocked/dotfiles/.zuluCrypt
if [ ! -d "$confdir" ]
then
        # Create Zulucrypt config directory & symlink
        sudo -u amnesia mkdir $confdir
        chmod 700 $confdir
        sudo -u amnesia ln -s  $confdir /home/amnesia/.zuluCrypt
fi

echo
echo "All done."
 
sudo -u amnesia /usr/bin/notify-send -i zuluCrypt.png "Zulucrypt Installed" "Open with Applications > Encryption > Zulucrypt"
