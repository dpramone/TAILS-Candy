#!/bin/bash

#########################################################################
# TAILS OpenSSH upgrade to version 6.6
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

if [[ $EUID -ne 0 ]]; then
    echo "You need to run this as root" 1>&2
    exit 1
fi

# Upgrade OpenSSH CLient 
# 
/usr/bin/apt-get install openssh-client=1:6.6p1-4~bpo70+1
#
modulifile=/home/amnesia/Persistent/Packages/Settings/OpenSSH/moduli.safe
if [ ! -f "$modulifile" ]
then

echo 
echo "Attention: We really should generate an /etc/ssh/moduli file of our own"
echo "********** with strong 4096-bit values instead of the default cr*p."
echo 
echo ssh-keygen -G /etc/ssh/moduli.all -b 4096
echo ssh-keygen -T /etc/ssh/moduli.safe -f /etc/ssh/moduli.all
echo 
echo "Warning: On an old or slow machine, this may take 2 days to complete!"
echo 
        while true; do
        read -p "Do you wish to do this now? y/n" yn
        case $yn in
        [Yy]* )
                echo "Calculating new moduli file with 4096-bit values..."
                ssh-keygen -G /etc/ssh/moduli.all -b 4096
		ssh-keygen -T /etc/ssh/moduli.safe -f /etc/ssh/moduli.all
		cp /etc/ssh/moduli.safe $modulifile
		chown amnesia:amnesia  $modulifile
		cp /etc/ssh/moduli.safe /etc/ssh/moduli
                break;;
        [Nn]* ) break;;
        * ) echo "Please answer (y)es or (n)o.";;
        esac
        done
else
	# Replace default moduli file with self-generated safe 4096bit primes
	cp $modulifile /etc/ssh/moduli
	chmod 644 /etc/ssh/moduli
fi

/usr/bin/sudo -u amnesia /usr/bin/notify-send -i gnome-app-install "OpenSSH Upgraded" "OpenSSH Client upgraded to version 6.6 Wheezy bpo"
