#!/bin/bash

#########################################################################
# TAILS installer script for TrueCrypt 7.2
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

checksig()
{

# Takes gpg key fingerprint as an argument
echo
echo "Verification will fail until you have trusted the TrueCrypt public key."
echo
gpg --list-keys $1 || wget -O - http://sourceforge.net/projects/truecrypt/files/TrueCrypt/Other/TrueCrypt-key.asc/download | gpg --import
#
# Download distribution file signature
#
curl --socks5-hostname 127.0.0.1:9050 -k -L -J -O http://sourceforge.net/projects/truecrypt/files/TrueCrypt/Other/TrueCrypt-7.2-Linux-x86.tar.gz.sig/download || echo "Unable to download signature file"
wait
if [ -s ./TrueCrypt-7.2-Linux-x86.tar.gz.sig ]; then
# Verify distribution file
        local sig="TrueCrypt-7.2-Linux-x86.tar.gz.sig"
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
		echo
                Confirm "This key is untrusted. Do you wish to edit its trust now? (trust/lsign)" && gpg --edit-key $1 trust
        fi
else
echo "Unable to fetch signature file and verify downloaded TrueCrypt distribution file"
fi

echo
Confirm "Press y to continue or n to abort installation ..." || error_exit "Installation aborted per user request."

}

Confirm() { read -sn 1 -p "$* [Y/N]? "; [[ ${REPLY:0:1} = [Yy] ]]; }

# Main line

clear
echo 
echo "This script will non-persistenly install TrueCrypt 7.2."
echo "It will create a dotfiles .TrueCrypt directory to"
echo "persistently store settings."
echo
echo "Re-run this script on every boot when you need TrueCrypt."
echo
echo "Source: http://truecrypt.sourceforge.net/OtherPlatforms.html"
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

DOT_DIR=/live/persistence/TailsData_unlocked/dotfiles
cd $DOT_DIR || error_exit "No dotfiles persistence found. Aborting"

REPO_DIR=/home/amnesia/Persistent/Packages/Repo

# This script should not be run as root
if [[ $EUID -eq 0 ]]; then
        error_exit "Please do not run this script with sudo or as root"
fi

# Do we already have a copy of the TrueCrypt installer ?
cd $REPO_DIR
installfile=$REPO_DIR/truecrypt-7.2-setup-x86
if [ ! -f "$installfile" ]; then
#
	curl --socks5-hostname 127.0.0.1:9050 -k -L -J -O http://sourceforge.net/projects/truecrypt/files/TrueCrypt/Other/TrueCrypt-7.2-Linux-x86.tar.gz/download || error_exit "Unable to download TrueCrypt installer. Bailing out."
	wait

# Verify GPG signature of downloaded distribution file against Veracrypt public key
	secring="/home/amnesia/.gnupg/secring.gpg"
	if [ -f "$secring" ]; then checksig C5F4BAC4A7B22DB8B8F85538E3BA73CAF0D6B1E0 ; fi

	tar -xzf TrueCrypt-7.2-Linux-x86.tar.gz
fi

echo
Confirm "Do you wish to keep the downloaded/saved distribution file?" || rm -f $REPO_DIR/TrueCrypt-7.2-Linux-x86*
echo

# Launch the installer
./truecrypt-7.2-setup-x86
clear

# Create menu item

/bin/cat <<EOF > /home/amnesia/.local/share/applications/truecrypt.desktop
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=TrueCrypt 7.2
GenericName=TrueCrypt
Comment=Work with TrueCrypt Volumes
Icon=truecrypt
Terminal=false
Type=Application
Categories=Encryption;Security;
Exec=/usr/bin/truecrypt
EOF
chmod 640 /home/amnesia/.local/share/applications/truecrypt.desktop

#
# Check for existence of previous TrueCrypt config directory in persistent volume (dotfiles)
#
confdir=/live/persistence/TailsData_unlocked/dotfiles/.TrueCrypt
if [ ! -d "$confdir" ]
then
        # Create TrueCrypt config directory & symlink
        mkdir $confdir
        chmod 700 $confdir
        ln -s  $confdir /home/amnesia/.TrueCrypt
fi
 
/usr/bin/notify-send -i /usr/share/pixmaps/truecrypt.xpm "TrueCrypt Installed" "Open with Applications > Encryption > TrueCrypt"
