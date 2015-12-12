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
mv $savedsettings/Gnome/panel-default-layout.layout.saved .. >/dev/null 2>&1
mv $savedsettings/Gnome/icons/*.png .. >/dev/null 2>&1
rm -rf Gnome 
chown -R amnesia:amnesia $savedsettings
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
echo "You will be asked whether or not to remove any individual applications"
echo "installed with TAILS Candy and whether to preserve its configuration settings."
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

DOT_DIR=/live/persistence/TailsData_unlocked/dotfiles
PERSISTENT=/home/amnesia/Persistent

echo "Removing start-up hook in ~/.config/autostart/"
rm -f $DOT_DIR/.config/autostart/customisations.desktop 
rm -f /home/amnesia/.config/autostart/customisations.desktop 
echo "Removing deactivation of SSH Gnome Keyring support in ~/.config/autostart/"
rm -f $DOT_DIR/.config/autostart/gnome-keyring-ssh.desktop 
rm -f /home/amnesia/.config/autostart/gnome-keyring-ssh.desktop 

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
	if Confirm "Would you like to remove I2P persistence? " ; then
		sed --in-place '/i2p/d' /live/persistence/TailsData_unlocked/persistence.conf
		chmod 600 /live/persistence/TailsData_unlocked/persistence.conf
		chown tails-persistence-setup:tails-persistence-setup /live/persistence/TailsData_unlocked/persistence.conf
	fi
fi

# Remove persistent Teamviewer settings ?
appdir="/home/amnesia/Packages/Settings/teamviewer10"
if [ -d $appdir ]; then
	echo
	Confirm "Would you like to remove persistent Teamviewer 10 configuration settings " && rm -rf $appdir
fi

# Remove persistent AIDE settings ?
appdir="/home/amnesia/Packages/Settings/aide"
if [ -d $appdir ]; then
	echo
	Confirm "Would you like to remove persistent AIDE configuration settings " && rm -rf $appdir
fi

# Remove persistent Tahoe LAFS settings ?
cd $PERSISTENT/Packages/Settings
cnt=`ls -d tahoe*/ 2>/dev/null | wc -l`
if [ ! "$cnt" = "0" ]; then
	echo
	if Confirm "Would you like to remove Tahoe LAFS and persistent configuration settings? " ; then
		rm -rf $PERSISTENT/Packages/Settings/tahoe* 
		rm -rf $PERSISTENT/Packages/Repo/layered-yaml-attrdict-config >/dev/null 2>&1
		rm -rf $PERSISTENT/lafs-backup-tool >/dev/null 2>&1
	fi
fi

# Removing applications installed by TAILS Candy
cd $PERSISTENT

# Academic Signature
cnt=`ls -d aca_sig*/ 2>/dev/null | wc -l`
if [ "$cnt" = "1" ]; then
appdir=`ls -d aca_sig*/`
	echo
	if Confirm "Would you like to remove the Academic Signature installation? " ; then
		rm -rf $PERSISTENT/$appdir
		rm /live/persistence/TailsData_unlocked/dotfiles/.local/share/applications/aca_sig.desktop
		rm /home/amnesia/.local/share/applications/aca_sig.desktop
	fi
fi

# Dropbox
appdir=$DOT_DIR/.dropbox-dist
if [ -d $appdir ]; then
	echo
	if Confirm "Would you like to remove the Dropbox installation? " ; then
		rm -rf $DOT_DIR/.dropbox*
		rm /live/persistence/TailsData_unlocked/dotfiles/.local/share/applications/dropbox.desktop
		rm /home/amnesia/.local/share/applications/dropbox.desktop
		rm /home/amnesia/Desktop/dropbox.desktop >/dev/null 2>&1
		rm $PERSISTENT/Packages/Repo/dropbox.py >/dev/null 2>&1
		rm $DOT_DIR/bin/dropbox.py >/dev/null 2>&1
		rm $DOT_DIR/bin/dropbox_uploader.sh >/dev/null 2>&1
		rm $PERSISTENT/bin/dropbox.py >/dev/null 2>&1
		rm $PERSISTENT/bin/dropbox_uploader.sh >/dev/null 2>&1
		rm $PERSISTENT/Packages/Settings/Gnome/icons/Dropbox*.png >/dev/null 2>&1
	fi
fi

# Onionshare
appdir=$PERSISTENT/onionshare
if [ -d $appdir ]; then
	appdir="/home/amnesia/Persistent/onionshare /home/amnesia/Persistent/.onionshare_install"
	echo
	Confirm "Would you like to remove the Onionshare installation? " && rm -rf $appdir
fi

# PyBitmessage
appdir=$PERSISTENT/PyBitmessage
if [ -d $appdir ]; then
	echo
	if Confirm "Would you like to remove the PyBitmessage installation? " ; then
		rm -rf $appdir
		rm /live/persistence/TailsData_unlocked/dotfiles/.local/share/applications/bitmessage.desktop
		rm /home/amnesia/.local/share/applications/bitmessage.desktop >/dev/null 2>&1
	fi
fi

# Tor Messenger
appdir=$PERSISTENT/tor-messenger
if [ -d $appdir ]; then
	echo
	if Confirm "Would you like to remove the Tor Messanger (InstantBird) installation? " ; then
		$PERSISTENT/tor-messenger/start-tor-messenger.desktop --unregister-app
		wait
		rm /home/amnesia/.local/share/applications/start-tor-messenger.desktop >/dev/null 2>&1
		rm -rf $appdir
	fi
fi

# Tomb
appdir=$PERSISTENT/Tomb
if [ -d $appdir ]; then
	echo
	Confirm "Would you like to remove the Tomb installation? " && rm -rf $appdir
fi

# Linux Malware Detect
cnt=`ls -d maldetect*/ 2>/dev/null | wc -l`
if [ "$cnt" = "1" ]; then
	appdir=`ls -d maldetect*/`
	echo
	if Confirm "Would you like to remove the Linux Malware Detect installation? " ; then
		maldet="/etc/init.d/maldet"
		if [ -f "$maldet" ]; then
			/etc/init.d/maldet stop
		fi
		rm -rf $PERSISTENT/$appdir
		rm /home/amnesia/.local/share/applications/maldetect.desktop >/dev/null 2>&1
		rm /home/amnesia/Desktop/maldet.desktop >/dev/null 2>&1
		rm $PERSISTENT/Packages/Settings/Gnome/icons/Malware*.png >/dev/null 2>&1
	fi
fi

# Rootkit Hunter
cnt=`ls -d rkhunter*/ 2>/dev/null | wc -l`
if [ "$cnt" = "1" ]; then
	appdir=`ls -d rkhunter*/`
	echo
	if Confirm "Would you like to remove the Rootkit Hunter installation? " ; then
		rm -rf $PERSISTENT/$appdir
	fi
fi
 
# Martus Client
cnt=`ls -d Martus*/ 2>/dev/null | wc -l`
if [ "$cnt" = "1" ]; then
	appdir=`ls -d Martus*/`
	echo
	if Confirm "Would you like to remove the Martus Client installation? " ; then
		rm -rf $PERSISTENT/$appdir
		rm -rf $PERSISTENT/.Martus
		rm /live/persistence/TailsData_unlocked/dotfiles/.local/share/applications/martus.desktop
		rm /home/amnesia/.local/share/applications/martus.desktop
	fi
fi

# Horcrux
appdir=$PERSISTENT/horcrux
if [ -d $appdir ]; then
	echo
	if Confirm "Would you like to remove the Horcrux installation? " ; then
		rm -rf $appdir
		rm -rf /live/persistence/TailsData_unlocked/dotfiles/.horcrux
		rm -rf /home/amnesia/.horcrux
		rm /home/amnesia/.local/share/applications/horcrux.desktop
	fi
fi

# SSSS GUI
appdir=$PERSISTENT/SSSS
if [ -d $appdir ]; then
	echo
	if Confirm "Would you like to remove the SSSS GUI installation? " ; then
		rm -rf $appdir
		rm /live/persistence/TailsData_unlocked/dotfiles/.local/share/applications/SSSS.desktop
		rm /home/amnesia/.local/share/applications/SSSS.desktop
	fi
fi

# Pond
appdir=$PERSISTENT/go/pkg/linux_386/github.com/agl/pond
if [ -d $appdir ]; then
	echo
	if Confirm "Would you like to remove the Pond installation? " ; then
		rm -rf $appdir $PERSISTENT/go/bin/client
		echo "Removing Pond settings from .bashrc ..."
		sed --in-place '/pond/d' $DOT_DIR/.bashrc
	fi
fi

# Paranoia SSE Text & File Encryption
if [ -f "/live/persistence/TailsData_unlocked/dotfiles/bin/pte.jar" ]; then
	echo
	if Confirm "Would you like to remove Paranoia SSE Text & File Encryption? " ; then
		 rm /home/amnesia/bin/pte.jar
		 rm /home/amnesia/bin/ssefenc.jar
		 rm /home/amnesia/bin/ssefencgui.jar
		 rm /live/persistence/TailsData_unlocked/dotfiles/bin/pte.jar
		 rm /live/persistence/TailsData_unlocked/dotfiles/bin/ssefenc.jar
		 rm /live/persistence/TailsData_unlocked/dotfiles/bin/ssefencgui.jar
		 rm /live/persistence/TailsData_unlocked/dotfiles/.local/share/applications/pte.desktop
		 rm /live/persistence/TailsData_unlocked/dotfiles/.local/share/applications/ssefe.desktop
		 rm /home/amnesia/.local/share/applications/pte.desktop
		 rm /home/amnesia/.local/share/applications/ssefe.desktop
		 rm /home/amnesia/Persistent/Packages/Repo/SSEFilePC.zip
		 rm /home/amnesia/Persistent/Packages/Repo/PTE-PC.zip
	fi
fi

# GostCrypt
appdir=$DOT_DIR/.GostCrypt
if [ -f "/live/persistence/TailsData_unlocked/dotfiles/bin/gostcrypt" ]; then
	echo
	if Confirm "Would you like to remove Gostcrypt? " ; then
		 rm -rf $appdir
		 rm /home/amnesia/bin/gostcrypt
		 rm /live/persistence/TailsData_unlocked/dotfiles/bin/gostcrypt
		 rm /live/persistence/TailsData_unlocked/dotfiles/.local/share/applications/gostcrypt.desktop
		 rm /home/amnesia/.local/share/applications/gostcrypt.desktop
		 rm /home/amnesia/Persistent/Packages/Settings/Gnome/icons/GostCrypt*.xpm
		rm -rf /home/amnesia/Persistent/Packages/Repo/GostCrypt_Linux_1.0
	fi
fi

# TrueCrypt
appdir=$DOT_DIR/.TrueCrypt
if [ -d $appdir ]; then
	echo
	Confirm "Would you like to remove previously saved TrueCrypt settings? " && rm -rf $appdir
fi

# Veracrypt
appdir=$DOT_DIR/.VeraCrypt
if [ -d $appdir ]; then
	echo
	Confirm "Would you like to remove previously saved Veracrypt settings? " && rm -rf $appdir
fi

# Zulucrypt
appdir=$DOT_DIR/.zuluCrypt
if [ -d $appdir ]; then
	echo
	Confirm "Would you like to remove previously saved Zulucrypt settings? " && rm -rf $appdir
fi

#
# Remove additional software packages from /live/persistence/TailsData_unlocked/live-additional-software.conf
#

softfile=/live/persistence/TailsData_unlocked/live-additional-software.conf
packages='dirmngr gpgsm claws-mail-smime-plugin pidgin-openpgp signing-party clamtk claws-mail-clamd-plugin filezilla putty mixmaster encfs cryptkeeper pidgin-privacy-please proxychains nmap hfsprogs ed clamav'
for package in $packages
do
	grep -q $package $softfile
	if [ $? -eq 0 ]; then
		echo
		Confirm "Do you wish to remove $package from live-additional-software.conf? " && RemovePackage $package
	fi
done
echo

echo
echo "Removing Packages and TAILSCandy folders in $PERSISTENT ..."
echo
Confirm "Do you wish to save any remaining application configuration settings? " && SaveConfig 
rm -rf $PERSISTENT/Packages $PERSISTENT/TAILSCandy
# Remove uninstall TAILS Candy menu item
rm -f $PERSISTENT/.local/share/applications/uninstall_candy.desktop 
rm -f $PERSISTENT/.local/share/applications/install_candy.desktop 

sudo -u amnesia /usr/bin/notify-send -i package-purge "TAILS Candy succesfully removed" "Reboot for changes to take effect."

