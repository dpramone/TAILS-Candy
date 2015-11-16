#!/bin/bash

#########################################################################
# TAILS installer script for AIDE 0.16 file & directory integrity checker 
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

function insertAfter # file line newText
{
   local file="$1" line="$2" newText="$3"
   sed -i -e "/^$line$/a"$'\\\n'"$newText"$'\n' "$file"
}

Confirm() { read -sn 1 -p "$* [Y/N]? "; [[ ${REPLY:0:1} = [Yy] ]]; }

# Script main line
if [[ $EUID -ne 0 ]]; then
    echo "You need to run this as root" 1>&2
    exit 1
fi

cd /home/amnesia/Persistent || error_exit "No persistence found. Aborting"

clear
echo 
echo "This routine non-persistenly installs AIDE, a file & directory integrity checker."
echo "Settings and DB are kept in ~/Persistent/Packages/Settings/aide."
echo 
echo "If this is the first time you run AIDE, it is recommended you let"
echo "the script properly initialise the AIDE database and set up the"
echo "configuration settings for future AIDE checks."
echo 
echo "Source: http://aide.sourceforge.net/"
echo 
read -n 1 -p "Press any key to continue or Ctrl-C to abort ..."
echo

echo "Now installing AIDE and dependencies ..."
dpkg -s aide 2>/dev/null >/dev/null 
if [ $? -ne 0 ]; then
	/usr/bin/apt-get -y install aide=0.16~a2.git20130520-3~bpo70+1 aide-common=0.16~a2.git20130520-3~bpo70+1 bsd-mailx exim4-base exim4-config exim4-daemon-light
	/usr/bin/sudo -u amnesia /usr/bin/notify-send -i gnome-app-install "AIDE binaries installed" "Crontab entry created"
fi

# Adjust /etc/default/aide
sed -i "s/MAILTO=root/MAILTO=amnesia/" /etc/default/aide
sed -i "s/#CRON_DAILY_RUN=yes/CRON_DAILY_RUN=no/" /etc/default/aide
sed -i 's/# UPAC_CONFDIR="\/etc\/aide"/UPAC_CONFDIR="\/home\/amnesia\/Persistent\/Packages\/Settings\/aide"/' /etc/default/aide
sed -i "s/# UPAC_CONFD/UPAC_CONFD/" /etc/default/aide
sed -i "s/# UPAC_SETTINGSD/UPAC_SETTINGSD/" /etc/default/aide
# Add UPAC_MAINCONFIGFILE
grep -q 'UPAC_MAINCONFIGFILE' /etc/default/aide || insertAfter /etc/default/aide 'UPAC_CONFD="\$UPAC_CONFDIR\/aide\.conf\.d"' 'UPAC_MAINCONFIGFILE="\$UPAC_CONFDIR\/aide\.conf"'
# Add UPAC_AUTOCONFIGFILE
grep -q 'UPAC_AUTOCONFIGFILE' /etc/default/aide || insertAfter /etc/default/aide 'UPAC_CONFD="\$UPAC_CONFDIR\/aide\.conf\.d"' 'UPAC_AUTOCONFIGFILE="\$UPAC_CONFDIR\/aide\.conf\.autogenerated"'

# Do we already have a configuration in ~/Persistent/Packages/Settings/aide ?
configdir="/home/amnesia/Persistent/Packages/Settings/aide"
configfile="/home/amnesia/Persistent/Packages/Settings/aide/aide.conf"
dbfile="/home/amnesia/Persistent/Packages/Settings/aide/lib/aide.db.gz"
autoconfigfile="/home/amnesia/Persistent/Packages/Settings/aide/aide.conf.autogenerated"

# Create AIDE config and data directories
if [ ! -d "$configdir" ]; then
	echo "Creating AIDE config and data directories ..."
        mkdir /home/amnesia/Persistent/Packages/Settings/aide
        mkdir /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d
        mkdir /home/amnesia/Persistent/Packages/Settings/aide/aide.settings.d
        mkdir /home/amnesia/Persistent/Packages/Settings/aide/lib
	chown -R amnesia:amnesia /home/amnesia/Persistent/Packages/Settings/aide
fi

# Create base configuration file
if [ ! -f "$configfile" ]; then
	echo "Creating AIDE base configuration file aide.conf ..."
	cat <<EOF > /home/amnesia/Persistent/Packages/Settings/aide/aide.conf
# AIDE conf

# The daily cron job depends on these paths

@@define DBDIR /home/amnesia/Persistent/Packages/Settings/aide/lib
@@define LOGDIR /var/log/aide

# The location of the database to be read.
database=file:@@{DBDIR}/aide.db.gz
# The location of the database to be written.
database_out=file:@@{DBDIR}/aide.db.new.gz
database_new=file:@@{DBDIR}/aide.db.new.gz

gzip_dbout=yes

# Set to no to disable summarize_changes option.
summarize_changes=yes

# Set to no to disable grouping of files in report.
grouped=yes

# standard verbose level
verbose = 6
report_url=file:@@{LOGDIR}/aide.log
report_url=stdout

# Set to yes to print the checksums in the report in hex format
report_base16 = no

# if you want to sacrifice security for speed, remove some of these
# checksums. Whirlpool is broken on sparc and sparc64 (see #429180,
# #420547, #152203).
#Checksums = sha256+sha512+rmd160+haval+gost+crc32+tiger
Checksums = sha256+sha512+rmd160

# The checksums of the databases to be printed in the report
# Set to 'E' to disable.
database_attrs = Checksums

# check permissions, owner, group and file type
OwnerMode = p+u+g+ftype

# Check size and block count
Size = s+b

# Files that stay static
InodeData = OwnerMode+n+i+Size+l+X
StaticFile = m+c+Checksums

# Files that stay static but are copied to a ram disk on startup
# (causing different inode)
RamdiskData = InodeData-i

# Check everything
Full = InodeData+StaticFile

# Files that change their mtimes or ctimes but not their contents
VarTime = InodeData+Checksums

# Files that are recreated regularly but do not change their contents
VarInode = VarTime-i

# Files that change their contents during system operation
VarFile = OwnerMode+n+l+X

# Directories that change their contents during system operation
VarDir = OwnerMode+n+i+X

# Directories that are recreated regularly and change their contents
VarDirInode = OwnerMode+n+X

# Directories that change their mtimes or ctimes but not their contents
VarDirTime = InodeData

Normal = R+Checksums

# Logs are special: they are continously written to, may be compressed
# have their file name changed in different, mutually incompatibly ways
# and apprear and vanish at will. Handling this is a a complex and error-
# prone issue.
#
# This is best broken down in a number of small tasks:
#
#
# (A)
# While a live log is being written to, it doesn't change its mode and
# inode and its size only increases.
#
# (B)
# When a live log is rotated for the first time, it should not change
# its mode, may change its inode, and its size decreases. The size
# decrease may not be noticed by aide if the file had size x at the last
# aide run, was rotated in the mean time and was written to so that it
# had a size > x at the next aide run.
#
# (C)
# When a log is compressed, this looks to aide like the uncompressed
# file vanished (or was replaced by another file) and the compressed
# file appeared out of the blue. There is (currently) no way to
# associate the (gone) uncompressed file's contents with the (new)
# compressed file's contents
#
# (D)
# The actual log rotation may rename foo.{x}.bar to foo.{x+1}.bar without
# changing the other properties of the file
#
# (E)
# If only a given number of log generations is to be kept, foo.{y}.bar may
# vanish, but usually only when no foo.{z}.bar exists for z>y.
#
# (F)
# The set of files foo.{x}.bar to foo.{y}.bar is called a "log series"
# in aide terms, with the lowest x being called the "LoSerMember" element
# and the highest y being called the "HiSerMember" element, and the z
# with x<z<y simple called "SerMember". The Lo and Hi members need to
# be special cased in aide configuration.
#
#
# This is an example of the normal life of a log named foo in a logrotate
# configuration using a configuration at it is commonly used in Debian
# (from old to new):
#     1 logrotate deletes HiSerMember foo.{y}.gz
#     2 logrotate rotates SerMember foo.{z-1}.gz to foo.{z}.gz for all
#       z with 3<z<=y. This includes rotation of foo.{y-1}.gz to
#       foo.{y}.gz and foo.2.gz to foo.3.gz
#     3 logrotate compresses foo.1 to foo.2.gz, creating LoSerMember foo.2.gz
#     4 logrotate rotates foo to foo.1 (a simple rename)
#     5 logrotate creates new, empty foo
#     6 foo daemon logs to foo - foo grows in size
#
# we need the following rules:
# /var/log/foo$ Log
# /var/log/foo$ FreqRotLog
#    this takes care of the growing live log (step 7). The "Log" rule
#    is appropriate for logs that are not rotated daily as rotation
#    might be reported (if the file size has decreased since the last
#    aide run). For daily rotated logs, the "FreqRotLog" may be more
#    appropriate.
# /var/log/foo\.1$ LowLog
#    this takes care of step 5.
# /var/log/foo\.2\.gz$ LoSerMemberLog
#    this allows yet unknown new files to appear with a \.2\.gz extension,
#    covering step 3.
# /var/log/foo\.[3..y-1]\.gz$ SerMemberLog
#    this watches the log files as they wander through the Series,
#    changing only their file name but not their contents or metadata,
#    covering step 2.
#    Please note that [3..y-1] needs to be a manually crafted regexp covering
#    all numbers between 3 and y-1.
# /var/log/foo\.y\.gz$ HiSerMemberLog
#    finally, the last element of the Series is allowed to vanish without
#    being reported, covering step 1.
#
# Please note that these example rules need to be adapted to the logrotate
# configuration for the log. Compression may be disabled or lead to a different
# extension, the dateext option may be used, old logs might be held in a
# different place, a log series does not necessarily need to be compressed etc.
#
# Please note that savelog rotates the live log to .0 and not to .1 as it
# is logrotates (changeable) default.


# Logs grow in size. Log rotation of these logs will be reported, so
# this should only be used for logs that are not rotated daily.
Log = OwnerMode+n+S+X

# Logs that are frequently rotated
FreqRotLog = Log-S

# The first instance of a rotated log: After the log has stopped being
# written to, but before rotation
LowLog = Log-S

# Rotated logs change their file name but retain all their other properties
SerMemberLog  = Full+I

# The first instance of a compressed, rotated log: After a LowLog was
# compressed.
LoSerMemberLog = SerMemberLog+ANF

# The last instance of a compressed, rotated log: After this name, a log
# will be removed
HiSerMemberLog = SerMemberLog+ARF

# Not-yet-compressed log created by logrotate's dateext option:
# These files appear one rotation (renamed from the live log) and are gone
# the next rotation (being compressed)
LowDELog = SerMemberLog+ANF+ARF

# Compressed log created by logrotate's dateext option: These files appear
# once and are not touched any more.
SerMemberDELog = Full+ANF

# For daemons that log to a variable file name and have the live log
# hardlinked to a static file name
LinkedLog = Log-n

# Next decide what directories/files you want in the database.

/home/amnesia/Persistent        Normal
/live/persistence       Normal

EOF
	chown amnesia:amnesia $configfile
	chmod 644 $configfile
 
	echo "Populating aide.conf.d with Debian/TAILS specific entries ..."
	rm -f /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/*
	ln -s /etc/aide/aide.conf.d/10_aide_constants /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/10_aide_constants
	ln -s /etc/aide/aide.conf.d/10_aide_distribution /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/10_aide_distribution
	ln -s /etc/aide/aide.conf.d/10_aide_hostname /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/10_aide_hostname
	ln -s /etc/aide/aide.conf.d/10_aide_run /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/10_aide_run
	ln -s /etc/aide/aide.conf.d/10_aide_year /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/10_aide_year
	ln -s /etc/aide/aide.conf.d/31_aide_adjtime /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_adjtime
	cat << EOF > /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_aide
/home/amnesia/Persistent/Packages/Settings/aide/lib/aide\.db(\.new)?$ VarFile
!/home/amnesia/Persistent/Packages/Settings/aide/lib/aide\.conf\.autogenerated$
/home/amnesia/Persistent/Packages/Settings/aide/lib VarDir
/var/log/aide/aide\.log(\.0)?$ LowLog
/var/log/aide/aide\.log\.1\.gz$ LoSerMemberLog
/var/log/aide/aide\.log\.[2-5]\.gz$ SerMemberLog
/var/log/aide/aide\.log\.6\.gz$ HiSerMemberLog
/var/log/aide$ VarDir
!/@@{RUN}/aide$
!/@@{RUN}/aide\.lock$
!/@@{RUN}/aide/cron\.daily\.lock$
!/@@{RUN}/aide/cron\.daily$
!/@@{RUN}/aide/cron\.daily/((error|a(run|err))log|mailfile)$
EOF
	ln -s /etc/aide/aide.conf.d/31_aide_alsa /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_alsa
	ln -s /etc/aide/aide.conf.d/31_aide_apt /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_apt
	ln -s /etc/aide/aide.conf.d/31_aide_apt-file /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_apt-file
	ln -s /etc/aide/aide.conf.d/31_aide_btmp /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_btmp
	ln -s /etc/aide/aide.conf.d/31_aide_clamav /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_clamav
	ln -s /etc/aide/aide.conf.d/31_aide_clamav-freshclam /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_clamav-freshclam
	ln -s /etc/aide/aide.conf.d/31_aide_cups /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_cups
	ln -s /etc/aide/aide.conf.d/31_aide_dbus /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_dbus
	ln -s /etc/aide/aide.conf.d/31_aide_debconf /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_debconf
	ln -s /etc/aide/aide.conf.d/31_aide_dhcp3-client /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_dhcp3-client
	ln -s /etc/aide/aide.conf.d/31_aide_dpkg /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_dpkg
	ln -s /etc/aide/aide.conf.d/31_aide_exim4 /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_exim4
	cat << EOF > /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_gpg
/home/amnesia/.gnupg/random_seed$ VarFile
EOF
	ln -s /etc/aide/aide.conf.d/31_aide_ifplugd /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_ifplugd
	ln -s /etc/aide/aide.conf.d/31_aide_ifupdown /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_ifupdown
	ln -s /etc/aide/aide.conf.d/31_aide_initramfs-tools /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_initramfs-tools
	ln -s /etc/aide/aide.conf.d/31_aide_initscripts /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_initscripts
	ln -s /etc/aide/aide.conf.d/31_aide_laptop-mode-tools /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_laptop-mode-tools
	ln -s /etc/aide/aide.conf.d/31_aide_lastlog /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_lastlog
	ln -s /etc/aide/aide.conf.d/31_aide_logrotate /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_logrotate
	ln -s /etc/aide/aide.conf.d/31_aide_lvm2 /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_lvm2
	ln -s /etc/aide/aide.conf.d/31_aide_man /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_man
	ln -s /etc/aide/aide.conf.d/31_aide_modules /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_modules
	ln -s /etc/aide/aide.conf.d/31_aide_network /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_network
	ln -s /etc/aide/aide.conf.d/31_aide_pcscd /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_pcscd
	ln -s /etc/aide/aide.conf.d/31_aide_pm-utils /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_pm-utils
	ln -s /etc/aide/aide.conf.d/31_aide_resolvconf /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_resolvconf
	ln -s /etc/aide/aide.conf.d/31_aide_rkhunter /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_rkhunter
	ln -s /etc/aide/aide.conf.d/31_aide_root-dotfiles /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_root-dotfiles
	ln -s /etc/aide/aide.conf.d/31_aide_rsyslog /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_rsyslog
	ln -s /etc/aide/aide.conf.d/31_aide_snmpd /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_snmpd
	ln -s /etc/aide/aide.conf.d/31_aide_sudo /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/31_aide_sudo
	chown amnesia:amnesia /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d/*

	# Create relevant symlinks to AIDE settings directory
	echo "Populating aide.settings.d with Debian/TAILS specific entries ..."
	rm -f /home/amnesia/Persistent/Packages/Settings/aide/aide.settings.d/*
	ln -s /etc/aide/aide.settings.d/10_aide_sourceslist /home/amnesia/Persistent/Packages/Settings/aide/aide.settings.d/10_aide_sourceslist
	ln -s /etc/aide/aide.settings.d/31_aide_apt_settings /home/amnesia/Persistent/Packages/Settings/aide/aide.settings.d/31_aide_apt_settings
	chown amnesia:amnesia /home/amnesia/Persistent/Packages/Settings/aide/aide.settings.d/*

fi

# Initialise AIDE DB
if [ ! -f "$dbfile" ]; then

	echo
	if Confirm "Would you like to initialise AIDE now? This will take a while. "; then
		echo
		update-aide.conf -d /home/amnesia/Persistent/Packages/Settings/aide -D /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.d -S /home/amnesia/Persistent/Packages/Settings/aide/aide.settings.d --mainconfigfile /home/amnesia/Persistent/Packages/Settings/aide/aide.conf -a /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.autogenerated -o /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.autogenerated --verbose --keepcomments || error_exit "Something went horribly wrong creating our AIDE configuration file."
		chown amnesia:amnesia /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.autogenerated
		echo "Initialising AIDE database now. Please be patient ..."
		/usr/bin/aide -i -c /home/amnesia/Persistent/Packages/Settings/aide/aide.conf.autogenerated -V && mv /home/amnesia/Persistent/Packages/Settings/aide/lib/aide.db.new.gz /home/amnesia/Persistent/Packages/Settings/aide/lib/aide.db.gz 
		chown amnesia:amnesia /home/amnesia/Persistent/Packages/Settings/aide/lib/aide.db.gz
		echo "AIDE database initialised."
	fi
fi

if [ -f "$autoconfigfile" ]; then
	ln -sf $autoconfigfile /var/lib/aide/aide.conf.autogenerated
	if [ -f "$dbfile" ]; then
	# Create menu item
		cat <<EOF > /home/amnesia/.local/share/applications/aide.desktop
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=AIDE Integrity Check
GenericName=AIDE Integrity Check
Comment=AIDE File & Directory Integrity Check
Icon=checkbox
Terminal=true
Type=Application
Categories=System;
Exec=bash -c 'echo "Initialising AIDE integrity check ... Please be patient. This may take a while" ; sudo /usr/bin/aide.wrapper --check  ; read -n 1 -p "Press any key to finish up."'
EOF
		chown amnesia:amnesia /home/amnesia/.local/share/applications/aide.desktop
		chmod 600 /home/amnesia/.local/share/applications/aide.desktop
		/usr/bin/sudo -u amnesia /usr/bin/notify-send -i checkbox "AIDE successfully installed" "Applications -> System Tools -> AIDE Integrity Check"
	fi
fi

