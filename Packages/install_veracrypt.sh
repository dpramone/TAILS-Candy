#!/bin/bash

#########################################################################
# TAILS installer script for Veracrypt
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

# Main line

clear
echo 
echo "This script will non-persistenly install Veracrypt 1.16."
echo
echo "Source: https://veracrypt.codeplex.com/ "
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

DOT_DIR=/live/persistence/TailsData_unlocked/dotfiles
cd $DOT_DIR || error_exit "No dotfiles persistence found. Aborting"

REPO_DIR=/home/amnesia/Persistent/Packages/Repo

# Do we already have a copy of the Veracrypt installer ?
cd $REPO_DIR
installfile=$REPO_DIR/veracrypt-1.16-setup-gui-x86
if [ ! -f "$installfile" ]; then
wget -O veracrypt-1.16-setup.tar.bz2 https://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=veracrypt&DownloadId=1468024&FileTime=130886989031200000&Build=21031 || error_exit "Unable to download Veracrypt installer. Bailing out."
tar -xjvf veracrypt-1.16-setup.tar.bz2
# We don't need the x64 stuff on this platform and the .bz2 can go too
rm vera*x64 veracrypt*.bz2
fi

# Launch the installer
./veracrypt-1.16-setup-gui-x86

# Create menu item

/bin/cat <<EOF >> /home/amnesia/.local/share/applications/veracrypt.desktop
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=VeraCrypt 1.16
GenericName=VeraCrypt
Comment=Work with VeraCrypt/Truecrypt Volumes
Icon=gdu-encrypted-lock
Terminal=false
Type=Application
Categories=Encryption;Security;
Exec=/usr/bin/veracrypt
EOF
chmod 640 /home/amnesia/.local/share/applications/veracrypt.desktop

#
# Check for existence of previous Veracrypt config directory in persistent volume (dotfiles)
#
confdir=/live/persistence/TailsData_unlocked/dotfiles/.VeraCrypt
if [ ! -d "$confdir" ]
then
        # Create Veracrypt config directory & symlink
        mkdir $confdir
        chmod 700 $confdir
        ln -s  $confdir /home/amnesia/.VeraCrypt
fi
 
/usr/bin/notify-send "Veracrypt Installed" "Open with Applications > Encryption > Veracrypt"
