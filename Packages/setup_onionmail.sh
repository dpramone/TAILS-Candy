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

control_c()
{
	# Run if user hits control-c
	echo "Script interrupted by user"
	# Clean up any downloads
	rm $REPO_DIR/wizard.tar.gz* 1>&2
	exit 1
}

Confirm() { read -sn 1 -p "$* [Y/N]? "; [[ ${REPLY:0:1} = [Yy] ]]; }

install()
{
	wizardfile=$REPO_DIR/wizard.tar.gz
	cd $REPO_DIR

       	echo "Trying to download the OnionMail installer ..."
       	wget -O wizard.tar.gz http://louhlbgyupgktsw7.onion/network/wizard.tar.gz
	wait
	if [ $? -ne 0 ]; then
		wget -O wizard.tar.gz.asc http://onionmail.info/network/wizard.tar.gz.asc || error_exit "Unable to download OnionMail installer. Bailing out ..."
		wait
		# Retrieve public key of <gestione@onionmail.info>
		gpg --list-keys 8288216B || gpg --keyserver keys.gnupg.net --recv 8288216B
		gpg -o wizard.tar.gz --decrypt wizard.tar.gz.asc || error_exit "Unable to verify signature of downloaded file. Bailing out."
		echo
		read -n 1 -p "If we have a good signature from OnionMail <gestione@onionmail.info>, then it is safe to proceed. If not, press Ctrl-C to abort ..."
	fi 

	mv $REPO_DIR/wizard.tar.gz* $INSTALL_DIR/
        cd $INSTALL_DIR
	# Installs or updates package
	tar -xzvf wizard.tar.gz
	rm wizard.tar.gz*

	/usr/bin/notify-send "OnionMail Installed/Upgraded" "Create new accounts by (re-)running this script."
}

# Main line

# Trap keyboard interrupt (control-c)
trap control_c SIGINT

PERSISTENT=/home/amnesia/Persistent
REPO_DIR=$PERSISTENT/Packages/Repo
INSTALL_DIR=$REPO_DIR/OnionMail

clear
echo "This routine will set up a persistent Onionmail account in"
echo "the TAILS Claws email client."
echo "Source: http://en.onionmail.info/ "
echo
echo "1) You need to have TAILS persistence set up."
echo "The script will exit gracefully if this is not the case."
echo "2) We will try to download the Onionmail setup script that does"
echo "all the work. If download fails, the script exits gracefully."
echo "3) All mailboxes created are saved in ~/Persistent/OnionMail."
echo "4) You can run this script as many times as you want."
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

# This script should not be run as root
if [[ $EUID -eq 0 ]]; then
	error_exit "Please do not run this script with sudo or as root"
fi

cd /home/amnesia/Persistent || exit
clawsmail="/usr/bin/claws-mail"
if [ ! -f "$clawsmail" ]
	error_exit "Claws Mail not installed. Aborting"
fi

if [ ! -d "$INSTALL_DIR" ]; then
	mkdir -p $INSTALL_DIR
	install
else
	Confirm "OnionMail directory already present. Would you like to re-install/upgrade? " && install
fi

cd $INSTALL_DIR/wizard/onionmail
./onionmail-wizard

read -n 1 -p "Press any key to finish up ..."
