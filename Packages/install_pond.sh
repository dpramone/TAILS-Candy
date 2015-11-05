#!/bin/bash

#########################################################################
# TAILS installer script for Pond
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

# Script main line
clear
echo "This routine will persistently install a Pond"
echo "asynchronous messaging client in ~/Persistent/go"
echo "Source: https://pond.imperialviolet.org/"
echo
echo "You need to have TAILS persistence configured."
echo "The script will exit gracefully if this is not the case."
echo
echo "ATTENTION: To access Pond in TAILS, you need to"
echo "re-run this script after every TAILS (re)boot."
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

cd /live/persistence/TailsData_unlocked/dotfiles || error_exit "No dotfiles persistence found. Sorry."

PERSISTENT=/home/amnesia/Persistent
PKG_DIR=$PERSISTENT/Packages/go

# This script should not be run as root
if [[ $EUID -eq 0 ]]; then
	echo
        error_exit "Please do not run this script with sudo or as root"
fi

#
# Install Pond if Pond client not installed
#
client=/home/amnesia/Persistent/go/bin/client
if [ ! -f "$client" ]; then

/bin/echo "Installing Pond ..."
echo 'export GOPATH=$HOME/Persistent/go' >> ~/.bashrc
export GOPATH=$HOME/Persistent/go
mkdir $GOPATH
alias pond-install-deps='sudo apt-get install libtspi1 libgtkspell-3-0'
alias pond='$GOPATH/bin/client'
alias pond-cli='$GOPATH/bin/client --cli'
alias pond-build='sudo bash -c "sudo apt-get update && apt-get install -y -t testing golang && apt-get install -y gcc git mercurial libgtk-3-dev libgtkspell-3-dev libtspi-dev trousers" && mkdir -p /home/amnesia/Persistent/go/src/golang.org/x && cd /home/amnesia/Persistent/go/src/golang.org/x && git clone https://github.com/golang/crypto && git clone https://github.com/golang/net && go get -u -tags ubuntu github.com/agl/pond/client && echo "Success" || echo "Sorry, something went wrong."'
alias|grep pond >> ~/.bashrc
. ~/.bashrc
# pond-build
sudo bash -c "sudo apt-get update && apt-get install -y -t testing golang && apt-get install -y gcc git mercurial libgtk-3-dev libgtkspell-3-dev libtspi-dev trousers" && mkdir -p /home/amnesia/Persistent/go/src/golang.org/x && cd /home/amnesia/Persistent/go/src/golang.org/x && git clone https://github.com/golang/crypto && git clone https://github.com/golang/net && go get -u -tags ubuntu github.com/agl/pond/client && echo "Success" || echo "Sorry, something went wrong."
#
/usr/bin/notify-send "Pond has been installed." "Open with Applications > Internet > Pond"

else

# Install Pond dependencies if Pond client already present
#

#pond-install-deps
/bin/echo "Installing Pond runtime dependencies only ..."
sudo apt-get install libtspi1 libgtkspell-3-0
/usr/bin/notify-send "Pond dependencies have been installed." "Open with Applications > Internet > Pond"

fi

#
# Create menu item
#
    cat <<EOF > /home/amnesia/.local/share/applications/pond.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Pond Messenger
GenericName=Pond
Comment=Secure asynchronous messaging
Exec=/home/amnesia/Persistent/go/bin/client
Icon=indicator-message-new
Terminal=false
Categories=Network;
EOF
