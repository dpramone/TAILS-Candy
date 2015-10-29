#!/bin/bash

#########################################################################
# TAILS installer script for PyBitmessage
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

# Script main line
  
# Install PyBitmessage
# 

instpbm(){

	/bin/echo "Installing PyBitmessage in $PKG_DIR ..."
	if [ ! -f /home/amnesia/Persistent/PyBitmessage/keys.dat ]
	then
		/bin/cat <<EOT >> /home/amnesia/Persistent/PyBitmessage/keys.dat
[bitmessagesettings]
settingsversion = 10
port = 8444
timeformat = %%a, %%d %%b %%Y  %%I:%%M %%p
blackwhitelist = black
startonlogon = False
minimizetotray = False
showtraynotifications = True
startintray = False
socksproxytype = SOCKS5
sockshostname = localhost
socksport = 9150
socksauthentication = True
sockslisten = False
socksusername = bitmessage
sockspassword = bitmessage
keysencrypted = false
messagesencrypted = false
defaultnoncetrialsperbyte = 1000
defaultpayloadlengthextrabytes = 1000
minimizeonclose = false
maxacceptablenoncetrialsperbyte = 0
maxacceptablepayloadlengthextrabytes = 0
userlocale = system
useidenticons = True
identiconsuffix = PV7e9irDHhsy
replybelow = False
stopresendingafterxdays = 
stopresendingafterxmonths = 
namecoinrpctype = namecoind
namecoinrpchost = localhost
namecoinrpcuser = 
namecoinrpcpassword = 
namecoinrpcport = 8336
sendoutgoingconnections = True
maxdownloadrate = 0
maxuploadrate = 0
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
 do sleep 5 ; done ; cd /home/amnesia/Persistent/PyBitmessage/ ; ./src/bitmessagemain.py"
Icon=/home/amnesia/Persistent/PyBitmessage/desktop/icon24.png
Comment[en_US.UTF-8]=Anonymous P2P Messenger
EOT
	chmod 700 $appdir/bitmessage_autostart.desktop

	/bin/echo " "
	while true; do
        read -p "Do you wish to replace Claws Mail in the Gnome top panel with Bitmessage? y/n" yesno
        case $yesno in
        [Yy]* )
                /bin/echo " "
		/bin/echo "Creating file to replace Claws Mail with Bitmessage in Gnome top panel"
		/bin/echo " "
		appdir=/live/persistence/TailsData_unlocked/dotfiles/.config/gnome-panel
		if [ ! -d "$appdir" ]
		then
			mkdir -p $appdir
		fi
		/bin/cat <<EOT > $appdir/bitmessage.desktop
[Desktop Entry]
Name=Bitmessage
Type=Application
Terminal=false
Exec=bash -c "cd /home/amnesia/Persistent/PyBitmessage/ ; ./src/bitmessagemain.py"
Icon=/home/amnesia/Persistent/PyBitmessage/desktop/icon24.png
Comment[en_US.UTF-8]=Anonymous P2P Messenger
EOT
		chmod 700 $appdir/bitmessage.desktop
		cp /home/amnesia/.config/gnome-panel/panel-default-layout.layout $appdir/
		sed -i "s|\[Object claws-launcher\]|\[Object bitmessage-launcher\]|g" $appdir/panel-default-layout.layout
		sed -i "s|@instance-config/location='/usr/share/applications/claws-mail\.desktop'|@instance-config/location='/live/persistence/TailsData_unlocked/dotfiles/\.config/gnome-panel/bitmessage\.desktop'|g" $appdir/panel-default-layout.layout
                break
                ;;
        [Nn]* ) break;;
        * ) echo "Please answer (y)es or (n)o.";;
        esac
        done

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
Exec=bash -c "until sudo -n -u debian-tor /usr/local/sbin/tor-has-bootstrapped ; do sleep 5 ; done ; cd /home/amnesia/Persistent/PyBitmessage/ ; ./src/bitmessagemain.py"
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
read -n 1 -p "Press any key to continue ..."
echo

PERSISTENT=/home/amnesia/Persistent
PKG_DIR=$PERSISTENT/PyBitmessage

# Exit if no TAILS persistence
cd /live/persistence/TailsData_unlocked/dotfiles || exit

if [ -d "$PKG_DIR" ]
then
	echo "Trying PyBitmessage update from Github ..."
	cd $PKG_DIR
	git pull
	read -n 1 -p "Press any key to continue..."
	
else
        while true; do
        read -p "Install PyBitmessage with (y) or without (n) Mixmaster support ?" yn
        case $yn in
        [Yy]* )
                echo "Downloading PyBitmessage + Mixmaster installer..."
		mkdir $PKG_DIR
		wget -O $PKG_DIR/bitmix_tailsinstaller.sh https://raw.githubusercontent.com/p2pmessage/PyBitmessage/p2pmessage/bitmix_tailsinstaller.sh || error_exit "Sorry, we were unable to fetch the BitMix TAILS installer script" 
		wait
		chmod 700 $PKG_DIR/bitmix_tailsinstaller.sh
		instpbmx
		break
                ;;
        [Nn]* ) 
		echo "Downloading original PyBitmessage from Github ..."
		mkdir $PKG_DIR
		git clone https://github.com/Bitmessage/PyBitmessage $PKG_DIR || error_exit "Sorry, we were unable to download PyBitmessage" 
		inst_pbm
		break
		;;
        * ) echo "Please answer (y)es or (n)o.";;
        esac
        done

	cp /live/persistence/TailsData_unlocked/dotfiles/.local/share/applications/bitmessage.desktop /home/amnesia/.local/share/applications/bitmessage.desktop
	/usr/bin/sudo -u amnesia /usr/bin/notify-send "PyBitmessage Installed" "Open with Applications > Internet > Bitmessage"
fi

