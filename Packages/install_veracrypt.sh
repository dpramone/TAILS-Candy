#!/bin/bash

#########################################################################
# TAILS installer script for Veracrypt 1.16
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

checksig()
{

# Takes gpg key fingerprint as an argument
echo
echo "Verification will fail until you have trusted the Veracrypt public key."
echo
gpg --list-keys $1 || wget -O - https://www.idrix.fr/VeraCrypt/VeraCrypt_PGP_public_key.asc | gpg --import
#
# Download distribution file signature
#
# This is an ABSURD hack because codeplex.com doesn't allow any direct 
# downloads with curl/wget unless you set the User Agent to "chocolatey command
# line". Go figure ...
# Ref.: https://groups.google.com/forum/#!topic/chocolatey/tQJzs0B7a1k
#
curl --socks5-hostname 127.0.0.1:9050 -k -L -J -A "chocolatey command line" -O https://veracrypt.codeplex.com/downloads/get/1468027 || echo "Unable to download signature file"
wait
if [ -s ./veracrypt-1.16-setup.tar.bz2.sig ]; then
# Verify distribution file
        local sig="veracrypt-1.16-setup.tar.bz2.sig"
        local output="$(gpg -v "$sig" 2>&1)"
        local good="$(grep -oE "^gpg: Good signature from" <<< "$output")"
        local bad="$(grep -oE "^gpg: BAD signature from" <<< "$output")"
        local untrusted="$(grep -oE "^gpg: WARNING: This key is not certified with a trusted signature" <<< "$output")"
        if [[ -n $good && -z $untrusted ]]; then
                echo "Signature verified. Looking good."
                return 0
        elif [[ -n $bad ]]; then
                echo "Signature verification FAILED!"
        else
                Confirm "This key is untrusted. Do you wish to edit its trust now? (trust/lsign)" && gpg --edit-key $1 trust
        fi
else
echo "Unable to fetch signature file and verify downloaded Veracrypt distribution file"
fi

echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort installation ..."

}

Confirm() { read -sn 1 -p "$* [Y/N]? "; [[ ${REPLY:0:1} = [Yy] ]]; }

# Main line

clear
echo 
echo "This script will non-persistenly install Veracrypt 1.16."
echo "It will create a dotfiles .VeraCrypt directory to"
echo "persistently store settings."
echo
echo "Re-run this script on every boot when you need Veracrypt."
echo
echo "Source: https://veracrypt.codeplex.com/ "
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

DOT_DIR=/live/persistence/TailsData_unlocked/dotfiles
cd $DOT_DIR || error_exit "No dotfiles persistence found. Aborting"

REPO_DIR=/home/amnesia/Persistent/Packages/Repo

# This script should not be run as root
if [[ $EUID -eq 0 ]]; then
        error_exit "Please do not run this script with sudo or as root"
fi

# Do we already have a copy of the Veracrypt installer ?
cd $REPO_DIR
installfile=$REPO_DIR/veracrypt-1.16-setup-gui-x86
if [ ! -f "$installfile" ]; then
#
# This is an ABSURD hack because codeplex.com doesn't allow any direct 
# downloads with curl/wget unless you set the User Agent to "chocolatey command
# line". Go figure ...
# Ref.: https://groups.google.com/forum/#!topic/chocolatey/tQJzs0B7a1k
#
	curl --socks5-hostname 127.0.0.1:9050 -k -L -J -A "chocolatey command line" -O https://veracrypt.codeplex.com/downloads/get/1468024 || error_exit "Unable to download Veracrypt installer. Bailing out."
	wait

# Verify GPG signature of downloaded distribution file against Veracrypt public key
	secring="/home/amnesia/.gnupg/secring.gpg"
	if [ -f "$secring" ]; then checksig 993B7D7E8E413809828F0F29EB559C7C54DDD393 ; fi

	tar -xjvf veracrypt-1.16-setup.tar.bz2
# We don't need the x64 stuff on this platform
	rm vera*x64
fi

echo
Confirm "Do you wish to keep the downloaded/saved distribution file?" || rm $REPO_DIR/veracrypt-1.16-setup.tar.bz2*
echo

# Launch the installer
./veracrypt-1.16-setup-gui-x86
clear

# Create menu item

/bin/cat <<EOF > /home/amnesia/.local/share/applications/veracrypt.desktop
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
