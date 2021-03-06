#!/bin/bash

#########################################################################
# TAILS installer script for Tor Messenger 0.1.0b4 (beta)
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

checksig()
{

# Takes gpg key fingerprint as an argument
echo
echo "Fetching package authors gpg key ..."
gpg --list-keys $1 || gpg --keyserver keys.gnupg.net --recv $1
# Download distribution file check sum file
echo "Downloading package checksum file ..."
wget -O sha256sums.txt -t 10 --no-check-certificate https://dist.torproject.org/tormessenger/0.2.0b2/sha256sums.txt || echo "Unable to download checksum file"
wait
if [ -s ./sha256sums.txt ]; then
	local checksum=`grep linux32 sha256sums.txt | sed -e 's/\s.*$//'`
	local calcval=`sha256sum ./tor-messenger-linux32-0.2.0b2_en-US.tar.xz | sed -e 's/\s.*$//'`
	test "$checksum" = "$calcval" && echo "Checksum OK!" || echo "WARNING: Checksum values did not match!"
	rm sha256sums.txt
else
echo "Unable to fetch checksum file and verify downloaded Tor Messenger distribution file"
fi

echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort installation ..."

}

Confirm() { read -sn 1 -p "$* [Y/N]? "; [[ ${REPLY:0:1} = [Yy] ]]; }

# Main line

clear
echo 
echo "This script will persistenly install Tor Messenger 0.2.0b2 (beta)."
echo
echo "Source: https://blog.torproject.org/blog/tor-messenger-beta-chat-over-tor-easily "
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

PER_DIR=/home/amnesia/Persistent
cd $PER_DIR || error_exit "No TAILS persistence found. Aborting"

REPO_DIR=/home/amnesia/Persistent/Packages/Repo
INSTALL_DIR="/home/amnesia/Persistent/tor-messenger"
distfile="tor-messenger-linux32-0.2.0b2_en-US.tar.xz"

# This script should not be run as root
if [[ $EUID -eq 0 ]]; then
        error_exit "Please do not run this script with sudo or as root"
fi

if [ -d "$INSTALL_DIR" ];then
Confirm "Tor Messenger already installed. Press Y to upgrade/overwrite or N to quit." || exit
fi

# Do we already have a copy of the Tor Messenger distribution file ?
cd $PER_DIR
installfile=$REPO_DIR/$distfile
if [ ! -f "$installfile" ]; then
	echo
	echo "Downloading Tor Messenger distribution file ..."
	echo
	wget -O $distfile https://dist.torproject.org/tormessenger/0.2.0b2/tor-messenger-linux32-0.2.0b2_en-US.tar.xz || error_exit "Unable to download Tor Messenger. Bailing out."
else
	mv $installfile $PER_DIR/
fi
# Verify checksum of downloaded distribution file
secring="/home/amnesia/.gnupg/secring.gpg"
if [ -f "$secring" ]; then checksig 3A0B3D84370896136B845E826887935AB297B391 ; fi

if [ -d "$INSTALL_DIR" ];then
echo
echo "Overwriting/upgrading existing installation ..."
fi 

echo "Unpacking distribution file ..."
tar -xJf $distfile
echo
Confirm "Do you wish to keep the downloaded/saved distribution file?" && mv $distfile $REPO_DIR/ || rm $distfile
echo

# Create menu item
cd $INSTALL_DIR
echo
#./start-tor-messenger.desktop --help >/dev/null 2>&1
echo "Registering Tor Messenger in Gnome ..."
./start-tor-messenger.desktop --register-app

/usr/bin/notify-send "Tor Messenger Installed" "Open with Applications > Internet > Tor Messenger"

echo
echo "ATTENTION: Configure Tor to connect through the SOCKS 5 proxy at"
echo "127.0.0.1 port 9050 for things to work!"
echo
read -n 1 -p "Press any key to launch Tor Messenger anyway or Ctrl-C to finish up..."
echo
echo "Opening up tcp ports 9152-9153 to connect Tor Messenger ..."
echo
sudo iptables -I OUTPUT -o lo -p tcp --dport 9152 -j ACCEPT
sudo iptables -I OUTPUT -o lo -p tcp --dport 9153 -j ACCEPT
./start-tor-messenger.desktop

