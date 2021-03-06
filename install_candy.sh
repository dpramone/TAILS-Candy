#!/bin/bash
#########################################################################
# TAILS Candy installer script
#
# This script installs the TAILS Candy package
#
# Part of "TAILS Candy" Project
# Version 0.2
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
	l1dir="/live/persistence/TailsData_unlocked/dotfiles/.config/gnome-panel"
	l2dir="/home/amnesia/.config/gnome-panel"
	if [ ! -d "$l1dir" ]; then
		sudo -u amnesia mkdir -p $l1dir
	fi
	if [ ! -d "$l2dir" ]; then
		sudo -u amnesia mkdir -p $l2dir
	fi
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

Confirm() { read -sn 1 -p "$* [Y/N]? "; [[ ${REPLY:0:1} = [Yy] ]]; }

####################
# Script main line #
####################

if [[ $EUID -ne 0 ]]; then
    echo "You need to run this installer script as root" 1>&2
    exit 1
fi

CUR_DIR=$PWD
DOT_DIR=/live/persistence/TailsData_unlocked/dotfiles
cd $DOT_DIR || error_exit "No TAILS Dotfiles persistence found. Aborting"
cd "$CUR_DIR"

clear
echo 
echo "This routine will guide you through installation or upgrade"
echo "of TAILS Candy."
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

# Determine if this is a first time install or upgrade.
#
PERSISTENT=/home/amnesia/Persistent

packdir=$PERSISTENT/Packages
candydir=$PERSISTENT/TAILSCandy 
if [ -d "$packdir" ] && [ -d "$candydir" ] ; then
# This is an upgrade
	#if [ "$CUR_DIR" == "/home/amnesia/Persistent/Packages" ]; then
		echo "Downloading latest TAILS Candy from Github ..."
		# We are being executed from the Packages directory, so let's
		# update by performing a git clone from the master branch
		sudo -u amnesia mkdir -p $PERSISTENT/tmp  2> /dev/null
		cd $PERSISTENT/tmp
		sudo -u amnesia git clone https://github.com/dpramone/TAILS-Candy.git || error_exit "Unable to download TAILS Candy upgrade. Bailing out ..."
		cd TAILS-Candy
		# Remove Git infornation
		rm -rf /home/amnesia/Persistent/tmp/TAILS-Candy/.git
		CUR_DIR="/home/amnesia/Persistent/tmp/TAILS-Candy"
	#fi
	VERSION=`cat "$CUR_DIR/VERSION"`
	echo
	echo "Upgrading TAILS Candy to version $VERSION ..."
	# 
	# Placeholder for stuff to be removed from older versions ...
	#
else
	VERSION=`cat "$CUR_DIR/VERSION"`
	echo
	echo "Installing TAILS Candy version $VERSION ..."
fi

echo
echo "Installing Packages and TAILSCandy folders in $PERSISTENT ..."
folder="$CUR_DIR/Packages"
if [ -d "$folder" ]
then
	chown -R amnesia:amnesia "$folder"
	cp -rp "$folder" $PERSISTENT/
	if [ ! -f "$PERSISTENT/Packages/install_candy.sh" ]; then
	cp -p "$CUR_DIR/install_candy.sh" $PERSISTENT/Packages/ 2> /dev/null
	fi 
	chmod 700 "$folder"/*.sh
else
	error_exit "Where is our TAILS Candy Packages folder? Installation aborted."
fi
folder="$CUR_DIR/TAILSCandy"
if [ -d "$folder" ]
then
	chown -R amnesia:amnesia "$folder"
	cp -rp "$folder" $PERSISTENT/
	mkdir -p $PERSISTENT/TAILSCandy/Info 2> /dev/null
	cp -p "$CUR_DIR/TODO" $PERSISTENT/TAILSCandy/Info/ 2> /dev/null
	cp -p "$CUR_DIR/AUTHORS" $PERSISTENT/TAILSCandy/Info/ 2> /dev/null
	cp -p "$CUR_DIR/README" $PERSISTENT/TAILSCandy/Info/ 2> /dev/null
	cp -p "$CUR_DIR/LICENSE" $PERSISTENT/TAILSCandy/Info/ 2> /dev/null
	cp -p "$CUR_DIR/COPYING" $PERSISTENT/TAILSCandy/Info/ 2> /dev/null
	cp -p "$CUR_DIR/ChangeLog" $PERSISTENT/TAILSCandy/Info/ 2> /dev/null
	cp -p "$CUR_DIR/NEWS" $PERSISTENT/TAILSCandy/Info/ 2> /dev/null
	cp -p "$CUR_DIR/VERSION" $PERSISTENT/TAILSCandy/Info/ 2> /dev/null
	chown -R amnesia:amnesia $PERSISTENT/TAILSCandy/Info
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
Encoding=UTF-8
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
if [ ! -d "/home/amnesia/.config/autostart" ]; then
	sudo -u amnesia mkdir -p /home/amnesia/.config/autostart
fi
sudo -u amnesia ln -sf $startdir/customisations.desktop /home/amnesia/.config/autostart/customisations.desktop

#
# Disable default TAILS SSH support in Gnome Keyring daemon.
# It totally sucks, doesn't support ECC keys and normal people should
# be using the GnuPG agent anyway.
#
echo "Disabling Gnome Keyring SSH support so we can use the GPG agent ..."
sudo -u amnesia cat <<EOF > /live/persistence/TailsData_unlocked/dotfiles/.config/autostart/gnome-keyring-ssh.desktop
[Desktop Entry]
Encoding=UTF-8
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

if [ -f "${HOME}/.gnupg/gpg-agent-info-amnesia" ]; then
     . "${HOME}/.gnupg/gpg-agent-info-amnesia"
       export GPG_AGENT_INFO
       export SSH_AUTH_SOCK
       export SSH_AGENT_PID
fi
EOF
bashrc=/live/persistence/TailsData_unlocked/dotfiles/.bashrc
# Make .bashrc persistent by copying over to Dotfiles directory
if [ ! -f "$bashrc" ]; then
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
	sudo -u amnesia mkdir -p $dtdir
fi
sudo -u amnesia cp -p $PERSISTENT/Packages/Settings/Gnome/Encryption.directory $dtdir/Encryption.directory 1>&2

#
# Shall we modify the default TAILS Gnome top panel layout?
#
echo
Confirm "Shall we add a couple of useful items to the Gnome top panel? If you answered yes on previous TAILS 1.6 ot 1.7 instalations, please repeat now to reflect changes in TAILS 1.8 and up." && modify_toppanel

#
# Configure persistence for I2P ?
#
echo
grep -q "i2p" /live/persistence/TailsData_unlocked/persistence.conf
if [ ! $? -eq 0 ]; then
Confirm "Shall we configure TAILS for I2P persistence? " && echo "/var/lib/i2p source=i2p" >> /live/persistence/TailsData_unlocked/persistence.conf
fi
 
#
# Ask for additional software packages to be installed persistently
#
clear
echo
echo "You can now pick a series of other standard packages to be installed"
echo "automatically every time you boot TAILS."
echo 
echo "1) pidgin-privacy-please and pidgin-openpgp are privacy add-ons for"
echo "the Pidgin IM client."
echo "2) ClamTk"
#echo "3) ClamTk and claws-mail-clamd-plugin: forwarding emails containing"
#echo "viruses is never a good idea."
echo "3) Putty and Filezilla are for those folks who cannot be asked to use"
echo "the command line for secure remote sessions and file transfers."
echo "4) encfs and cryptkeeper let you access Dropbox storage encrypted with"
echo "encfs or BoxCryptor on other platforms."
echo "5) Mixmaster and signing-party for die-hard cypherpunks."
echo "6) Proxychains for use with nmap during network reconnaissance."
echo "7) hfsprogs: set of utilities for accessing your Mac's hard drive(s)."
echo

packages='dirmngr gpgsm pidgin-openpgp signing-party clamtk filezilla putty mixmaster encfs cryptkeeper pidgin-privacy-please proxychains nmap hfsprogs'
for package in $packages
do
	grep -q $package /live/persistence/TailsData_unlocked/live-additional-software.conf
	if [ ! $? -eq 0 ]; then
		echo
		Confirm "Do you wish to consistently install $package at boot time? " && echo $package >> /live/persistence/TailsData_unlocked/live-additional-software.conf
	fi
done
echo

#
# Set RAMONES desktop background
#
# Unless you comment out the next 2 statements, your desktop background will get
# a Ramones wallpaper. People REALLY should take their time to go through
# installation routines like this one to see what exactly it is they're doing.
# You're on a SECURE OS, so try to keep it that way.
# The wallpaper is temporary and TAILS will automatically reset it at reboot
#
sudo -u amnesia /usr/bin/gsettings set org.gnome.desktop.background picture-uri file:///home/amnesia/Persistent/Packages/Settings/Gnome/bg.jpg
sudo -u amnesia /usr/bin/gsettings set org.gnome.desktop.background picture-options "scaled"

# Execute Customisations script from TAILS Candy Packages folder. This will from now be executed at every boot
sudo -u amnesia /home/amnesia/Persistent/Packages/Customisations.sh install

read -n 1 -p "All finished. Some modifications will only take effect after reboot. Press any key to finish up ..."

# Remove installation directory
cd "$CUR_DIR"
cd ..
rm -rf ./TAILS-Candy-master
rm -rf ./TAILS-Candy

exit 0

