#!/bin/bash
#########################################################################
# TAILS Candy removal script
#
# This script removes the TAILS Candy package
#
# Part of "TAILS Candy" Project
# Version 0.1a
# License: GPL v3 - Copy included in distribution package
#
# By Dirk Praet - skylord@jedi.be
#########################################################################

# Function declarations
# #####################

function error_exit
{
        echo "$1" 1>&2
        exit 1
}

Confirm() { read -sn 1 -p "$* [Y/N]? "; [[ ${REPLY:0:1} = [Yy] ]]; }

SaveConfig()
{
savedsettings=$PERSISTENT/TAILS_Candy_Saved_Settings
mv $PERSISTENT/Packages/Settings $savedsettings
cd $savedsettings
mv $savedsettings/Gnome/panel-default-layout.layout.saved .. 1>&2
rm -rf Gnome 1>&2
echo "Settings saved in $savedsettings"
echo
cd -
}

RemovePackage()
{
grep -vFf <(echo "$1") $softfile > /tmp/brol
mv /tmp/brol $softfile
chmod 600 $softfile
chown tails-persistence-setup:tails-persistence-setup $softfile
}

RemoveI2P()
{
grep -vFf <(echo "/var/lib/i2p source=i2p") /live/persistence/TailsData_unlocked/persistence.conf > /tmp/brol
chmod 600 /live/persistence/TailsData_unlocked/persistence.conf
chown tails-persistence-setup:tails-persistence-setup /live/persistence/TailsData_unlocked/persistence.conf
}

####################
# Script main line #
####################

if [[ $EUID -ne 0 ]]; then
    echo "You need to run this script as root, i.e. sudo ./remove_candy.sh ." 1>&2
    exit 1
fi

clear
echo 
echo "This script will remove the TAILS Candy package."
echo 
echo "Packages you have installed with TAILS Candy will be preserved and"
echo "you can choose to keep their configuration settings."
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

DOT_DIR=/live/persistence/TailsData_unlocked/dotfiles
PERSISTENT=/home/amnesia/Persistent

echo
echo "Removing Packages and TAILSCandy folders in $PERSISTENT ..."
echo
Confirm "Do you wish to save application configuration settings? y/n" && SaveConfig 
rm -rf $PERSISTENT/Packages $PERSISTENT/TAILSCandy

echo "Removing start-up hook in ~/.config/autostart/"
rm -f $DOT_DIR/.config/autostart/customisations.desktop 1>&2
rm -f /home/amnesia/.config/autostart/customisations.desktop 1>&2
echo "Removing deactivation of SSH Gnome Keyring support in ~/.config/autostart/"
rm -f $DOT_DIR/.config/autostart/gnome-keyring-ssh.desktop 1>&2
rm -f /home/amnesia/.config/autostart/gnome-keyring-ssh.desktop 1>&2

echo "Leaving GnuPG SSH support in ~/.bashrc ..."
echo "Leaving SSH support in ~/.gnupg/gpg-agent.conf ..."
echo "Leaving Gnome menu customisations in ~/.config/menus to preserve Encryption submenu ..."

echo "Removing TAILS Candy folder from desktop ..."
rm -f /home/amnesia/Desktop/TAILS_Candy.desktop

echo
grep -q "Packages" /live/persistence/TailsData_unlocked/dotfiles/.config/gnome-panel/panel-default-layout.layout
if [ $? -eq 0 ]; then
echo "Removing custom TAILS Candy Gnome top panel..."
rm -f /live/persistence/TailsData_unlocked/dotfiles/.config/gnome-panel/panel-default-layout.layout
fi 

#
# Remove I2P persistence?
#
grep -q "I2P" /live/persistence/TailsData_unlocked/persistence.conf
if [ $? -eq 0 ]; then
echo
Confirm "Would you like to remove I2P persistence? " && RemoveI2P
fi

#
# Remove additional software packages from /live/persistence/TailsData_unlocked/live-additional-software.conf
#

softfile=/live/persistence/TailsData_unlocked/live-additional-software.conf
packages='dirmngr gpgsm claws-mail-smime-plugin pidgin-openpgp signing-party clamtk claws-mail-clamd-plugin filezilla putty mixmaster encfs cryptkeeper pidgin-privacy-please proxychains nmap hfsprogs'
for package in $packages
do
	grep -q $package $softfile
	if [ $? -eq 0 ]; then
		echo
		Confirm "Do you wish to remove $package from live-additional-software.conf? " && RemovePackage $package
	fi
done
echo

sudo -u amnesia /usr/bin/notify-send "TAILS Candy succesfully removed" "Reboot for changes to take effect."

