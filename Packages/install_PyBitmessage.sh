#!/bin/bash

#########################################################################
# TAILS installer script for PyBitmessage
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
  
# Install PyBitmessage
# 

instpbm(){

	/bin/echo "Installing PyBitmessage in $PKG_DIR ..."
	confdir=/live/persistence/TailsData_unlocked/dotfiles/.config/PyBitmessage
	if [ ! -d "$confdir" ]; then
		mkdir -p $confdir
		ln -s /home/amnesia/.config/PyBitMessage
	fi

	if [ ! -f /live/persistence/TailsData_unlocked/dotfiles/.config/PyBitmessage/keys.dat ]
	then
		/bin/cat <<EOT > /live/persistence/TailsData_unlocked/dotfiles/.config/PyBitmessage/keys.dat
settingsversion = 10
port = 8444
timeformat = %%c
blackwhitelist = black
startonlogon = False
minimizetotray = False
showtraynotifications = True
startintray = False
socksproxytype = SOCKS5
sockshostname = 127.0.0.1
socksport = 9050
socksauthentication = False
sockslisten = False
socksusername = 
sockspassword = 
keysencrypted = false
messagesencrypted = false
defaultnoncetrialsperbyte = 1000
defaultpayloadlengthextrabytes = 1000
minimizeonclose = false
maxacceptablenoncetrialsperbyte = 20000000000
maxacceptablepayloadlengthextrabytes = 20000000000
dontconnect = true
userlocale = system
useidenticons = True
identiconsuffix = Y9998KPVEg78
replybelow = False
maxdownloadrate = 0
maxuploadrate = 0
ttl = 367200
stopresendingafterxdays = 
stopresendingafterxmonths = 
namecoinrpctype = nmcontrol
namecoinrpchost = localhost
namecoinrpcuser = 
namecoinrpcpassword = 
namecoinrpcport = 9000
sendoutgoingconnections = True
onionhostname = 
onionport = 8444
onionbindip = 127.0.0.1
smtpdeliver = 
trayonclose = False
willinglysendtomobile = False
EOT
	fi

	echo
	echo "Creating file to autostart Bitmessage with Tor"
	echo
	appdir=/live/persistence/TailsData_unlocked/dotfiles/.config/autostart
	if [ ! -d "$appdir" ]
	then
		mkdir -p $appdir
	fi
	/bin/cat <<EOT > $appdir/bitmessage_autostart.desktop
[Desktop Entry]
Name=Bitmessage
Type=Application
Terminal=false
Exec=bash -c "until sudo -n -u debian-tor /usr/local/sbin/tor-has-bootstrapped ;
 do sleep 5 ; done ; cd /home/amnesia/Persistent/PyBitmessage/ ; python2 src/bitmessagemain.py"
Icon=/home/amnesia/Persistent/PyBitmessage/desktop/icon24.png
Comment[en_US.UTF-8]=Anonymous P2P Messenger
Hidden=true
EOT
	chmod 700 $appdir/bitmessage_autostart.desktop

	/bin/echo " "
#	while true; do
#        read -p "Do you wish to replace Icedove in the Gnome top panel with Bitmessage? y/n" yesno
#        case $yesno in
#        [Yy]* )
#                /bin/echo " "
#		/bin/echo "Creating file to replace Icedove with Bitmessage in Gnome top panel"
#		/bin/echo " "
#		appdir=/live/persistence/TailsData_unlocked/dotfiles/.config/gnome-panel
#		if [ ! -d "$appdir" ]
#		then
#			mkdir -p $appdir
#		fi
#		/bin/cat <<EOT > $appdir/bitmessage.desktop
#[Desktop Entry]
#Name=Bitmessage
#Type=Application
#Terminal=false
#Exec=bash -c "cd /home/amnesia/Persistent/PyBitmessage/ ; ./src/bitmessagemain.py"
#Icon=/home/amnesia/Persistent/PyBitmessage/desktop/icon24.png
#Comment[en_US.UTF-8]=Anonymous P2P Messenger
#EOT
#		chmod 700 $appdir/bitmessage.desktop
#		cp /home/amnesia/.config/gnome-panel/panel-default-layout.layout $appdir/
#		sed -i "s|\[Object claws-launcher\]|\[Object bitmessage-launcher\]|g" $appdir/panel-default-layout.layout
#		sed -i "s|@instance-config/location='/usr/share/applications/claws-mail\.desktop'|@instance-config/location='/live/persistence/TailsData_unlocked/dotfiles/\.config/gnome-panel/bitmessage\.desktop'|g" $appdir/panel-default-layout.layout
#                break
#                ;;
#        [Nn]* ) break;;
#        * ) echo "Please answer (y)es or (n)o.";;
#        esac
#        done

	# Create Gnome menu item
	#
	/bin/echo "Creating Gnome menu item "
	appdir=/live/persistence/TailsData_unlocked/dotfiles/.local/share/applications
	if [ ! -d "$appdir" ]
	then
		mkdir -p $appdir
	fi
	/bin/cat <<EOF > /live/persistence/TailsData_unlocked/dotfiles/.local/share/applications/bitmessage.desktop
[Desktop Entry]
Version=1.0
Name=Bitmessage
Type=Application
Terminal=false
Path=/home/amnesia/Persistent/PyBitmessage
Exec=python2 /home/amnesia/Persistent/PyBitmessage/src/bitmessagemain.py
Icon=evolution-mail
Comment=Anonymous P2P Messenger
Comment[en_US.UTF-8]=Anonymous P2P Messenger
Categories=Network;
EOF

}

instpbmx(){

	/bin/echo "Installing PyBitmessage + Mixmaster in $PKG_DIR ..."
	$PKG_DIR/bitmix_tailsinstaller.sh
	# Disable autostart in desktop file created by bitmix_tailsinstaller.sh?
	while true; do
	read -p "Do you wish to autostart PyBitmessage at login time? y/n" yesno
	case $yesno in
	[Nn]* ) 
		/bin/echo " "
		/bin/echo 'X-GNOME-Autostart-enabled=false' >> /live/persistence/TailsData_unlocked/dotfiles/.config/autostart/bitmessage_autostart.desktop
		break
		;;
	[Yy]* ) break;;
	* ) echo "Please answer (y)es or (n)o.";;
	esac
	done
	# 	Create Gnome menu item
	#
	appdir=/live/persistence/TailsData_unlocked/dotfiles/.local/share/applications
	if [ ! -d "$appdir" ]
	then
		mkdir -p $appdir
	fi
	/bin/cat <<EOF > /live/persistence/TailsData_unlocked/dotfiles/.local/share/applications/bitmessage.desktop
[Desktop Entry]
Version=1.0
Name=Bitmessage
Type=Application
Terminal=false
Exec=bash -c "until sudo -n -u debian-tor /usr/local/sbin/tor-has-bootstrapped ; do sleep 5 ; done ; cd /home/amnesia/Persistent/PyBitmessage/ ; /usr/bin/torsocks /usr/bin/mixmaster-update & ./src/bitmessagemain.py"
Icon=evolution-mail
Comment=Anonymous P2P Messenger
Comment[en_US.UTF-8]=Anonymous P2P Messenger
Categories=Network;
EOF
}

clear
echo "*************************************************"
echo "Bitmessage & (optional) Mixmaster TAILS Installer"
echo "*************************************************"
echo "Permanently installs Bitmessage in ~/Persistent/PyBitmessage"
echo "Source: https://github.com/Bitmessage/PyBitmessage "
echo 
echo "Requirements: You must have enabled TAILS persistence with dotfiles. If not, we will exit gracefully."
echo 
echo "If ~/Persistent/PyBitmessage already exists, we will not reinstall but try to update from Github (git pull) instead." 
echo 
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."
echo

PERSISTENT=/home/amnesia/Persistent
PKG_DIR=$PERSISTENT/PyBitmessage
REPO_DIR=$PERSISTENT/Packages/Repo

# This script should not be run as root
if [[ $EUID -eq 0 ]]; then
        echo
        error_exit "Please do not run this script with sudo or as root"
fi

# Exit if no TAILS persistence
cd /live/persistence/TailsData_unlocked/dotfiles || error_exit "No TAILS persistence found. Bailing out..."

if [ -d "$PKG_DIR" ]
then
	echo "Trying PyBitmessage update from Github ..."
	cd $PKG_DIR
	git pull
	read -n 1 -p "Press any key to continue..."
	
else
	rm /live/persistence/TailsData_unlocked/dotfiles/.local/share/applications/bitmessage.desktop 2>/dev/null >/dev/null
	rm /home/amnesia/.local/share/applications/bitmessage.desktop 2>/dev/null >/dev/null
        while true; do
        read -p "Install PyBitmessage with (y) or without (n) Mixmaster support ? " yn
        case $yn in
        [Yy]* )
                echo "Downloading PyBitmessage + Mixmaster installer..."
		mkdir $PKG_DIR
		wget -O $PKG_DIR/bitmix_tailsinstaller.sh https://raw.githubusercontent.com/p2pmessage/PyBitmessage/p2pmessage/bitmix_tailsinstaller.sh || error_exit "Sorry, we were unable to fetch the BitMix TAILS installer script" 
		wait
		chmod 700 $PKG_DIR/bitmix_tailsinstaller.sh
		# Check for presence of mixmaster
		dpkg -s mixmaster 2>/dev/null >/dev/null || sudo apt-get -y install mixmaster
		echo
		read -n 1 -p "ATTENTION: Re-install Mixmaster at every reboot or make it persistent! Press any key to continue..."
		echo
		instpbmx
		break
                ;;
        [Nn]* ) 
		echo "Downloading original PyBitmessage from Github ..."
		mkdir $PKG_DIR
		git clone https://github.com/Bitmessage/PyBitmessage $PKG_DIR || error_exit "Sorry, we were unable to download PyBitmessage" 
		instpbm

		echo "installing namecoind ..."
		# Do we already have a copy of the SilentEye .deb installation file?
		cd $REPO_DIR
		cnt=`ls namecoin_0.3*_i386.deb 2>/dev/null | wc -l`
		if [ "$cnt" = "0" ]; then
		wget -O namecoin_0.3.80-3_i386.deb http://download.opensuse.org/repositories/home:/p_conrad:/coins/Debian_8.0/i386/namecoin_0.3.80-3_i386.deb || break
		wait
		chown amnesia:amnesia $REPO_DIR/namecoin_0.3*_i386.deb
		fi

		sudo apt-get install libboost-program-options1.55.0
		sudo dpkg -i namecoin_0.3.80-3_i386.deb
		echo
		Confirm "Type y if you wish to keep the downloaded/saved distribution file" || rm $REPO_DIR/namecoin_0.3.*_i386.deb
		echo

		break
		;;
        * ) echo "Please answer (y)es or (n)o.";;
        esac
        done

	cp /live/persistence/TailsData_unlocked/dotfiles/.local/share/applications/bitmessage.desktop /home/amnesia/.local/share/applications/bitmessage.desktop

	/usr/bin/notify-send -i /home/amnesia/Persistent/PyBitmessage/desktop/icon24.png "PyBitmessage Installed" "Open with Applications > Internet > Bitmessage"
fi

