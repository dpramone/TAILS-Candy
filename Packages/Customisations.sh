#!/bin/bash
#########################################################################
# This script performs a number of TAILS start-up customisations
#
# It is launched from ~/.config/autostart/customisations.desktop,
# which the TAILS Candy installer has copied to /live/persistence/
# /TailsData_unlocked/dotfiles/.config/autostart/customisations.desktop
#
# Part of "TAILS Candy" Project
# Version 0.2
# License: GPL v3 - Copy included in distribution package
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

# This script should not be run as root
if [[ $EUID -eq 0 ]]; then
        error_exit "Please do not run this script with sudo or as root"
fi

#
# Put a link to the TAILS Candy folder on the user's desktop
#

cat <<EOF > /home/amnesia/Desktop/TAILS_Candy.desktop
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Link
Icon[en_US]=system-software-install
Name[en_US]=TAILS Candy
Comment[en_US]=Install Additional Software
URL=file:///home/amnesia/Persistent/TAILSCandy
Name=TAILS Candy
Comment=Install Additional Software
Icon=system-software-install
EOF

#
# Disable vulnerable DHE & RC4-ciphers in Firefox/Tor Browser
#
if [ -f "/home/amnesia/.tor-browser/profile.default/prefs.js" ]; then
echo "Disabling weak ciphers in Tor Browser default profile ..."

grep -q 'user_pref("security.ssl3.dhe_rsa_aes_128_sha", false);' /home/amnesia/.tor-browser/profile.default/prefs.js
if [ ! $? -eq 0 ]; then
echo 'user_pref("security.ssl3.dhe_rsa_aes_128_sha", false);' >> /home/amnesia/.tor-browser/profile.default/prefs.js
fi

grep -q 'user_pref("security.ssl3.dhe_rsa_aes_256_sha", false);' /home/amnesia/.tor-browser/profile.default/prefs.js
if [ ! $? -eq 0 ]; then
echo 'user_pref("security.ssl3.dhe_rsa_aes_256_sha", false);' >> /home/amnesia/.tor-browser/profile.default/prefs.js
fi

grep -q 'user_pref("security.ssl3.ecdhe_ecdsa_rc4_128_sha", false);' /home/amnesia/.tor-browser/profile.default/prefs.js
if [ ! $? -eq 0 ]; then
echo 'user_pref("security.ssl3.ecdhe_ecdsa_rc4_128_sha", false);' >> /home/amnesia/.tor-browser/profile.default/prefs.js
fi

grep -q 'user_pref("security.ssl3.ecdhe_rsa_rc4_128_sha", false);' /home/amnesia/.tor-browser/profile.default/prefs.js
if [ ! $? -eq 0 ]; then
echo 'user_pref("security.ssl3.ecdhe_rsa_rc4_128_sha", false);' >> /home/amnesia/.tor-browser/profile.default/prefs.js
fi

grep -q 'user_pref("security.ssl3.rsa_rc4_128_md5", false);' /home/amnesia/.tor-browser/profile.default/prefs.js
if [ ! $? -eq 0 ]; then
echo 'user_pref("security.ssl3.rsa_rc4_128_md5", false);' >> /home/amnesia/.tor-browser/profile.default/prefs.js
fi

grep -q 'user_pref("security.ssl3.rsa_rc4_128_sha", false);' /home/amnesia/.tor-browser/profile.default/prefs.js
if [ ! $? -eq 0 ]; then
echo 'user_pref("security.ssl3.rsa_rc4_128_sha", false);' >> /home/amnesia/.tor-browser/profile.default/prefs.js
fi

grep -q 'user_pref("security.tls.unrestricted_rc4_fallback, false);' /home/amnesia/.tor-browser/profile.default/prefs.js
if [ ! $? -eq 0 ]; then
echo 'user_pref("security.tls.unrestricted_rc4_fallback", false);' >> /home/amnesia/.tor-browser/profile.default/prefs.js
fi

fi
#############################################################################
# Feel free to add your own customisations hereafter ...
#############################################################################

#
# Set theme & icons
#
#/usr/bin/gsettings set org.gnome.desktop.interface gtk-theme "YourGTKTheme"
#/usr/bin/gsettings set org.gnome.desktop.interface icon-theme 'YourIconTheme'

#
# Customize desktop background color and image (optional)
#
#/usr/bin/gsettings set org.gnome.desktop.background primary-color '#000000'
#resolution=`xdpyinfo | awk -F'[ x]+' '/dimensions:/{print $3, $4}'`
#if [ "$resolution" == "1280 800" ]; then
#/usr/bin/gsettings set org.gnome.desktop.background picture-uri file:///home/amnesia/Persistent/Tor\ Browser/bg1280.jpg
#else
#/usr/bin/gsettings set org.gnome.desktop.background picture-uri file:///home/amnesia/Persistent/Tor\ Browser/bg.jpg
#fi
#/usr/bin/gsettings set org.gnome.desktop.background picture-options "scaled"

#
# Add a couple of Desktop icons
#
BOX_DIR=/live/persistence/TailsData_unlocked/dotfiles/.dropbox-dist
if [ -d "$BOX_DIR" ]; then
cat <<EOF > /home/amnesia/Desktop/dropbox.desktop
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=Dropbox
Name[de]=Dropbox
Name[en_GB]=Dropbox
Name[fr]=Dropbox
Name[fr_CA]=Dropbox
Comment='Sync your files across computers and to the web'
Type=Application
Terminal=false
Exec=torsocks /home/amnesia/bin/dropbox.py start
Icon=/home/amnesia/Persistent/Packages/Settings/Gnome/icons/Dropbox64.png
EOF
chmod 700 /home/amnesia/Desktop/dropbox.desktop
fi

MAL_DIR="/home/amnesia/Persistent/maldetect-1.5"
if [ -d "$MAL_DIR" ]; then
cat <<EOF > /home/amnesia/Desktop/maldet.desktop
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=Enable TAILS Malware Detect
Name[de]=Enable TAILS Malware Detect
Name[en_GB]=Enable TAILS Malware Detect
Name[fr]=Enable TAILS Malware Detect
Name[fr_CA]=Enable TAILS Malware Detect
Type=Application
Terminal=true
Exec=sudo /home/amnesia/Persistent/Packages/install_maldetect.sh
Icon=/home/amnesia/Persistent/Packages/Settings/Gnome/icons/Malware64.png
EOF
chmod 700 /home/amnesia/Desktop/maldet.desktop
fi

# Create menu item for Tor Messenger
#
TOR_DIR="/home/amnesia/Persistent/tor-messenger"
if [ -d "$TOR_DIR" ]; then
cd $TOR_DIR
./start-tor-messenger.desktop --register-app
fi

#
# Create menu item for TAILS Candy installer/updater
#
if [ "$1" == "install" ]; then
	cat <<EOF > /home/amnesia/.local/share/applications/install_candy.desktop
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=Install/Upgrade TAILS Candy
GenericName=Install/Upgrade TAILS Candy
Comment=Install/Upgrade TAILS Candy
Icon=system-upgrade
Terminal=true
Type=Application
Categories=Utilities;Tails;
Exec=sudo /home/amnesia/Persistent/Packages/install_candy.sh
EOF
else
	installfile="/home/amnesia/Persistent/Packages/install_candy.sh"
	if [ -f "$installfile" ]; then
		mv $installfile /home/amnesia/Persistent/Packages/upgrade_candy.sh
	fi
	cat <<EOF > /home/amnesia/.local/share/applications/install_candy.desktop
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=Install/Upgrade TAILS Candy
GenericName=Install/Upgrade TAILS Candy
Comment=Install/Upgrade TAILS Candy
Icon=system-upgrade
Terminal=true
Type=Application
Categories=Utilities;Tails;
Exec=sudo /home/amnesia/Persistent/Packages/upgrade_candy.sh
EOF
fi

#
# Create menu item for TAILS Candy Uninstaller
#
cat <<EOF > /home/amnesia/.local/share/applications/uninstall_candy.desktop
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=Uninstall TAILS Candy
GenericName=Uninstall TAILS Candy
Comment=Uninstall TAILS Candy
Icon=debian
Terminal=true
Type=Application
Categories=Utilities;Tails;
Exec=sudo /home/amnesia/Persistent/Packages/remove_candy.sh
EOF

#
# Create menu item for Mixmaster (if present)
# additional software
#
mixdir=/live/persistence/TailsData_unlocked/dotfiles/.Mix
if [ -d "$mixdir" ]; then
cat <<EOF > /home/amnesia/.local/share/applications/mixmaster.desktop
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=Mixmaster 3.0
GenericName=Mixmaster
Comment=Mixmaster Type II Remailer
Icon=aumix
Terminal=true
Type=Application
Categories=Network;
Exec=/usr/bin/mixmaster
EOF
# Update Mixmaster files
torsocks /usr/bin/mixmaster-update
fi
#
# Re-start panel to make theme/icon settings take effect
#
#/usr/bin/killall -1 gnome-panel
/usr/bin/notify-send -i checkbox "TAILS Candy initialised" "Install your favorite applications from the TAILS Candy desktop folder."
