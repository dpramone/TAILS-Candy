#!/bin/bash

#########################################################################
# TAILS installer script for Dropbox
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
echo "This routine will persistently install Dropbox."
echo
echo "Source: https://www.dropbox.com/install?os=lnx "
echo
echo "1) You need to have TAILS persistence with dotfiles set up."
echo "The script will exit gracefully if this is not the case."
echo "2) We will try to download the Dropbox headless installer."
echo "If download fails, the script exits gracefully."
echo "3) Installation is saved in /live/persistence/TailsData_unlocked/dotfiles/.dropbox-dist"
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

DOT_DIR=/live/persistence/TailsData_unlocked/dotfiles
cd $DOT_DIR || error_exit "No dotfiles persistence found. Aborting"

INSTALL_DIR=$DOT_DIR/.dropbox-dist
BIN_DIR=$DOT_DIR/bin

if [ ! -d "$INSTALL_DIR" ]
then
        echo "Trying to download the Dropbox headless installer ..."
        cd /live/persistence/TailsData_unlocked/dotfiles
	wget -O - https://www.dropbox.com/install?os=lnx | tar xzf - || error_exit "Unable to download Dropbox. Giving up."
	if [ ! -d "$BIN_DIR" ]; then
	mkdir -p $BIN_DIR
	ln -sf $BIN_DIR /home/amnesia/bin
	fi
	cd $BIN_DIR
	echo "Downloading Dropbox.py console script ..."
	wget -O $BIN_DIR/dropbox.py https://www.dropbox.com/download?dl=packages/dropbox.py || echo "Unable to download dropbox.py cli helper"
	wget -O $BIN_DIR/dropbox_uploader.sh https://raw.github.com/andreafabrizi/Dropbox-Uploader/master/dropbox_uploader.sh || echo "Unable to download dropbox_uploader.sh cli helper"
	cp -p $BIN_DIR/dropbox.py $INSTALL_DIR/ 1>&2
	# Create Dropbox config directory & symlinks
	mkdir $DOT_DIR/.dropbox
	chmod 700 $DOT_DIR/.dropbox
	ln -s $DOT_DIR/.dropbox-dist /home/amnesia/.dropbox-dist
	ln -s  $DOT_DIR/.dropbox /home/amnesia/.dropbox
	echo
	echo "Creating Dropbox menu item ..."
	echo
        desktopdir=/live/persistence/TailsData_unlocked/dotfiles/.local/share/applications
        if [ ! -d "$desktopdir" ]
        then
                mkdir -p $desktopdir
        fi
        /bin/cat <<EOF > $desktopdir/dropbox.desktop
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=Dropbox
Name[de]=Dropbox
Name[en_GB]=Dropbox
Name[fr]=Dropbox
Name[fr_CA]=Dropbox
Comment=Sync your files across computers and to the web
Type=Application
Terminal=false
Exec=torsocks /home/amnesia/bin/dropbox.py start
Icon=/home/amnesia/Persistent/Packages/Settings/Gnome/icons/Dropbox32.png
Categories=Network;
EOF
	cp -p $desktopdir/dropbox.desktop /home/amnesia/.local/share/applications/ 1>&2

# Create desktop icon
cat <<EOF > /home/amnesia/Desktop/dropbox.desktop
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=Dropbox
Name[de]=Dropbox
Name[en_GB]=Dropbox
Name[fr]=Dropbox
Name[fr_CA]=Dropbox
Comment='Sync your files across computers and to the web'
Type=Application
Terminal=false
Exec=torsocks /home/amnesia/bin/dropbox.py start
Icon=/home/amnesia/Persistent/Packages/Settings/Gnome/icons/Dropbox64.png
EOF
chmod 700 /home/amnesia/Desktop/dropbox.desktop

	/usr/bin/notify-send "Dropbox Installed" "Open with Applications > Internet > Dropbox"

	echo
	# Launch Dropbox now
	read -n 1 -p "Dropbox will now be launched with torsocks. Press any key to continue ..."
	echo
	torsocks /home/amnesia/.dropbox-dist/dropboxd
else
	echo
	echo
	read -n 1 -p "Dropbox already installed. It will update itself when you launch it. Press any key to close ..."
fi

