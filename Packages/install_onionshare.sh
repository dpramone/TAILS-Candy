#!/bin/bash

#########################################################################
# TAILS installer script for OnionShare
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
echo "This routine will persistently install an Onionshare 0.9.1"
echo "git clone in ~/Persistent/Git/onionshare."
echo
echo "Source: https://onionshare.org/ "
echo
echo "1) You need to have TAILS persistence configured."
echo "The script will exit gracefully if this is not the case."
echo "2) We will try to download Onionshare from Github. If the"
echo "download fails, the script exits gracefully."
echo "3) If the ~/Persistent/Git/onionshare directory already exists,"
echo "you can (optionally) request a git pull (package update)." 
echo
echo "4)ATTENTION: To access Onionshare in TAILS, you need to"
echo "execute this script after every TAILS (re)boot."
echo
echo "5)CAVEAT: Onionshare is broken in current TAILS!"
echo "We will need to wait till Tor/OnionShare developers come"
echo "up with a fix".
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

cd /live/persistence/TailsData_unlocked/dotfiles || error_exit "Sorry, no TAILS dotfiles persistence found"

PERSISTENT=/home/amnesia/Persistent
INSTALL_DIR=$PERSISTENT/Git/onionshare

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
        [Nn]* ) 
                sudo apt-get install -y python3-flask python3-stem python3-pyqt5 python-nautilus 
                break;;
        [Yy]* ) 
        	echo "Trying Onionshare update from Github ..."
        	cd $INSTALL_DIR
        	git pull || break
                sudo apt-get install -y python3-flask python3-stem python3-pyqt5 python-nautilus build-essential fakeroot python3-all python3-stdeb dh-python
		./install/build_deb.sh
		Confirm "Type y if you wish to remove the compiler now" && sudo apt-get -y remove g++ g++-4.9 gcc gcc-4.9 libc-dev-bin libc6-dev libasan1 libatomic1 libcilkrts5 libitm1 libgcc-4.9-dev libstdc++-4.9-dev libubsan0 linux-libc-dev make
        	read -n 1 -p "Press any key to continue..."
		break ;;
        * ) echo "Please answer (y)es or (n)o.";;
        esac
        done

	echo 
	echo "Installing ..."
	sudo dpkg -i $INSTALL_DIR/deb_dist/onionshare_*.deb
else
	echo "Downloading Onionshare from Github ..."
	# mkdir $INSTALL_DIR
	cd $PERSISTENT/Git
	git clone https://github.com/micahflee/onionshare.git || error_exit "Unable to download OnionShare. Bailing out ..."
	echo "Installing ..."
        sudo apt-get install -y python3-flask python3-stem python3-pyqt5 python-nautilus build-essential fakeroot python3-all python3-stdeb dh-python
	./install/build_deb.sh
	sudo dpkg -i deb_dist/onionshare_*.deb
	Confirm "Type y if you wish to remove the compiler now" && sudo apt-get -y remove g++ g++-4.9 gcc gcc-4.9 libc-dev-bin libc6-dev libasan1 libatomic1 libcilkrts5 libitm1 libgcc-4.9-dev libstdc++-4.9-dev libubsan0 linux-libc-dev make
fi

/usr/bin/notify-send -i /usr/share/pixmaps/onionshare80.xpm "Onionshare Installed" "Open with Applications > Internet > OnionShare"

