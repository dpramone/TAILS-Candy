#!/bin/bash

#########################################################################
# TAILS installer script for RKHUNTER 1.4.2
#
# Although RKHUNTER can be installed from Debian repositories, we prefer
# to use the most recent version available from the project site
#
# Execute with "rkhunter -c"
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
echo "Verification will fail until you have trusted the RKHUNTER public key."
echo
sudo -u amnesia gpg --list-keys $1 || sudo -u amnesia gpg --recv $1
#
# Download distribution file signature
#
echo
wget -O rkhunter-1.4.2.tar.gz.asc http://sourceforge.net/projects/rkhunter/files/rkhunter/1.4.2/rkhunter-1.4.2.tar.gz.asc/download || echo "Unable to download signature file"
wait
if [ -s ./rkhunter-1.4.2.tar.gz.asc ]; then
# Verify distribution file
        local sig="rkhunter-1.4.2.tar.gz.asc"
        local output="$(sudo -u amnesia gpg -v "$sig" 2>&1)"
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
	echo "Unable to fetch signature file and verify downloaded Rkhunter distribution file"
fi

#
# Download distribution file SHA256 checksum and verify
#
wget -O rkhunter-1.4.2.tar.gz.sha256 http://sourceforge.net/projects/rkhunter/files/rkhunter/1.4.2/rkhunter-1.4.2.tar.gz.sha256/download || echo "Unable to download checksum file"
wait
if [ -s ./rkhunter-1.4.2.tar.gz.sha256 ]; then
# Verify SHA256 checksum
        local checksum=`grep rkhunter rkhunter-1.4.2.tar.gz.sha256 | sed -e 's/\s.*$//'`
        local calcval=`sha256sum ./rkhunter-1.4.2.tar.gz | sed -e 's/\s.*$//'`
        test "$checksum" = "$calcval" && echo "SHA256 checksum OK!" || echo "WARNING: SHA256 checksum values did not match!"
else
	echo 
	echo "Unable to fetch SHA256 checksum file to verify against downloaded Rkhunter distribution file"
fi

echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort installation ..."

}

Confirm() { read -sn 1 -p "$* [Y/N]? "; [[ ${REPLY:0:1} = [Yy] ]]; }

# Main line

clear
echo 
echo "This script will install Rootkit Hunter 1.4.2"
echo
echo "Source: http://sourceforge.net/projects/rkhunter/files/rkhunter/1.4.2/"
echo
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."

PERSISTENT=/home/amnesia/Persistent

DOT_DIR=/live/persistence/TailsData_unlocked/dotfiles
cd $DOT_DIR || error_exit "No dotfiles persistence found. Aborting"

REPO_DIR=/home/amnesia/Persistent/Packages/Repo

# This script should not be run as root
if [[ $EUID -ne 0 ]]; then
	echo
        error_exit "This script should not be run as root."
fi

# Was rkhunter previously installed ?
installer="$PERSISTENT/rkhunter-1.4.2/installer.sh"
if [ ! -f "$installer" ]; then

	# Do we already have a copy of the Rkhunter distribution file ?
	cd $REPO_DIR

	distfile=rkhunter-1.4.2.tar.gz
	installfile=$REPO_DIR/$distfile

	if [ ! -f "$installfile" ]; then
		wget -O rkhunter-1.4.2.tar.gz http://sourceforge.net/projects/rkhunter/files/rkhunter/1.4.2/rkhunter-1.4.2.tar.gz/download || error_exit "Unable to download Rkhunter distribution file. Bailing out."
	fi

	# Verify GPG signature of downloaded distribution file against Rkhunter public key
	secring="/home/amnesia/.gnupg/secring.gpg"
	if [ -f "$secring" ]; then checksig 0xEA5F4CD3A65F5E17 ; fi

	mv $distfile $PERSISTENT/
	cd $PERSISTENT
	tar -xzvf $distfile
	chown amnesia:amnesia rkhunter-1.4.2.tar.gz*
	mv rkhunter-1.4.2.tar.gz* $REPO/
	chown amnesia:amnesia $REPO/rkhunter-1.4.2.tar.gz*
	chown -R amnesia:amnesia $PERSISTENT/rkhunter-1.4.2

	echo
	Confirm "Do you wish to keep the downloaded/saved distribution file(s)? " || rm $REPO_DIR/rkhunter-1.4.2.tar.gz*
	echo
fi

# Install Unhide
dpkg -s unhide  2>/dev/null >/dev/null || sudo apt-get install unhide

cd $PERSISTENT/rkhunter-1.4.2
./installer.sh --layout default --install

# Create local config file
/bin/cat <<EOF > /etc/rkhunter.conf.local
USE_SYSLOG=authpriv.notice
DISABLE_TESTS=suspscan deleted_files
PKGMGR=DPKG
USER_FILEPROP_FILES_DIRS=/home/amnesia/Persistent
SCRIPTWHITELIST=/usr/sbin/adduser
SCRIPTWHITELIST=/usr/bin/ldd
SCRIPTWHITELIST=/usr/bin/wget
SCRIPTWHITELIST=/usr/bin/lwp-request
SCRIPTWHITELIST=/bin/which
ALLOWHIDDENDIR=/etc/.java
EOF
chmod 640 /etc/rkhunter.conf.local

rkhunter --update
rkhunter --propupdate

# Create cron entry

/bin/cat <<EOF > /etc/cron.daily/rkhunter
#!/bin/sh
echo "Rkhunter Daily Scan Report Amnesia" > /home/amnesia/Desktop/rkhunter.log
echo " " >> /home/amnesia/Desktop/rkhunter.log
/usr/local/bin/rkhunter --versioncheck >> /home/amnesia/Desktop/rkhunter.log
/usr/local/bin/rkhunter --update >> /home/amnesia/Desktop/rkhunter.log
echo " " >> /home/amnesia/Desktop/rkhunter.log
/usr/local/bin/rkhunter --cronjob --report-warnings-only >> /home/amnesia/Desktop/rkhunter.log
chown amnesia:amnesia /home/amnesia/Desktop/rkhunter.log
EOF
chmod 755 /etc/cron.daily/rkhunter

sudo -u amnesia /usr/bin/notify-send -i /home/amnesia/Persistent/Packages/Settings/Gnome/icons/Malware64.png "Rkhunter Installed" "Cronjob created"

echo
read -n 1 -p "Press any key to launch Rkhunter now or Ctrl-C to finish up ..."

/usr/local/bin/rkhunter -c

echo
Confirm "Would you like to examine the /var/log/rkhunter.log file now? " && more /var/log/rkhunter.log
echo
echo
read -n 1 -p "All done. Press any key to finish up ..."

