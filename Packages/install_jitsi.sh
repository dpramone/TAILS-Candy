#!/bin/bash

#########################################################################
# TAILS installer script for Jitsi 2.8 -SIP Communicator
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

# Main line

if [[ $EUID -eq 0 ]]; then
    echo "Please do not this script as root" 1>&2
    exit 1
fi

clear
echo 
echo "This routine will non-persistently install Jitsi 2.8 Communicator"
echo "You need to run it again after each TAILS reboot. You configuration"
echo "settings are preserved."
echo 
echo "Source: http://www.jitsi.org/"
echo 
read -n 1 -p "Press any key to continue or Ctrl-C to abort..."
echo 

PERSISTENT=/home/amnesia/Persistent
REPO_DIR=$PERSISTENT/Packages/Repo

# Do we already have a copy of the Jitsi .deb installation file?
cd $REPO_DIR
cnt=`ls jitsi*_i386.deb 2>/dev/null | wc -l`
if [ "$cnt" = "0" ]; then
	wget -O jitsi_2.8.5426-1_i386.deb https://download.jitsi.org/jitsi/debian/jitsi_2.8.5426-1_i386.deb || error_exit "Sorry, unable to download Jitsi. Bailing out."
	wait
	chown amnesia:amnesia $REPO_DIR/jitsi*_i386.deb
else
	echo "Jitsi distribution file found in $REPO_DIR ."
	echo
fi

sudo /usr/bin/dpkg -i $REPO_DIR/jitsi*_i386.deb || error_exit "Jitsi installation failed!" 

#
# Check for existence of previous .jitsi config directory in persistent volume (dotfiles)
#
confdir=/live/persistence/TailsData_unlocked/dotfiles/.jitsi
if [ ! -d "$confdir" ]
then
        # Create .jitsi config directory & symlink
        mkdir $confdir
        chmod 700 $confdir
        ln -s $confdir /home/amnesia/.jitsi 2>/dev/null
	touch /home/amnesia/.jitsi/sip-communicator.properties 2>/dev/null
	chmod 600 /home/amnesia/.jitsi/sip-communicator.properties
fi

#desktopdir="/home/amnesia/.local/share/applications/"
#if [ ! -d "$desktopdir" ]; then
#        mkdir -p $desktopdir
#fi
#/bin/cat <<EOF > $desktopdir/jitsi.desktop
#!/usr/bin/env xdg-open
#[Desktop Entry]
#Version=1.0
#Encoding=UTF-8
#Name=Jitsi
#GenericName=Jitsi
#Comment=VoIP and Instant Messaging client
#Keywords=chat;messaging;im;voip;video;call;conference;
#Icon=/usr/share/pixmaps/jitsi.svg
#Type=Application
#Categories=Network;InstantMessaging;Chat;Telephony;VideoConference;Java;
#Exec=torsocks jitsi
#Terminal=false
#EOF

echo
echo "All done."

echo
Confirm "Type y if you wish to keep the downloaded/saved distribution file" || rm $REPO_DIR/jitsi*_i386.deb
echo

/usr/bin/notify-send -i jitsi "Jitsi Installed" "Open with Applications > Internet > Jitsi"

echo
Confirm "Press y to launch Jitsi now or n to finish up..." || exit 0
/usr/bin/jitsi &
