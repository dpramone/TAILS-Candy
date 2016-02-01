#!/bin/bash

#########################################################################
# TAILS installer script for SilentEye 0.4.0 steganography tool
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

Confirm() { read -sn 1 -p "$* [Y/N]? "; [[ ${REPLY:0:1} = [Yy] ]]; }

# Main line

if [[ $EUID -ne 0 ]]; then
    echo "You need to run this as root" 1>&2
    exit 1
fi

clear
echo 
echo "This routine will non-persistently install the SilentEye"
echo "steganography tool and its dependencies from Debian package(s)."
echo 
echo "Source: http://www.silenteye.org/ "
echo 
read -n 1 -p "Press any key to continue or Ctrl-C to abort..."
echo 

PERSISTENT=/home/amnesia/Persistent
REPO_DIR=$PERSISTENT/Packages/Repo
CONF_DIR=$PERSISTENT/Packages/Settings/SilentEye

# SilentEye dependencies
echo "Installing SilentEye dependencies first ..."
/usr/bin/apt-get install libqca2 libqt4-opengl libqtmultimediakit1

# Do we already have a copy of the SilentEye .deb installation file?
cd $REPO_DIR
cnt=`ls silenteye*-i386.deb 2>/dev/null | wc -l`
if [ "$cnt" = "0" ]; then
wget -O silenteye-0.4.0-i386.deb http://downloads.sourceforge.net/project/silenteye/Application/0.4/silenteye-0.4.0-i386.deb?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fsilenteye%2Ffiles%2FApplication%2F0.4%2Fsilenteye-0.4.0-i386.deb%2Fdownload&ts=1445478994&use_mirror=liquidtelecom || error_exit "Sorry, unable to download SilentEye. Bailing out."
wait
chown amnesia:amnesia $REPO_DIR/silenteye*-i386.deb
fi
/usr/bin/dpkg -i $REPO_DIR/silenteye*-i386.deb || error_exit "SilentEye installation failed!" 

echo
Confirm "Type y if you wish to keep the downloaded/saved distribution file" || rm $REPO_DIR/silenteye*-i386.deb
echo

# Did we save its settings file in a previous TAILS session?
# If yes: restore.
#
conffile=$CONF_DIR/silenteye.conf
if [ -f "$conffile" ] 
then
	cp $conffile /opt/silenteye/silenteye.conf
	chown amnesia:amnesia /opt/silenteye/silenteye.conf
	chmod 640 /opt/silenteye/silenteye.conf
else
	mkdir -p $CONF_DIR 1>&2
	chown amnesia:amnesia $CONF_DIR
	cp /opt/silenteye/silenteye.conf $conffile
	chown amnesia:amnesia $conffile
	echo 
	echo "When modifying SilentEye preferences, you may save the configuration file"
	echo "in /opt/silenteye/silenteye.conf to ~/Persistent/Packages/Settings/SilentEye."
	echo "This routine will then restore it in future sessions."
	echo 
	read -n 1 -p "Press any key to finish up ..."
fi
#
# We will forget to save the settings file anyway, so we force a save by
# creating a small script in /etc/rc6.d which will execute at shutdown time.
# 
shutfile=/etc/rc6.d/K01SilentEye
if [ ! -f "$shutfile" ]
then
        /bin/cat <<EOF > $shutfile
#!/bin/bash
cp /opt/silenteye/silenteye.conf /home/amnesia/Persistent/Packages/Settings/SilentEye/silenteye.conf
chown amnesia:amnesia /home/amnesia/Persistent/Packages/Settings/SilentEye/silenteye.conf
EOF
	chmod +x $shutfile
fi

sudo -u amnesia /usr/bin/notify-send -i /opt/silenteye/silenteye.png "SilentEye Installed" "Open with Applications > Accessoires > SilentEye"
