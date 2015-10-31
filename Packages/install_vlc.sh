#!/bin/bash

#########################################################################
# TAILS installer script for VLC Media Player
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
if [[ $EUID -ne 0 ]]; then
    echo "You need to run this as root" 1>&2
    exit 1
fi

echo " "
echo "This routine non-persistenly installs VLC and removes Totem Player"
echo "VLC just plays way more different media types."
echo "At some point, we will add a VLC apparmor profile for better containment."
echo "Source: https://www.videolan.org "
echo 
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."
echo

# Remove Totem player
echo "Removing Totem multimedia player..."
sudo apt-get remove totem totem-common gir1.2-totem-1.0 gir1.2-totem-plparser-1.0 totem-plugins
# /usr/bin/apt-get remove libepc-1.0-3 libepc-common libepc-ui-1.0-3 libgdata-common libgdata13 liboauth0 libtotem0 python-beautifulsoup python-chardet python-feedparser python-httplib2

# Install VLC & dependencies
# We're doing it in this order for mimetypes and stuff to get registered correctly
echo "Now installing VLC & dependencies ..."
/usr/bin/apt-get -y install vlc=2.1.5-1~bpo70+1 vlc-nox=2.1.5-1~bpo70+1 vlc-data=2.1.5-1~bpo70+1 libvlccore7=2.1.5-1~bpo70+1 libvlc5=2.1.5-1~bpo70+1 libavcodec-extra-55=6:10.1-1~bpo70+1 libavformat55=6:10.1-1~bpo70+1 libswscale2=6:10.1-1~bpo70+1 libopus0=1.1-1~bpo70+1 libgnutls-deb0-28=3.3.8-6~bpo70+1 libhogweed2=2.7.1-1~bpo70+1 libnettle4=2.7.1-1~bpo70+1 libp11-kit0=0.20.7-1~bpo70+1

/usr/bin/sudo -u amnesia /usr/bin/notify-send "Totem Player Removed & VLC Installed" "Open with Applications > Sound & Video > VLC"
