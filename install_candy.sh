#!/bin/bash
#########################################################################
# TAILS Candy installer script
#
# This script installs the TAILS Candy package
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

function modify_toppanel
{
	echo "Replacing default TAILS Gnome top panel..."
	layoutfile="/live/persistence/TailsData_unlocked/dotfiles/.config/gnome-panel/panel-default-layout.layout"
	layoutfile2="/home/amnesia/.config/gnome-panel/panel-default-layout.layout"
	layoutsave=$PERSISTENT/Packages/Settings/Gnome/panel-default-layout.layout.saved
	if [ -f "$layoutfile" ]; then
		sudo -u amnesia cp -p $layoutfile $layoutsave
	else
	if [ -f "$layoutfile2" ]; then
		sudo -u amnesia cp -p $layoutfile2 $layoutsave
	fi
	fi
	sudo -u amnesia cp -p $PERSISTENT/Packages/Settings/Gnome/panel-default-layout.layout $layoutfile
	if [ -f "$layoutsave" ]; then
		echo "Original panel layout saved as $layoutsave"
	fi
}

I2PPersistence()
{
grep -q "I2P" /live/persistence/TailsData_unlocked/persistence.conf
if [ ! $? -eq 0 ]; then
echo "/var/lib/i2p source=i2p" >> /live/persistence/TailsData_unlocked/persistence.conf
fi
}

Confirm() { read -sn 1 -p "$* [Y/N]? "; [[ ${REPLY:0:1} = [Yy] ]]; }

####################
# Script main line #
####################

if [[ $EUID -ne 0 ]]; then
    echo "You need to run this installer as root, i.e. sudo ./install_candy.sh ." 1>&2
    exit 1
fi

clear
echo 
echo "This routine will guide you through the installation of the"
echo "TAILS Candy package."
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

DOT_DIR=/live/persistence/TailsData_unlocked/dotfiles
CUR_DIR=$PWD
PERSISTENT=/home/amnesia/Persistent

cd $DOT_DIR || error_exit "No TAILS Dotfiles persistence found. Aborting"

echo
echo "Installing Packages and TAILSCandy folders in $PERSISTENT ..."
folder=$CURDIR/Packages
if [ -d "$folder" ]
then
	chown -R amnesia:amnesia $folder
	cp -rp $folder $PERSISTENT/
	chmod 700 $PERSISTENT/$folder/*.sh
else
	error_exit "Where is our Packages folder? Installation aborted."
fi
folder=$CURDIR/TAILSCandy
if [ -d "$folder" ]
then
	chown -R amnesia:amnesia $folder
	cp -rp $folder $PERSISTENT/
else
	error_exit "Where is our TAILSCandy folder? Installation aborted."
fi

# Add persistent start-up hook in ~/.config/autostart/
#
startdir="/live/persistence/TailsData_unlocked/dotfiles/.config/autostart/"
if [ ! -d "$startdir" ]; then
sudo -u amnesia mkdir -p $startdir
fi
sudo -u amnesia cat <<EOF > /live/persistence/TailsData_unlocked/dotfiles/.config/autostart/customisations.desktop
[Desktop Entry]
Name=Customisations
GenericName=Customisations
Comment=Customisations hook
Exec=/home/amnesia/Persistent/Packages/Customisations.sh
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true 
EOF
chown amnesia:amnesia $startdir/customisations.desktop
chmod 600 $startdir/customisations.desktop
sudo -u amnesia ln -sf $startdir/customisations.desktop /home/amnesia/.config/autostart/customisations.desktop

#
# Disable default TAILS SSH support in Gnome Keyring daemon.
# It totally sucks, doesn't support ECC keys and normal people should
# be using the GnuPG agent anyway.
#
echo "Disabling Gnome Keyring SSH support so we can use the GPG agent ..."
sudo -u amnesia cat <<EOF > /live/persistence/TailsData_unlocked/dotfiles/.config/autostart/gnome-keyring-ssh.desktop
[Desktop Entry]
Type=Application
Name=SSH Key Agent
Name[en_GB]=SSH Key Agent
Comment=GNOME Keyring: SSH Agent
Comment[en_GB]=GNOME Keyring: SSH Agent
Exec=/usr/bin/gnome-keyring-daemon --start --components=ssh
OnlyShowIn=GNOME;Unity;
X-GNOME-Autostart-Phase=Initialization
X-GNOME-AutoRestart=false
X-GNOME-Autostart-Notify=true
X-GNOME-Bugzilla-Bugzilla=GNOME
X-GNOME-Bugzilla-Product=gnome-keyring
X-GNOME-Bugzilla-Component=general
X-GNOME-Bugzilla-Version=3.4.1
X-GNOME-Autostart-enabled=false
EOF

chown amnesia:amnesia $startdir/gnome-keyring-ssh.desktop
chmod 600 $startdir/gnome-keyring-ssh.desktop
sudo -u amnesia ln -sf $startdir/gnome-keyring-ssh.desktop /home/amnesia/.config/autostart/gnome-keyring-ssh.desktop 1>&2

echo "Checking .bashrc for GnuPG SSH support ..."
grep -q "GPG_TTY" /home/amnesia/.bashrc
if [ ! $? -eq 0 ]; then
	sudo -u amnesia cat <<EOF >> /home/amnesia/.bashrc
# 
# GnuPG SSH support
# 
GPG_TTY=$(tty)
export GPG_TTY
EOF
bashrc=/live/persistence/TailsData_unlocked/dotfiles/.bashrc
# Make .bashrc persistent by copying over to Dotfiles directory
if [ ! -f "$bashrc"]; then
	sudo -u amnesia cp -p /home/amnesia/.bashrc $bashrc
fi
fi

gpgagent="/home/amnesia/.gnupg/gpg-agent.conf"
grep -q "enable-ssh-support" $gpgagent
if [ ! $? -eq 0 ]; then
	sudo -u amnesia echo "enable-ssh-support" >> $gpgagent
fi

#
# Modify Gnome menu/directory entries with TAILS Candy entries
#
echo "Creating a Gnome menu Encryption application group item"
sudo -u amnesia cp -rp $PERSISTENT/Packages/Settings/Gnome/menus /live/persistence/TailsData_unlocked/dotfiles/.config/ 1>&2
dtdir=/live/persistence/TailsData_unlocked/dotfiles/.local/share/desktop-directories
if [ ! -d "$dtdir" ]; then
mkdir -p $dtdir
fi
sudo -u amnesia cp -p $PERSISTENT/Packages/Settings/Gnome/Encryption.directory $dtdir/Encryption.directory 1>&2

#
# Disable vulnerable DHE & RC4-ciphers in Firefox/Tor Browser
#
echo "Disabling weak ciphers in Tor Browser default profile ..."
echo "You need to restart your Tor browser for these changes to take"
echo "effect in this TAILS session."
echo 'user_pref("security.ssl3.dhe_rsa_aes_128_sha", false);' >> /home/amnesia/.tor-browser/profile.default/prefs.js
echo 'user_pref("security.ssl3.dhe_rsa_aes_256_sha", false);' >> /home/amnesia/.tor-browser/profile.default/prefs.js
echo 'user_pref("security.ssl3.ecdhe_ecdsa_rc4_128_sha", false);' >> /home/amnesia/.tor-browser/profile.default/prefs.js
echo 'user_pref("security.ssl3.ecdhe_rsa_rc4_128_sha", false);' >> /home/amnesia/.tor-browser/profile.default/prefs.js
echo 'user_pref("security.ssl3.rsa_rc4_128_md5", false);' >> /home/amnesia/.tor-browser/profile.default/prefs.js
echo 'user_pref("security.ssl3.rsa_rc4_128_sha", false);' >> /home/amnesia/.tor-browser/profile.default/prefs.js
echo 'user_pref("security.tls.unrestricted_rc4_fallback", false);' >> /home/amnesia/.tor-browser/profile.default/prefs.js

#
# Put a link to the TAILS Candy folder on the user's desktop
#
echo "Creating TAILS Candy desktop item ..."
sudo -u amnesia cat <<EOF > /home/amnesia/Desktop/TAILS_Candy.desktop
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Link
Icon[en_US]=x-system-software-sources
Name[en_US]=TAILS Candy
Comment[en_US]=Install Additional Software
URL=file:///home/amnesia/Persistent/TAILSCandy
Name=TAILS Candy
Comment=Install Additional Software
Icon=x-system-software-sources
EOF

#
# Shall we modify the default TAILS Gnome top panel layout?
#
echo
Confirm "Shall we add a couple of useful items to the Gnome top panel? " && modify_toppanel

#
# Configure persistence for I2P ?
#
echo
Confirm "Shall we configure TAILS for I2P persistence? " && I2PPersistence
 
#
# Ask for additional software packages to be installed persistently
#
clear
echo
echo "You can now pick a series of other standard packages to be installed"
echo "automatically every time you boot TAILS."
echo 
echo "1) You need dirmngr, gpgsm and claws-mail-smime-plugin if you want to"
echo "use X509 certificates in Claws Mail."
echo "2) pidgin-privacy-please and pidgin-openpgp are privacy add-ons for"
echo "the Pidgin IM client."
echo "3) ClamTk and claws-mail-clamd-plugin: forwarding emails containing"
echo "viruses is never a good idea."
echo "4) Putty and Filezilla are for those folks who cannot be asked to use"
echo "the command line for secure remote sessions and file transfers."
echo "5) encfs and cryptkeeper let you access Dropbox storage encrypted with"
echo "encfs or BoxCryptor on other platforms."
echo "6) Mixmaster and signing-party for die-hard cypherpunks."
echo "7) Proxychains for use with nmap during network reconnaissance."
echo "8) hfsprogs: set of utilities for accessing your Mac's hard drive(s)."
echo

packages='dirmngr gpgsm claws-mail-smime-plugin pidgin-openpgp signing-party clamtk claws-mail-clamd-plugin filezilla putty mixmaster encfs cryptkeeper pidgin-privacy-please proxychains nmap hfsprogs'
for package in $packages
do
	grep -q $package /live/persistence/TailsData_unlocked/live-additional-software.conf
	if [ ! $? -eq 0 ]; then
		echo
		Confirm "Do you wish to consistently install $package at boot time? y/n" && echo $package >> /live/persistence/TailsData_unlocked/live-additional-software.conf
	fi
done

#
# Set RAMONES desktop background
#
# Unless you comment out the next 2 statements, your desktop background will get
# a Ramones wallpaper. People REALLY should take their time to go through
# installation routines like this one to see what exactly it is they're doing.
# You're on a SECURE OS, so try to keep it that way.
# The wallpaper is temporary and TAILS will automatically reset it at reboot
#
/usr/bin/gsettings set org.gnome.desktop.background picture-uri file:///home/amnesia/Persistent/Packages/Settings/Gnome/bg.jpg
/usr/bin/gsettings set org.gnome.desktop.background picture-options "scaled"

sudo -u amnesia /usr/bin/notify-send "TAILS Candy succesfully installed" "Install your favorite applications from the desktop folder"

read -n 1 -p "All finished. New settings will take effect after reboot. Press any key to finish up ..."

