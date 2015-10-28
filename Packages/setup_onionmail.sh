#!/bin/bash

#########################################################################
# TAILS script for setting up OnionMail
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

Confirm() { read -sn 1 -p "$* [Y/N]? "; [[ ${REPLY:0:1} = [Yy] ]]; }

# Main line

clear
echo "This routine will set up a persistent Onionmail account in"
echo "the TAILS Claws email client."
echo "Source: http://en.onionmail.info/ "
echo
echo "1) You need to have TAILS persistence set up."
echo "The script will exit gracefully if this is not the case."
echo "2) We will try to download the Onionmail setup script that does"
echo "all the work. If download fails, the script exits gracefully."
echo "3) Setup files are saved in ~/Persistent/Packages/Repo/OnionMail."
echo "4) All mailboxes created are saved in ~/Persistent/OnionMail."
echo "5) You can run this script as many times as you want."
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

cd /home/amnesia/Persistent || exit

PERSISTENT=/home/amnesia/Persistent
REPO_DIR=$PERSISTENT/Packages/Repo
INSTALL_DIR=$REPO_DIR/OnionMail

if [ ! -d "$INSTALL_DIR" ]
then
        echo "Trying to download the OnionMail installer ..."
	mkdir -p $INSTALL_DIR
        cd $REPO_DIR
	wizardfile=$REPO_DIR/wizard.tar.gz
	if [ ! -f "$wizardfile" ]
        	wget -O wizard.tar.gz http://louhlbgyupgktsw7.onion/network/wizard.tar.gz || error_exit "Unable to download OnionMail installer. Bailing out ..."
	fi
	mv $wizardfile $INSTALL_DIR
        cd $INSTALL_DIR
	tar -xzvf wizard.tar.gz
	mv wizard.tar.gz $REPO_DIR/
	echo
	Confirm "Type y if you wish to remove the downloaded distribution archive." && rm $REPO_DIR/wizard.tar.gz

	/usr/bin/notify-send "OnionMail Installed" "Create new accounts by (re-)running this script."
fi

cd $INSTALL_DIR/wizard/onionmail
./onionmail-wizard

read -n 1 -p "Press any key to finish up ..."
