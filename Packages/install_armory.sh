#!/bin/bash

#########################################################################
# TAILS installer script for Armory Bitcoin wallet management
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

# Main line

if [[ $EUID -ne 0 ]]; then
    echo "You need to run this as root" 1>&2
    exit 1
fi

clear
echo 
echo "This routine will non-persistently install the Armory offline"
echo "bundle and its dependencies from Debian package(s). Armory is"
echo "a Bitcoin wallet management application." 
echo 
echo "Source: https://bitcoinarmory.com "
echo 
echo "1) You need to have TAILS persistence with dotfiles set up."
echo "The script will exit gracefully if this is not the case."
echo "2) We will try to download the Dropbox headless installer."
echo "If download fails, the script exits gracefully."
echo "3) ATTENTION: Do not forget to configure for use with Tor"
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

DOT_DIR=/live/persistence/TailsData_unlocked/dotfiles
cd $DOT_DIR || error_exit "No dotfiles persistence found. Aborting"

PERSISTENT=/home/amnesia/Persistent
INSTALL_DIR=$PERSISTENT/Packages/Repo

# Armory dependencies
echo "Installing Armory dependencies first ..."
/usr/bin/apt-get install python-crypto python-openssl python-psutil python-pyasn1 python-twisted python-twisted-bin python-twisted-conch python-twisted-core python-twisted-lore python-twisted-mail python-twisted-names python-twisted-news python-twisted-runner python-twisted-web python-twisted-words

# Do we already have a copy of the Armory .deb installation file?
cd $INSTALL_DIR
cnt=`ls armory*-32bit.deb 2>/dev/null | wc -l`
if [ "$cnt" = "0" ]; then
wget -O armory_0.93.2_ubuntu-32bit.deb https://s3.amazonaws.com/bitcoinarmory-releases/armory_0.93.2_ubuntu-32bit.deb || error_exit "Sorry, unable to download Armory. Bailing out." 
chown amnesia:amnesia $INSTALL_DIR/armory*-32bit.deb
fi
/usr/bin/dpkg -i $INSTALL_DIR/armory*-32bit.deb || error_exit "Armory installation failed! WTF?" 

# Config dir already present?
confdir=$DOT_DIR/.armory
if [ ! -d "$confdir" ]; then
        # Create Armory config directory & symlink
        mkdir $confdir
	chown amnesia:amnesia $confdir
        chmod 700 $confdir
        sudo -u amnesia ln -s  $confdir /home/amnesia/.armory
fi

sudo -u amnesia /usr/bin/notify-send "Armory Bundle Installed" "Open with Applications > Internet > Armory"
