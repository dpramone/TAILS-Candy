#!/bin/bash

#########################################################################
# TAILS installer script for Muble 1.2.3
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
if [[ $EUID -eq 0 ]]; then
    echo "Please do not run this installer as root" 1>&2
    exit 1
fi

echo " "
echo "This routine non-persistenly installs the Mumble 1.2.3 VOIP Client"
echo "You need to run it again after each TAILS reboot. Configuration settings"
echo "are preserved in ~/.config/Mumble ."
echo 
echo "CAVEAT: Always run Mumble over TorSocks!"
echo 
echo "Source: http://www.mumble.com"
echo 
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."
echo

# Install Mumble & dependencies
# 
echo "Now installing Mumble & dependencies ..."
sudo /usr/bin/apt-get -y install mumble=1.2.3-349-g315b5f5-2.2+deb7u2 libavahi-compat-libdnssd1 libg15-1 libg15daemon-client1 libg15render1 libprotobuf7 libqt4-sql-sqlite lsb-release

confdir=/live/persistence/TailsData_unlocked/dotfiles/.config/Mumble
if [ ! -d "$confdir" ]
then
        # Create ~/.config/Mumble config directory & symlink
        mkdir -p $confdir
        chmod 700 $confdir
        ln -s $confdir /home/amnesia/.config/Mumble 2>/dev/null
fi

desktopdir="/home/amnesia/.local/share/applications/"
if [ ! -d "$desktopdir" ]; then
	mkdir -p $desktopdir
fi
/bin/cat <<EOF > $desktopdir/mumble.desktop
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=Mumble
GenericName=Voice Chat
Comment=A low-latency, high quality voice chat program for gaming
Exec=torsocks mumble
Icon=mumble
Terminal=false
Type=Application
StartupNotify=false
Categories=Network;Chat;Qt;
EOF

echo "All done."

/usr/bin/notify-send -i mumble "Mumble Installed" "Open with Applications > Internet > Mumble"

echo 
Confirm "Press y to launch Mumble now or n to finish up ..." || exit 0
/usr/bin/torsocks /usr/bin/mumble &

