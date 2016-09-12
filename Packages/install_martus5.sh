#!/bin/bash

#!/bin/bash

#########################################################################
# TAILS installer script for Martus 5.1.1 Client
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
echo "This routine will persistently install the Martus 5.1.1 secure"
echo "information colection and management tool for activists."
echo
echo "Source: https://www.martus.org/ "
echo
echo "1) You need to have TAILS persistence set up."
echo "The script will exit gracefully if this is not the case."
echo "2) We will try to download the Martus installer. If download"
echo "fails, the script exits gracefully."
echo "3) Installation is saved in ~/Persistent/MartusClient-5.1.1 ."
echo "Settings are saved in ~/Persistent/.Martus ."
echo "4) Script will exit if Martus is already installed."
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

cd /home/amnesia/Persistent || error_exit "Sorry, no TAILS persistence found."

PERSISTENT=/home/amnesia/Persistent
INSTALL_DIR=$PERSISTENT/MartusClient-5.1.1
REPO_DIR=$PERSISTENT/Packages/Repo
REPO_FILE=$REPO_DIR/Martus-5.1.1.zip

# This script should not be run as root
if [[ $EUID -eq 0 ]]; then
        error_exit "Please do not run this script with sudo or as root"
fi

if [ ! -d "$INSTALL_DIR" ]; then
        cd $PERSISTENT
	if [ -f "$REPO_FILE" ]; then
		echo "Using previously saved Martus distribution package ..."
		mv $REPO_FILE $PERSISTENT/
	else
        	echo "Trying to download the Martus package (43 MB)..."
        	wget https://martus.org/installers/Martus-5.1.1.zip || error_exit "Unable to download Martus 5.1.1 client. Bailing out."
		wait
	fi
	# Verifying checksum of distribution file
        checksum="da13a7ed03788a9a4abf5988ab64370644fdfa4c"
        calcval=`sha1sum ./Martus-5.1.1.zip`
        if [ "$checksum" = "$calcval" ]; then
		echo "SHA-1 checksum OK!"
	else
		echo
		read -n 1 -p "WARNING: SHA-1 checksum value did not match downloaded file! Press any key to continue or Ctrl-C to abort installation."
	fi

	unzip Martus-5.1.1.zip
	mv Martus-5.1.1.zip $REPO_DIR/
	echo
	Confirm "Type y if you wish to keep the downloaded/saved distribution file" || rm $REPO_DIR/Martus-5.1.1.zip
	echo	
	echo "Creating Gnome menu item ..."
        desktopdir=/live/persistence/TailsData_unlocked/dotfiles/.local/share/applications
        if [ ! -d "$desktopdir" ]
        then
                mkdir -p $desktopdir
        fi
        /bin/cat <<EOF >> $desktopdir/martus.desktop
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=Martus Client 5.1.1
GenericName=Martus
Comment=Secure/encrypted bulletins
Icon=java
Terminal=false
Type=Application
Categories=Network;
Path=/home/amnesia/Persistent/MartusClient-5.1.1
Exec=/home/amnesia/Persistent/MartusClient-5.1.1/run.sh
StartupNotify=true
EOF
	cp -p $desktopdir/martus.desktop /home/amnesia/.local/share/applications/
	echo "Create Java run file ..."
        /bin/cat <<EOF > $INSTALL_DIR/run.sh
#!/bin/bash
#
# This script launches the Martus 5.1.1 Client
#
java -DsocksProxyHost=127.0.0.1 -DsocksProxyPort=9050 -Duser.home=/home/amnesia/Persistent -jar martus.jar
EOF
	chmod 700 $INSTALL_DIR/run.sh
	/usr/bin/notify-send "Martus Installed" "Open with Applications > Internet > Martus Client 5.1.1"
	echo
	echo "Removing Java 7 and Installing Java 8 ..."
	sudo apt-get remove openjdk-7-jre openjdk-7-jre-headless
	sudo apt-get install openjdk-8-jre openjdk-8-jre-headless openjfx libopenjfx-java libopenjfx-ini
	read -n 1 -p "Martus client has been installed. Press any key to finish up ..."
else
	echo "Removing Java 7 and Installing Java 8 ..."
	sudo apt-get remove openjdk-7-jre openjdk-7-jre-headless
	sudo apt-get install openjdk-8-jre openjdk-8-jre-headless openjfx libopenjfx-java libopenjfx-ini
	read -n 1 -p "Martus client already installed. Press any key to close ..."
fi

