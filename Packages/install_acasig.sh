#!/bin/bash

#########################################################################
# TAILS installer script for Academic Signature by Prof. Michael Anders 
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

function insertAfter # file line newText
{
   local file="$1" line="$2" newText="$3"
   sed -i -e "/^$line$/a"$'\\\n'"$newText"$'\n' "$file"
}

Confirm() { read -sn 1 -p "$* [Y/N]? "; [[ ${REPLY:0:1} = [Yy] ]]; }

# Script main line

clear
echo "This routine will persistently install Academic Signature,"
echo "a Swiss Army Knife of strong cryptography by Prof. Michael Anders."
echo
echo "Source: http://www.fh-wedel.de/~an/crypto/Academic_signature_eng.html"
echo
echo "1) You need to have TAILS persistence & root password set up."
echo "The script will exit gracefully if this is not the case."
echo "2) We will try to download the Academic Signature source package."
echo "If download fails, the script exits gracefully."
echo "3) Installation is saved in ~/Persistent/aca_sig-b52 ."
echo "4) Script will exit if Academic Signature is already installed."
echo "5) Recover settings from previous versions/installations by copying"
echo "over the x_secrets and key_tray subdirectories."
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

cd /home/amnesia/Persistent || error_exit "No persistence found. Aborting"

PERSISTENT=/home/amnesia/Persistent
INSTALL_DIR=$PERSISTENT/aca_sig-b52
REPO_DIR=$PERSISTENT/Packages/Repo

if [ ! -d "$INSTALL_DIR" ]
then
        echo "Trying to download the Academic Signature source package ..."
        cd $REPO_DIR
	wget -O aca_sig-b52.tar.gz https://www.fh-wedel.de/~an/crypto/accessories/aca_sig_sout.php || error_exit "Unable to download Academic Signature. Giving up."
	wait
	tar -xzf aca_sig-b52.tar.gz
	mv aca_sig-b52 $PERSISTENT/
	echo
	echo "Install compiler & dependencies ..."
	echo
	sudo apt-get -y install g++ g++-4.7 gcc gcc-4.7 libc-dev-bin libc6-dev libitm1 libstdc++6-4.7-dev libwxbase2.8-dev libwxgtk2.8-dev linux-libc-dev make wx-common wx2.8-headers
	# Compile Academic Signature the usual way ...
	echo
	echo "Now compiling Academic Signature ..."
	echo
	cd $INSTALL_DIR
	./configure
	# modify src/dolonu.h header because of known bug that prevents compilation on TAILS
	grep -q 'define WX28' $INSTALL_DIR/src/dolonu.h || insertAfter $INSTALL_DIR/src/dolonu.h '#define DOLONUX_H' '#define WX28'
	make || error_exit "Compilation of Academic Signature failed."
	echo
	echo "Creating Gnome menu item ..."
	echo
        desktopdir=/live/persistence/TailsData_unlocked/dotfiles/.local/share/applications
        if [ ! -d "$desktopdir" ]
        then
                mkdir -p $desktopdir
        fi
        /bin/cat <<EOF > $desktopdir/aca_sig.desktop
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=Academic Signature
Name[de]=Academic Signature
Name[en_GB]=Academic Signature
Name[fr]=Academic Signature
Name[fr_CA]=Academic Signature
Type=Application
Terminal=false
Path=/home/amnesia/Persistent/aca_sig-b52
Exec=/home/amnesia/Persistent/aca_sig-b52/aca_sig
Icon=/home/amnesia/Persistent/aca_sig-b52/signature-icon.png
Categories=Security;Encryption;
StartupNotify=true
EOF
	cp -p $desktopdir/aca_sig.desktop /home/amnesia/.local/share/applications/ 1>&2
	/usr/bin/notify-send "Academic Signature Installed" "Open with Applications > Encryption > Academic Signature"

	cd $INSTALL_DIR
	# Remove installation & configuration source files?
	echo
	Confirm "Type y if you wish to clean up installation source files" && rm -rf $INSTALL_DIR/src Make* config* compile depcomp missing aclocal.m4 
	Confirm "Type y if you wish to remove the distribution file" && rm $REPO_DIR/aca_sig-b52.tar.gz
	# Remove compiler & dependencies?
	echo
	Confirm "Type y if you wish to remove the compiler now" && sudo apt-get -y remove g++ g++-4.7 gcc gcc-4.7 libc-dev-bin libc6-dev libitm1 libstdc++6-4.7-dev libwxbase2.8-dev libwxgtk2.8-dev linux-libc-dev make wx-common wx2.8-headers

	echo
	read -n 1 -p "Academic Signature has been installed. Press any key to launch now or Ctrl-C to finish up ..."
	./aca_sig &
else
	echo
	read -n 1 -p "Academic Signature already installed. Press any key to close ..."
fi

