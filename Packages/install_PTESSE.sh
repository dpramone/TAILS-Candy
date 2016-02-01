#!/bin/bash

#########################################################################
# TAILS installer script for Paranoia Works Text Encryption 12R1C &
# Secret Space Encryptor 12R1C
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
echo "This routine will install Paranoia Works Text Encryption 12R1C"
echo "and Secret Space Encryptor File Encryption 12R1C."
echo
echo "Source: http://www.paranoiaworks.mobi/download/downloads.html"
echo
echo "1) You need to have TAILS persistence & root password set up."
echo "The script will exit gracefully if this is not the case."
echo "2) We will try to download the source packages. If download"
echo "fails, the script exits gracefully."
echo "3) Installation, if required, is persisently saved in ~/bin ."
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

# This script should not be run as root
if [[ $EUID -eq 0 ]]; then
        error_exit "Please do not run this script with sudo or as root"
fi

cd /home/amnesia/Persistent || error_exit "No persistence found. Aborting"

BIN_DIR=/live/persistence/TailsData_unlocked/dotfiles/bin
if [ -f "$BIN_DIR/ssefencgui.jar" ]; then
	Confirm "Paranoia TE/SSE FE already installed. Press y to reinstall, n to abort" || error_exit "Re-installation aborted on user request."
fi

PERSISTENT=/home/amnesia/Persistent
REPO_DIR=$PERSISTENT/Packages/Repo
distdir1="$REPO_DIR/Paranoia Text Encryption"
distdir2=$REPO_DIR/SSEFilePC
distfil1=PTE-PC.zip
distfil2=SSEFilePC.zip

cd $REPO_DIR
# Do we already have a copy of the distribution files?
if [ ! -f "$REPO_DIR/$distfil1" ]; then
	echo "Trying to download the Paranoia Text Encryption source package ..."
	wget -O $distfil1 http://www.paranoiaworks.mobi/download/files/PTE-PC.zip || error_exit "Unable to download Paranoia Text Encryption. Giving up."
	wait
fi
if [ ! -f "$REPO_DIR/$distfil2" ]; then
	echo "Trying to download the Paranoia SSE File Encryption source package ..."
	wget -O $distfil2 http://www.paranoiaworks.mobi/download/files/SSEFilePC.zip || error_exit "Unable to download Paranoia SSE File Encryption. Giving up."
	wait
fi

echo "Unpacking distribution files ..."
unzip $distfil1
unzip $distfil2

# Install into ~/bin directory
if [ ! -d "$BIN_DIR" ]; then
	mkdir -p $BIN_DIR
	mkdir /home/amnesia/bin
fi

echo
if Confirm "Press y to install persistently, n for this session only"; then

	rm -f /home/amnesia/bin/pte.jar /home/amnesia/bin/ssefenc.jar /home/amnesia/bin/ssefencgui.jar
	cp "$distdir1/pte.jar" $BIN_DIR/
	ln -sf $BIN_DIR/pte.jar /home/amnesia/bin/pte.jar
	cp $distdir2/ssefenc.jar $BIN_DIR/
	ln -sf $BIN_DIR/ssefenc.jar /home/amnesia/bin/ssefenc.jar
	cp $distdir2/ssefencgui.jar $BIN_DIR/
	ln -sf $BIN_DIR/ssefencgui.jar /home/amnesia/bin/ssefencgui.jar
	desktopdir=/live/persistence/TailsData_unlocked/dotfiles/.local/share/applications
else
	cp "$distdir1/pte.jar" /home/amnesia/bin/
	cp $distdir2/ssefenc.jar /home/amnesia/bin/
	cp $distdir2/ssefencgui.jar /home/amnesia/bin/
	desktopdir=/home/amnesia/.local/share/applications
fi

if [ ! -d "$desktopdir" ]; then
	mkdir -p $desktopdir
fi

echo
echo
echo "Creating Gnome menu items ..."
echo
/bin/cat <<EOF > $desktopdir/pte.desktop
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=Paranoia SSE Text Encryption
Comment=Paranoia SSE Text Encryption 12R1C
Type=Application
Terminal=false
Path=/home/amnesia/bin
Exec=java -jar /home/amnesia/bin/pte.jar
Icon=gdu-encrypted-lock
Categories=Security;Encryption;
StartupNotify=true
EOF
/bin/cat <<EOF > $desktopdir/ssefe.desktop
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=Paranoia SSE File Encryption
Comment=Paranoia SSE File Encryption 12R1C
Type=Application
Terminal=false
Path=/home/amnesia/bin
Exec=java -jar /home/amnesia/bin/ssefencgui.jar
Icon=gdu-encrypted-lock
Categories=Security;Encryption;
StartupNotify=true
EOF

# Make a copy to ~/.local if persistently installed
desktopdir=/live/persistence/TailsData_unlocked/dotfiles/.local/share/applications
if [ -f "$desktopdir/ssefe.desktop" ]; then
	cp -p $desktopdir/ssefe.desktop /home/amnesia/.local/share/applications/
	cp -p $desktopdir/pte.desktop /home/amnesia/.local/share/applications/
fi

# Remove installation & configuration source files?
echo
Confirm "Type y if you wish to remove installation source files" && rm -rf "$distdir1" $distdir2
echo
Confirm "Type y if you wish to remove the distribution files" && rm $REPO_DIR/$distfil1 $REPO_DIR/$distfil2

/usr/bin/notify-send -i gdu-encrypted-lock "SSE Text and File Encryption Installed" "Open with Applications > Encryption > SSE Text/File Encryption"
