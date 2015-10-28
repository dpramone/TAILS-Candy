#!/bin/bash

#!/bin/bash

#########################################################################
# TAILS installer script for Martus 4.4 Client
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
echo "This routine will persistently install the Martus 4.4 secure"
echo "information colection and management tool for activists."
echo
echo "Source: https://www.martus.org/ "
echo
echo "1) You need to have TAILS persistence set up."
echo "The script will exit gracefully if this is not the case."
echo "2) We will try to download the Martus installer. If download"
echo "fails, the script exits gracefully."
echo "3) Installation is saved in ~/Persistent/MartusClient-4.4.0 ."
echo "Settings are saved in ~/Persistent/.Martus ."
echo "4) Script will exit if Martus is already installed."
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

cd /home/amnesia/Persistent || error_exit "Sorry, no TAILS persistence found."

PERSISTENT=/home/amnesia/Persistent
INSTALL_DIR=$PERSISTENT/MartusClient-4.4.0
REPO_DIR=$PERSISTENT/Packages/Repo
REPO_FILE=$REPO_DIR/Martus-4.4.zip

if [ ! -d "$INSTALL_DIR" ]
then
        cd $PERSISTENT
	if [ -f "$REPO_FILE" ]
		echo "Using previously saved Martus distribution package ..."
		mv $REPO_FILE $PERSISTENT/
	else
        	echo "Trying to download the Martus package (55 MB)..."
        	wget https://martus.org/installers/Martus-4.4.zip || error_exit "Unable to download Martus 4.4 client. Bailing out."
	fi
	unzip Martus-4.4.zip
	mv Martus-4.4.zip $REPO_DIR/
	echo
	Confirm "Type y if you wish to keep the downloaded/saved distribution file" || rm $REPO_DIR/Martus-4.4.zip
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
Name=Martus Client 4.4
GenericName=Martus
Comment=Secure/encrypted bulletins
Icon=java
Terminal=false
Type=Application
Categories=Network;
Path=/home/amnesia/Persistent/MartusClient-4.4.0
Exec=/home/amnesia/Persistent/MartusClient-4.4.0/run.sh
StartupNotify=true
EOF
	cp -p $desktopdir/martus.desktop /home/amnesia/.local/share/applications/
	echo "Create Java run file ..."
        /bin/cat <<EOF > $INSTALL_DIR/run.sh
#!/bin/bash
#
# This script launches the Martus 4.4.0 Client
#
java -DsocksProxyHost=127.0.0.1 -DsocksProxyPort=9050 -Duser.home=/home/amnesia/
Persistent -jar martus.jar
EOF
	chmod 700 $INSTALL_DIR/run.sh
	/usr/bin/notify-send "Martus Installed" "Open with Applications > Internet > Martus Client 4.4"
	echo
	read -n 1 -p "Martus client has been installed. Press any key to finish up ..."
else
	echo
	read -n 1 -p "Martus client already installed. Press any key to close ..."
fi

