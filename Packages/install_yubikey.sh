#!/bin/bash

#########################################################################
# TAILS installer script for Yubikey Personalization Manager
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

# Script main line
if [[ $EUID -ne 0 ]]; then
    echo "You need to run this as root. sudo ./install_yubikey.sh" 1>&2
    exit 1
fi

clear
echo "This routine non-persistently installs Yubikey Personalization Manager"
echo "GUI from standard Debian package(s)."
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

# This can also be done from Synaptic but I like it better like this
clear
/usr/bin/apt-get install yubikey-personalization-gui opensc
echo
echo "Creating 70-yubikey.rules in /etc/udev/rules.d ..."
/bin/cat <<EOT > /etc/udev/rules.d/70-yubikey.rules
ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="1050", ATTR{idProduct}=="0010|0110|0111|0114|0116|0401|0403|0405|0407|0410", OWNER="amnesia", TAG+="uaccess"
EOT
udevadm control --reload-rules

/usr/bin/sudo -u amnesia /usr/bin/notify-send "Yubikey Personalization GUI Installed" "Launch with Accessories - Yubikey Personalization Tool"

read -n 1 -p "Press any key to launch Yubikey PM now or Ctrl-C to finish up..."
sudo -u amnesia /usr/bin/yubikey-personalization-gui &

