#!/bin/bash

#########################################################################
# TAILS installer script for Gostcrypt 1.0
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


# Script main line

clear
echo "This routine will persistently install Gostcrypt 1.0"
echo
echo "Source: https://www.gostcrypt.org/download.php"
echo
echo "1) You need to have TAILS persistence & root password set up."
echo "The script will exit gracefully if this is not the case."
echo "2) We will try to download the Gostcrypt source package."
echo "If download fails, the script exits gracefully."
echo "3) Installation is saved in ~/bin ."
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

# This script should not be run as root
if [[ $EUID -eq 0 ]]; then
        error_exit "Please do not run this script with sudo or as root"
fi

cd /home/amnesia/Persistent || error_exit "No persistence found. Aborting"

BIN_DIR=/live/persistence/TailsData_unlocked/dotfiles/bin
if [ -f "$BIN_DIR/gostcrypt" ]; then
	Confirm "Gostcrypt already installed. Press y to reinstall, n to abort" || error_exit "Re-installation aborted on user request."
fi

PERSISTENT=/home/amnesia/Persistent
REPO_DIR=$PERSISTENT/Packages/Repo
COMP_DIR=$REPO_DIR/GostCrypt_Linux_1.0
distfile=GostCrypt_Linux_1.0.tar.gz

cd $REPO_DIR
# Do we already have a copy of the distribution file?
if [ ! -f "$REPO_DIR/$distfile" ]; then
	echo "Trying to download the Gostcrypt source package ..."
	wget -O $distfile https://www.gostcrypt.org/download/1.0/linux/GostCrypt_Linux_1.0.tar.gz || error_exit "Unable to download Gostcrypt. Giving up."
	wait

        # Verifying checksum of distribution file
        checksum="f5ad77f222b54b41acd70220d67518a8293707892b143bb598b2aa865023943b"
        calcval=`sha256sum ./GostCrypt_Linux_1.0.tar.gz | sed -e 's/\s.*$//'`
        if [ "$checksum" = "$calcval" ]; then
                echo "SHA-256 checksum OK!"
        else
                echo
                Confirm "WARNING: SHA-256 checksum value did not match downloaded file! Press y continue or n to abort installation." || error_exit "Gostcrypt installation aborted on user request." 
        fi
fi

echo "Unpacking distribution file ..."
tar -xzf $distfile

echo
echo "Install g++ compiler & dependencies ..."
echo
sudo apt-get -y install g++ g++-4.7 gcc gcc-4.7 libc-dev-bin libc6-dev libitm1 libstdc++6-4.7-dev libwxbase2.8-dev libwxgtk2.8-dev linux-libc-dev make wx-common wx2.8-headers libfuse-dev libselinux1-dev libsepol1-dev pkg-config
# Compile Gostcrypt the usual way ...
echo
echo "Now compiling Gostcrypt ..."
echo
cd $COMP_DIR
make || error_exit "Compilation of Gostcrypt failed."

# Install into ~/bin directory
if [ ! -d "$BIN_DIR" ]; then
	mkdir -p $BIN_DIR
	mkdir /home/amnesia/bin
fi
if [ -f "$COMP_DIR/Main/gostcrypt" ]; then
	cp $COMP_DIR/Main/gostcrypt $BIN_DIR/
	ln -sf $BIN_DIR/gostcrypt /home/amnesia/bin/gostcrypt
fi
cp $COMP_DIR/Resources/Icons/*.xpm $PERSISTENT/Packages/Settings/Gnome/icons/

echo
echo "Creating Gnome menu item ..."
echo
desktopdir=/live/persistence/TailsData_unlocked/dotfiles/.local/share/applications
if [ ! -d "$desktopdir" ]; then
	mkdir -p $desktopdir
fi
/bin/cat <<EOF > $desktopdir/gostcrypt.desktop
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=Gostcrypt 1.0
Name[de]=Gostcrypt 1.0
Name[en_GB]=Gostcrypt 1.0
Name[fr]=Gostcrypt 1.0
Name[fr_CA]=Gostcrypt 1.0
Comments=Truecrypt successor with GOST
Type=Application
Terminal=false
Path=/home/amnesia/Persistent/bin
Exec=/home/amnesia/Persistent/bin/gostcrypt
Icon=/home/amnesia/Persistent/Packages/Settings/Gnome/icons/GostCrypt-16x16.xpm
Categories=Security;Encryption;
StartupNotify=true
EOF
cp -p $desktopdir/gostcrypt.desktop /home/amnesia/.local/share/applications/ 1>&2

# Remove installation & configuration source files?
echo
Confirm "Type y if you wish to remove installation source files" && rm -rf $COMP_DIR
echo
Confirm "Type y if you wish to remove the distribution file" && rm $REPO_DIR/$distfile
# Remove compiler & dependencies?
echo
Confirm "Type y if you wish to remove the compiler now" && sudo apt-get -y remove g++ g++-4.7 gcc gcc-4.7 libc-dev-bin libc6-dev libitm1 libstdc++6-4.7-dev libwxbase2.8-dev libwxgtk2.8-dev linux-libc-dev make wx-common wx2.8-headers libfuse-dev libselinux1-dev libsepol1-dev pkg-config

/usr/bin/notify-send -i /home/amnesia/Persistent/Packages/Settings/Gnome/icons/GostCrypt-48x48.xpm "Gostcrypt Installed" "Open with Applications > Encryption > Gostcrypt"

echo
read -n 1 -p "Gostcrypt has been installed. Press any key to launch now or Ctrl-C to finish up ..."

/home/amnesia/bin/gostcrypt &
