#!/bin/bash

#########################################################################
# TAILS installer script for TeamViewer 11
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
echo "This routine will non-persistently install TeamViewer 11."
echo
echo "WARNING: Teamviewer runs under Wine and we need to open up"
echo "2 extra firewall ports on the lo interface to make it work."
echo
echo "Source: https://www.teamviewer.com/en/ "
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

PERSISTENT=/home/amnesia/Persistent
REPO_DIR=$PERSISTENT/Packages/Repo
SET_DIR=$PERSISTENT/Packages/Settings/teamviewer11
OLD_DIR=$PERSISTENT/Packages/Settings/teamviewer10

# TeamViewer dependencies
echo "Installing TeamViewer dependencies first ..."
/usr/bin/apt-get -y install libjpeg62

# Do we already have a copy of the TeamViewer .deb installation file?
cd $REPO_DIR
cnt=`ls teamviewer*i386.deb 2>/dev/null | wc -l`
if [ "$cnt" = "0" ]; then
wget https://download.teamviewer.com/download/teamviewer_i386.deb || error_exit "Sorry, we were unable to download TeamViewer" 
wait
fi
/usr/bin/dpkg -i $REPO_DIR/teamviewer*_i386.deb || error_exit "TeamViewer 11 installation failed! WTF?"

# Open TeamViewer-specific firewall ports
iptables -I OUTPUT -o lo -p tcp --dport 5939 -j ACCEPT
iptables -I OUTPUT -o lo -p udp --dport 5353 -j ACCEPT
#iptables -A OUTPUT -p tcp -m tcp --dport 5938 -j ACCEPT

echo
Confirm "Type y if you wish to keep the downloaded/saved distribution file" || rm $REPO_DIR/teamviewer*_i386.deb
echo
#
# Check for existence or previous TeamViewer config directory in $INSTALL_DIR
if [ -d "$OLD_DIR" ]; then
	mv $OLD_DIR $SET_DIR
fi
if [ -d "$SET_DIR" ]; then
	sudo -u amnesia ln -sf $SET_DIR /home/amnesia/.config/teamviewer11
else
	mkdir -p $SET_DIR
	chown amnesia:amnesia $SET_DIR
	sudo -u amnesia ln -s $SET_DIR /home/amnesia/.config/teamviewer11
	echo 
	echo "If you wish to make your Teamviewer settings persistent, copy the contents of the /home/amnesia/.config/teamviewer11 directory to /home/amnesia/Persistent/Packages/Settings/teamviewer11 ."
	echo
	echo "WARNING: Do NOT copy this directory to your Dotfiles persistent folder as this will cause an infinite loop at boot time. This is a TAILS bug."
	echo 
	read -n 1 -p "Press any key to launch the TeamViewer daemon ..."
fi
 
/usr/bin/sudo -u amnesia /usr/bin/notify-send -i /opt/teamviewer/tv_bin/desktop/teamviewer.png "TeamViewer Installed" "Open with Applications > Internet > TeamViewer"
/usr/bin/sudo -u amnesia /usr/bin/notify-send -i /opt/teamviewer/tv_bin/desktop/teamviewer.png "Set TeamViewer Proxy: Extras->Options->General->Proxy" "Manual Proxy IP socks5://127.0.0.1 Port 9050"
