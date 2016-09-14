#!/bin/bash

#########################################################################
# TAILS installer script for Armory Bitcoin wallet management
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

function error_sig
{
	echo "Unable to download signature file"
	rm armory_0.93.3_sha256sum.txt.asc
}

checksig()
{

echo
sudo -u amnesia gpg --list-keys 0x98832223 || gpg --recv-keys --keyserver keyserver.ubuntu.com 98832223
#
# Download distribution file signature
#
curl --socks5-hostname 127.0.0.1:9050 -k -L -J -O https://www.bitcoinarmory.com/downloads/bitcoinarmory-releases/armory_0.93.3_sha256sum.txt.asc || echo error_sig
wait

if [ -s ./armory_0.93.3_sha256sum.txt.asc ]; then
	chown amnesia:amnesia armory_0.93.3_sha256sum.txt.asc
	dpkg -s dpkg-sig 2>/dev/null >/dev/null || apt-get -y install dpkg-sig
	dpkg-sig --verify armory_0.93.3_ubuntu-32bit.deb
	echo 
	echo "You should see the string 4AB16AEA98832223 at the end of the GOODSIG line."
	echo "If this is not the case, you should NOT uses this installer."
	echo
else
	echo "Unable to fetch signature file and verify downloaded Armory distribution file"
fi

echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort installation ..."

}

Confirm() { read -sn 1 -p "$* [Y/N]? "; [[ ${REPLY:0:1} = [Yy] ]]; }


# Main line

if [[ $EUID -ne 0 ]]; then
    echo "You need to run this script as root, i.e. sudo install_armory.sh" 1>&2
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

# Do we already have a copy of the Armory .deb installation file?
cd $INSTALL_DIR
cnt=`ls armory*-32bit.deb 2>/dev/null | wc -l`
if [ "$cnt" = "0" ]; then
wget -O armory_0.93.3_ubuntu-32bit.deb https://www.bitcoinarmory.com/downloads/bitcoinarmory-releases/armory_0.93.3_ubuntu-32bit.deb 
if [[ "$?" != 0 ]]; then
	rm armory_0.93.3_ubuntu-32bit.deb 
	echo "Unable to download armory distribution file"
	echo "This is probably a Cloudflare Captcha problem."
	echo "Please go to https://www.bitcoinarmory.com/downloads"
	echo "to download the file manually. Save it in ~/Persistent/"
	echo "Packages/Repo/, then restart this installer." 
	echo "exit 1"
else
	chown amnesia:amnesia $INSTALL_DIR/armory*-32bit.deb
fi
wait
fi
checksig

# Armory dependencies
echo "Installing Armory dependencies first ..."
/usr/bin/apt-get install python-crypto python-openssl python-psutil python-pyasn1 python-twisted python-twisted-bin python-twisted-conch python-twisted-core python-twisted-lore python-twisted-mail python-twisted-names python-twisted-news python-twisted-runner python-twisted-web python-twisted-words

/usr/bin/dpkg -i $INSTALL_DIR/armory*-32bit.deb || error_exit "Armory installation failed! WTF?" 
#
# Remove distribution file?
echo
Confirm "Type y if you wish to remove the distribution file" && rm $INSTALL_DIR/armory_*-32bit.deb $INSTALL_DIR/armory_0.93.3_sha256sum.txt.asc
echo

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
