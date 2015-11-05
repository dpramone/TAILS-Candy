#!/bin/bash

#########################################################################
# TAILS installer for Tomb LUKS-volume management script
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

if [[ $EUID -ne 0 ]]; then
    echo "You need to run this as root" 1>&2
    exit 1
fi

clear
echo "This routine will persistently install the Tomb Cryptkeeper in"
echo "~/Persistent/Tomb."
echo "Source: https://www.dyne.org/software/tomb/"
echo
echo "1) You need to have TAILS persistence with dotfiles configured."
echo "The script will exit gracefully if this is not the case."
echo "2) We will try to download Tomb from Github. If download fails,"
echo "the script exits gracefully."
echo "3) If the ~/Persistent/Tomb directory already"
echo "exists, we try to update the package with a git pull." 
echo
echo "4) ATTENTION: To access Tomb, you need to re-run this script"
echo "after every TAILS (re)boot."
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

cd /live/persistence/TailsData_unlocked/dotfiles || exit

PERSISTENT=/home/amnesia/Persistent
PKG_DIR=$PERSISTENT/Tomb
REPO_DIR=$PERSISTENT/Packages/Repo

if [ -d "$PKG_DIR" ]
then
        echo "Trying to update Tomb from Github ..."
        cd $PKG_DIR
        git pull
	echo
        read -n 1 -p "Press any key to continue..."
	echo
else
        echo "Downloading Tomb from Github ..."
        git clone https://github.com/dyne/Tomb.git $PKG_DIR || exit
fi

/bin/echo "Installing Tomb dependencies"
/usr/bin/apt-get -y install libmcrypt4 python-uno zsh make steghide wipe pinentry-curses mlocate dcfldd qrencode swish++ unoconv

/bin/echo "Installing Tomb scripts"
cd $PKG_DIR
make install
cp $REPO_DIR/Tomb/tomb-open /usr/local/bin/
cp $REPO_DIR/Tomb/undertaker /usr/local/bin/
# Set SUID so wrappers can run with root privileges
chmod 755 /usr/local/bin/tomb-open
chmod 755 /usr/local/bin/undertaker

/bin/echo "Creating (non-persistent) Gnome menu items ..."
/bin/cat <<EOF > /home/amnesia/.local/share/applications/tomb.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Create/Open Crypto Tomb 
GenericName=Crypto Undertaker
Comment=Keep your bones safe
#Exec=gnome-terminal -e /usr/local/bin/tomb-open wizard %U
Exec=gnome-terminal -e 'sudo /usr/local/bin/tomb-open amnesia'
#TryExec=tomb-open %U
Icon=seahorse
Terminal=false
Categories=Tomb;
MimeType=application/x-tomb-volume;
#X-AppInstall-Package=tomb
EOF

/bin/cat <<EOF > /home/amnesia/.local/share/applications/tomb_close.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Close Crypto Tomb 
GenericName=Close Crypto Tomb
Comment=Close/Slam Crypto Tomb
Exec=sh -c "gksudo --message 'We need root password to close the Tomb volumes'  '/usr/local/bin/tomb close' && pkill tomb-gtk-tray"
Icon=gdu-encrypted-lock
Terminal=false
Categories=Tomb;
#MimeType=application/x-tomb-volume;
#X-AppInstall-Package=tomb
EOF

/bin/cat <<EOF > /home/amnesia/.local/share/desktop-directories/Tomb.directory
[Desktop Entry]
Encoding=UTF-8
Name=Tomb Encryption
Name[en_US]=Tomb Encryption
Name[en_DK]=Tomb Encryption
Comment=Tomb the Crypto Undertaker
Comment[en_US]=Tomb the Crypto Undertaker
Comment[en_DK]=Tomb the Crypto Undertaker
Icon=monmort
Type=Directory
EOF

chown amnesia:amnesia /home/amnesia/.local/share/applications/tomb.desktop
chown amnesia:amnesia /home/amnesia/.local/share/applications/tomb_close.desktop
chown amnesia:amnesia /home/amnesia/.local/share/desktop-directories/Tomb.directory
chmod u+x /home/amnesia/.local/share/applications/tomb.desktop
chmod u+x /home/amnesia/.local/share/applications/tomb_close.desktop

/bin/echo "Installing Tomb-gtk-tray"
cd $PKG_DIR/extras/gtk-tray
# Check if we have a tomb-gtk-tray object ; If not: compile first
if [ ! -f /home/amnesia/Persistent/Tomb/extras/gtk-tray/tomb-gtk-tray ]
then
	apt-get install make g++ libnotify-dev libgtk2.0-dev
	rm -f *.o
	make
else
	apt-get install make
fi

if [ -f /home/amnesia/Persistent/Tomb/extras/gtk-tray/tomb-gtk-tray ]
then
	make install
	cp tomb-gtk-tray /usr/local/bin/
	chmod 755 /usr/local/bin/tomb-gtk-tray
	cp monmort.xpm /usr/share/pixmaps/
	chmod 644 /usr/share/pixmaps/monmort.xpm
fi

/bin/echo "Installing Tomb KDF-keys"
#
cd $PKG_DIR/extras/kdf-keys
if [ ! -f /home/amnesia/Persistent/Tomb/extras/kdf-keys/tomb-kdb-pbkdf2 ]
then
	apt-get install g++ libgcrypt11-dev
	rm -f *.o
	make
fi
make install

# Desktop Integration
#
    echo "updating mimetypes..."
    /bin/cat <<EOF > /usr/share/mime/packages/tomb.xml
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
   <mime-type type="application/x-tomb-volume">
     <comment>Tomb crypto volume</comment>
     <magic priority="50">
       <match value="LUKS" type="string" offset="10:140"/>
     </magic>
     <glob pattern="*.tomb"/>
   </mime-type>
  <mime-type type="application/x-tomb-key">
    <comment>Tomb crypto key</comment>
    <glob pattern="*.tomb.key"/>
  </mime-type>
</mime-info>
EOF
    #update-mime-database /usr/share/mime

#    xdg-icon-resource install --context mimetypes --size 32 monmort.xpm monmort
#    xdg-icon-resource install --size 32 monmort.xpm dyne-monmort

    /bin/echo "updating desktop..."
    /bin/cat <<EOF > /usr/share/applications/tomb.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Tomb Crypto Undertaker
GenericName=Crypto Undertaker
Comment=Keep your bones safe
Exec=tomb-open amnesia
TryExec=tomb-open
Icon=medium-security
Terminal=true
Categories=Encryption;Security;Tomb
MimeType=application/x-tomb-volume;
X-AppInstall-Package=tomb
EOF
    #update-desktop-database

    /bin/echo "updating menus..."
    /bin/cat <<EOF > /usr/share/menu/tomb
?package(tomb):command="tomb" icon="/usr/share/pixmaps/monmort.xpm" needs="text
" \
	section="Applications/Encryption" title="Tomb" hints="Crypto" \
	hotkey="Tomb"
EOF
#    update-menus

    echo "updating mime info..."
    /bin/cat <<EOF > /usr/share/mime-info/tomb.keys
# actions for encrypted tomb storage
application/x-tomb-volume:
	open=tomb-open %f
	view=tomb-open %f
	icon-filename=monmort.xpm
	short_list_application_ids_for_novice_user_level=tomb
EOF
    /bin/cat <<EOF > /usr/share/mime-info/tomb.mime
# mime type for encrypted tomb storage
application/x-tomb-volume
	ext: tomb

application/x-tomb-key
	ext: tomb.key
EOF
    /bin/cat <<EOF > /usr/lib/mime/packages/tomb
application/x-tomb-volume; tomb-open '%s'; priority=8
EOF
    # update-mime

    /bin/echo "updating application entry..."

    /bin/cat <<EOF > /usr/share/application-registry/tomb.applications
tomb
	 command=tomb-open
	 name=Tomb - Crypto Undertaker
	 can_open_multiple_files=false
	 expects_uris=false
	 requires_terminal=true
	 mime-types=application/x-tomb-volume,application/x-tomb-key
EOF

/bin/echo "application/x-tomb-volume=tomb.desktop;" >> /usr/share/applications/mimeinfo.cache
/bin/echo "application/x-tomb-key=tomb.desktop;" >> /usr/share/applications/mimeinfo.cache

# Uninstall dependencies no longer needed
/usr/bin/dpkg -r make

/usr/bin/sudo -u amnesia /usr/bin/notify-send "Tomb has been installed." "Open with Applications > Encryption > Tomb Crypto Undertaker"
