#!/bin/bash

#########################################################################
# TAILS installer script for Academic Signature v52
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

function copy_settings
{
	cp -rp $PERSISTENT/$prev_dir/x_secrets $PERSISTENT/
	cp -rp $PERSISTENT/$prev_dir/key_tray $PERSISTENT/

}

function insertAfter # file line newText
{
   local file="$1" line="$2" newText="$3"
   sed -i -e "/^$line$/a"$'\\\n'"$newText"$'\n' "$file"
}

Confirm() { read -sn 1 -p "$* [Y/N]? "; [[ ${REPLY:0:1} = [Yy] ]]; }

checksig()
{

# Takes gpg key fingerprint as an argument
echo
echo "WARNING: Verification will fail until the authors gpg public key is marked trusted."
echo
# Do we already have Prof. Anders' public key?
gpg --list-keys $1 || gpg --keyserver keys.gnupg.net --recv $1
# Download distribution file signature
wget -O aca_sig-b52.tar.gz.sig -t 10 --no-check-certificate https://www.fh-wedel.de/~an/crypto/accessories/aca_sig_sout_tarsig.php || echo "Unable to download signature file"
wait
if [ -s ./aca_sig-b52.tar.gz.sig ]; then
	echo "Verifying distribution file signature ..."
# Verify distribution file
        local sig="aca_sig-b52.tar.gz.sig"
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
                Confirm "This key is untrusted. Do you wish to edit its trust now? (trust/lsign) " && gpg --edit-key $1 trust
        fi
	rm aca_sig-b52.tar.gz.sig
else
echo "Unable to fetch signature file and verify downloaded Academic Signature distribution file"
fi

echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort installation of Academic Signature ..."

}

# Script main line

clear
echo "This routine will persistently install Academic Signature,"
echo "a Swiss Army Knife of strong cryptography by Prof. Michael Anders."
echo
echo "Source: http://www.fh-wedel.de/~an/crypto/Academic_signature_eng.html"
echo
echo "1) You need to have TAILS persistence & root password set up."
echo "The script will exit gracefully if this is not the case."
echo "2) We will try to download the Academic Signature source package."
echo "If download fails, the script exits gracefully."
echo "3) Installation is saved in ~/Persistent/aca_sig-b52 ."
echo "4) Script will exit if Academic Signature v52 is already installed."
echo "5) Settings from a previous version/installation will by copied"
echo "over from the existing x_secrets and key_tray subdirectories."
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

cd /home/amnesia/Persistent || error_exit "No persistence found. Aborting"

PERSISTENT=/home/amnesia/Persistent
REPO_DIR=$PERSISTENT/Packages/Repo
INSTALL_DIR=$PERSISTENT/aca_sig-b52
distfile=aca_sig-b52.tar.gz

if [ -d "$INSTALL_DIR" ]; then
error_exit "Academic Signature already installed. Remove or rename $INSTALL_DIR to reinstall ..."
fi 

cd $PERSISTENT
# Do we already have a copy of the distribution file?
if [ ! -f "$REPO_DIR/$distfile" ]; then
	echo "Trying to download the Academic Signature source package ..."
	wget -O $distfile https://www.fh-wedel.de/~an/crypto/accessories/aca_sig_sout.php || error_exit "Unable to download Academic Signature. Giving up."
	wait
else
	mv $REPO_DIR/$distfile $PERSISTENT/
fi

# Verify distribution file PGP signature .sig
checksig 70C5D7741C6D685A

echo "Checking for older versions ..."
cnt=`ls -d aca_sig*/ 2>/dev/null | wc -l`
if [ "$cnt" = "1" ]; then
prev_dir=`ls -d aca_sig*/`
echo
Confirm "Previous version of Academic Signature found in $prev_dir. Copy settings over to new installation? " && copy_settings
echo
fi

echo "Unpacking distribution file ..."
tar -xzf $distfile

# Any x_secrets/key_tray settings to copy over?
if [ -d "$PERSISTENT/x_secrets" ]; then
echo "Restoring settings from previous version..."
cd $PERSISTENT
cp -p x_secrets/* $INSTALL_DIR/x_secrets/
cp -p key_tray/* $INSTALL_DIR/key_tray/
rm -rf x_secrets
rm -rf key_tray
fi

echo
echo "Install g++ compiler & dependencies ..."
echo
sudo apt-get -y install g++ g++-4.7 gcc gcc-4.7 libc-dev-bin libc6-dev libitm1 libstdc++6-4.7-dev libwxbase2.8-dev libwxgtk2.8-dev linux-libc-dev make wx-common wx2.8-headers
# Compile Academic Signature the usual way ...
echo
echo "Now compiling Academic Signature ..."
echo
cd $INSTALL_DIR
./configure
# modify src/dolonu.h header because of known bug that prevents compilation on TAILS
grep -q 'define WX28' $INSTALL_DIR/src/dolonu.h || insertAfter $INSTALL_DIR/src/dolonu.h '#define DOLONUX_H' '#define WX28'
make || error_exit "Compilation of Academic Signature failed."
echo
echo "Creating Gnome menu item ..."
echo
desktopdir=/live/persistence/TailsData_unlocked/dotfiles/.local/share/applications
if [ ! -d "$desktopdir" ]; then
	mkdir -p $desktopdir
fi
/bin/cat <<EOF > $desktopdir/aca_sig.desktop
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=Academic Signature
Name[de]=Academic Signature
Name[en_GB]=Academic Signature
Name[fr]=Academic Signature
Name[fr_CA]=Academic Signature
Type=Application
Terminal=false
Path=/home/amnesia/Persistent/aca_sig-b52
Exec=/home/amnesia/Persistent/aca_sig-b52/aca_sig
#Icon=/home/amnesia/Persistent/aca_sig-b52/signature-icon.png
Icon=writer
Categories=Security;Encryption;
StartupNotify=true
EOF
cp -p $desktopdir/aca_sig.desktop /home/amnesia/.local/share/applications/ 1>&2

# Create symlink to ~/bin directory to have the executable in our path
#echo "Creating symlink to ~/bin directory ..."
#BIN_DIR=/live/persistence/TailsData_unlocked/dotfiles/bin
#if [ ! -d "$BIN_DIR" ]; then
#	mkdir -p $BIN_DIR
#else
#	rm $BIN_DIR/aca_sig 1>&2
#fi
#ln -sf $INSTALL_DIR/aca_sig $BIN_DIR/aca_sig

cd $INSTALL_DIR
# Remove installation & configuration source files?
echo
Confirm "Type y if you wish to clean up installation source files" && rm -rf $INSTALL_DIR/src Make* config* compile depcomp missing aclocal.m4 stamp-h1 install-sh
echo
Confirm "Type y if you wish to remove the distribution file" && rm $PERSISTENT/$distfile || mv $PERSISTENT/$distfile $REPO_DIR/
# Remove compiler & dependencies?
echo
Confirm "Type y if you wish to remove the compiler now" && sudo apt-get -y remove g++ g++-4.7 gcc gcc-4.7 libc-dev-bin libc6-dev libitm1 libstdc++6-4.7-dev libwxbase2.8-dev libwxgtk2.8-dev linux-libc-dev make wx-common wx2.8-headers

/usr/bin/notify-send "Academic Signature Installed" "Open with Applications > Encryption > Academic Signature"

echo
read -n 1 -p "Academic Signature has been installed. Press any key to launch now or Ctrl-C to finish up ..."
./aca_sig &

