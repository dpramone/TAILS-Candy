#!/bin/bash

#########################################################################
# TAILS installer/bootstrap script for Tahoe-LAFS distributed file system
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

# Main line

if [[ $EUID -ne 0 ]]; then
    echo "You need to run this as root: sudo ./install_tahoe-lafs.sh ." 1>&2
    exit 1
fi

clear
echo "**********************************************************"
echo "*TAILS installer & bootstrap for Tahoe-LAFS + backup tool*"
echo "**********************************************************"
echo "1) Installs Tahoe-LAFS .deb packages and dependencies on a per-session basis in order to minimize attack surface when not in use."
echo "2) Permanently installs configuration files in ~/Persistent/Packages/Settings/tahoe (without I2P) and ~/Persistent/Packages/Settings/tahoe_with_i2p (with I2P) to preserve settings between TAILS sessions."
echo "3) (Optional) LAFS backup tool is persistently installed in ~/Persistence , dependencies in ~/Persistent/Packages/Repo"
echo 
echo "Requirements: You must have enabled TAILS persistence. If not, we will exit gracefully."
echo 
echo "Source: https://www.tahoe-lafs.org/ "
echo 
read -n 1 -p "Press any key to continue..."
echo

PERSISTENT=/home/amnesia/Persistent

# Exit if no TAILS persistence
cd $Persistent || error_exit "No TAILS persistence found. Bailing out."

# Silly way to find out if we booted with or without i2p
file="/usr/share/applications/i2p-browser.desktop"
if [ -f "$file" ]
then

# Add KillYourTV repositories
echo "Adding KillYourTV debian repositories"

    cat <<EOF > /etc/apt/sources.list.d/i2p_wheezy.list
deb tor+http://kytvi2pll2jw5gip.onion/debian/ wheezy main




EOF

    cat <<EOF > /etc/apt/sources.list.d/i2p_jessie.list
deb tor+http://kytvi2pll2jw5gip.onion/debian/ jessie main




EOF

    cat <<EOF > /etc/apt/sources.list.d/i2p_sid.list
deb tor+http://kytvi2pll2jw5gip.onion/debian/ sid main




EOF

# Reload repositories
/usr/bin/apt-get update

echo "Now installing Tahoe LAFS with I2P. This may take a while ..."
echo
# Install Tahoe LAFS over I2P & dependencies
/usr/bin/apt-get --yes --force-yes install i2p-keyring killyourtv-keyring
# Reload repositories after key additions for KillYourTV repos so i2p-tahoe-lafs install doesn't complain
/usr/bin/apt-get update

/usr/bin/apt-get install libcrypto++9 python-pycryptopp python-crypto python-i2p-foolscap python-mock python-nevow python-openssl python-pyasn1 python-setuptools python-simplejson python-twisted python-twisted-bin python-twisted-conch python-twisted-core python-twisted-lore python-twisted-mail python-twisted-names python-twisted-news python-twisted-runner python-twisted-web python-twisted-words python-zfec i2p-tahoe-lafs grid-updates binfmt-support fastjar itoopie jarwrapper libapache-pom-java libcommons-logging-java libcommons-parent-java libxmlgraphics-commons-java

# Create symbolic link from previous installation saved in Persistent/Packages/Settings/tahoe to ~/.tahoe

tahoedir="/home/amnesia/Persistent/Packages/Settings/tahoe_with_i2p"
if [ -d "$tahoedir" ]
then
sudo -u amnesia ln -sf /home/amnesia/Persistent/Packages/Settings/tahoe_with_i2p /home/amnesia/.tahoe
else
sudo -u amnesia mkdir /home/amnesia/Persistent/Packages/Settings/tahoe_with_i2p
sudo -u amnesia ln -sf /home/amnesia/Persistent/Packages/Settings/tahoe_with_i2p /home/amnesia/.tahoe
sudo -u amnesia /usr/bin/tahoe create-client --nickname=nimoy
# Configure tahoe.cfg and introducers file

sudo -u amnesia cat <<EOF > /home/amnesia/Persistent/Packages/Settings/tahoe_with_i2p/tahoe.cfg
# -*- mode: conf; coding: utf-8 -*-

# This file controls the configuration of the Tahoe node that
# lives in this directory. It is only read at node startup.
# For details about the keys that can be set here, please
# read the 'docs/configuration.rst' file that came with your
# Tahoe installation.


[node]
nickname = nimoy
web.port = tcp:3456:interface=127.0.0.1
web.static = public_html
http_proxy = 127.0.0.1:4444
# **IMPORTANT**
# You NEED to configure tub.location when running
# an I2P-enabled Tahoe-LAFS node. Otherwise your IP
# can be leaked to the introducers!
# Read the docs and/or come to #tahoe-lafs on Irc2P for assistance.
#tub.port =
tub.location = 
#log_gatherer.furl =
#timeout.keepalive =
#timeout.disconnect =
#ssh.port = 8022
#ssh.authorized_keys_file = ~/.ssh/authorized_keys

[client]
# Which services should this client connect to?
introducer.furl = pb://c6w5ernw7y7rp3uwmdyu5clujyt2y4m4@w2zrwz5gplkkufix7cb4gmxfbrkwg2abnsgk62bm5iifzlahe7kq.b32.i2p.xyz/introducer
helper.furl =
#key_generator.furl =
#stats_gatherer.furl =

# What encoding parameters should this client use for uploads?
#shares.needed = 3
#shares.happy = 7
#shares.total = 10

[storage]
# Shall this node provide storage service?
enabled = false
#readonly =
reserved_space = 1G
#expire.enabled =
#expire.mode =

[helper]
# Shall this node run a helper service that clients can use?
enabled = false

[drop_upload]
# Shall this node automatically upload files created or modified in a local directory?
enabled = false
# To specify the target of uploads, a mutable directory writecap URI must be placed
# in 'private/drop_upload_dircap'.
local.directory = ~/drop_upload

EOF

sudo -u amnesia cat <<EOF > /home/amnesia/Persistent/Packages/Settings/tahoe_with_i2p/introducers
pb://c6w5ernw7y7rp3uwmdyu5clujyt2y4m4@w2zrwz5gplkkufix7cb4gmxfbrkwg2abnsgk62bm5iifzlahe7kq.b32.i2p.xyz/introducer
pb://ifwpslh5f4jx2s3tzkkj4cyymrcxcunz@bvkb2rnvjbep4sjz.onion:58086/introducer
pb://c6w5ernw7y7rp3uwmdyu5clujyt2y4m4@w2zrwz5gplkkufix7cb4gmxfbrkwg2abnsgk62bm5iifzlahe7kq.b32.i2p.xyz/introducer
pb://exupps5kk3amc5iq4q6f5ahggkm4s5fl@oj7cffq5fnk46iw3i3h2sdgncxrqbxm7wh6i4h2cbpmqsydygkcq.b32.i2p.xyz/introducer
pb://md2tltfmdjvzptg4mznha5zktaxatpmz@5nrsgknvztikjxnpvidlokquojjlsudf7xlnrnyobj7e7trdmuta.b32.i2p.xyz/introducer
pb://fmcbgy7zd6ubrbphilmrlocvb7f327z5@gdr3tt5uewgnm7r7xn54k2qikf2kuwwegjjsnkz44pjticcacsua.b32.i2p.xyz/introducer
pb://tq7rx35yopkvodmsxkqra4qqkbho3yaa@6ga2r2h2fyq6tzcyh6bf3hpio3i7r4edadbq7l4wnh4y62taj6ia.b32.i2p.xyz/introducer
pb://cys5w43lvx3oi5lbgk6liet6rbguekuo@sagljtwlctcoktizkmyv3nyjsuygty6tpkn5riwxlruh3f2oze2q.b32.i2p.xyz/introducer
pb://r3bs6joub24gtsofe7ohnnjcnwfmo2jy@qaihdh5z7osn7tc3326ahv3z46badiuaulff43wchmap7skg7euq.b32.i2p.xyz/42mrbm7zxmjemz6hzejo3i7aunx4eoun
pb://hckqqn4vq5ggzuukfztpuu4wykwefa6d@publictestgrid.twilightparadox.com:50213,publictestgrid.lukas-pirl.de:50213,publictestgrid.e271.net:50213,198.186.193.74:50213,68.34.102.231:50213/introducer
EOF

fi

echo "Starting Tahoe LAFS daemon ..."
sudo -u amnesia /usr/bin/tahoe restart

# Punch hole in firewall on loopback interface for Itoopie panel applet
/sbin/iptables -I OUTPUT -o lo -p tcp --sport 7650 -j ACCEPT
# Punch hole in firewall on loopback interface for Tahoe LAFS web interface
/sbin/iptables -I OUTPUT -o lo -p tcp --sport 3456 -j ACCEPT

# Update list of Tahoe LAFS introducers
/usr/bin/sudo -u amnesia /usr/bin/grid-updates -s

/usr/bin/sudo -u amnesia /usr/bin/notify-send "Tahoe LAFS over I2P Installed" "Web interface on 127.0.0.1:3456 with Applications > Internet > 2P Browser"

else

# 
# TAILS Not booted with I2P
#
echo "Now installing Tahoe LAFS. This may take a while because of Python dependency hell..."
echo " "

/usr/bin/apt-get install libcrypto++9 python-crypto python-foolscap python-mock python-nevow python-openssl python-pyasn1 python-pycryptopp python-setuptools python-simplejson python-twisted python-twisted-bin python-twisted-conch python-twisted-core python-twisted-lore python-twisted-mail python-twisted-names python-twisted-news python-twisted-runner python-twisted-web python-twisted-words python-zfec tahoe-lafs

# Install backup tool too?
while true; do
    read -p "Do you wish to enable the Tahoe LAFS backup tool too? y/n" yn
    case $yn in
        [Yy]* ) 
		cd /home/amnesia/Persistent/Packages/Repo
		# Installing dependencies
		/usr/bin/apt-get install python-yaml python-ply python-pycparser python-cffi
		# Installing/configuring layered-yaml-attrdict-config module
		yamldir=/home/amnesia/Persistent/Packages/Repo/layered-yaml-attrdict-config
		if [ ! -d $yamldir ]; then
		cd /home/amnesia/Persistent/Packages/Repo
		git clone https://github.com/mk-fg/layered-yaml-attrdict-config.git || break
		chown -R amnesia:amnesia $yamldir
		fi
		cd /home/amnesia/Persistent/Packages/Repo/layered-yaml-attrdict-config
		/usr/bin/sudo -u amnesia python setup.py install --user
		# Installing/configuring lafs-backup-tool
		backupdir=/home/amnesia/Persistent/lafs-backup-tool
		if [ ! -d $backupdir ]; then
		cd /home/amnesia/Persistent
		git clone https://github.com/mk-fg/lafs-backup-tool.git || break
		chown -R amnesia:amnesia $backupdir
		fi
		cd /home/amnesia/Persistent/lafs-backup-tool
		echo " "
		echo "Backup tool in ~/Persistent/lafs-backup-tool"
		/usr/bin/sudo -u amnesia ./lafs-backup-tool --help
		echo " "
		break
		;;
        [Nn]* ) break;;
        * ) echo "Please answer (y)es or (n)o.";;
    esac
done

tahoedir="/home/amnesia/Persistent/Packages/Settings/tahoe"
if [ -d "$tahoedir" ]
then
sudo -u amnesia ln -sf /home/amnesia/Persistent/Packages/Settings/tahoe /home/amnesia/.tahoe
echo "Starting Tahoe LAFS daemon ..."
sudo -u amnesia /usr/bin/tahoe start

# Poke a hole in the firewall for TCP 3456
/sbin/iptables -I OUTPUT -o lo -p tcp --dport 3456 -j ACCEPT

grid_news_read_cap=URI:DIR2-RO:j7flrry23hfiix55xdakehvayy:pn7wdmukxulpwxc3khdwqcmahdusgvfljjt4gx5oe4z35cyxngga
    echo
    echo "This is the write capability for our 'tahoe:' (default) directory:"
    sudo -u amnesia /usr/bin/tahoe list-aliases | grep tahoe
    echo "(Might want to save that somewhere else)"
    echo
    echo "To access our tahoe directory in a browser, run this command:"
    echo "      tahoe webopen tahoe:"
    echo
    echo "To read the latest Onion Grid News, run this:"
    echo "      tahoe webopen Onion-Grid-News:Latest/index.html"

else
sudo -u amnesia mkdir /home/amnesia/Persistent/Packages/Settings/tahoe

web_port="tcp:3456:interface=127.0.0.1"
intro_furl=pb://ifwpslh5f4jx2s3tzkkj4cyymrcxcunz@bvkb2rnvjbep4sjz.onion:58086/introducer

sudo -u amnesia /usr/bin/tahoe create-client --introducer=$intro_furl --nickname=nimoy --node-directory=/home/amnesia/Persistent/Packages/Settings/tahoe

perl -lni.bak -e 'print '\
'm/shares.happy/  && "shares.happy=3"  ||'\
'm/shares.needed/ && "shares.needed=2" ||'\
'm/shares.total/  && "shares.total=5"  ||'\
'm/tub.location/  && "tub.location = client.fakelocation:1" '\
'|| $_' "/home/amnesia/Persistent/Packages/Settings/tahoe/tahoe.cfg"

# Create introducers list
sudo -u amnesia cat <<EOF > /home/amnesia/Persistent/Packages/Settings/tahoe/introducers
pb://c6w5ernw7y7rp3uwmdyu5clujyt2y4m4@w2zrwz5gplkkufix7cb4gmxfbrkwg2abnsgk62bm5iifzlahe7kq.b32.i2p.xyz/introducer
pb://ifwpslh5f4jx2s3tzkkj4cyymrcxcunz@bvkb2rnvjbep4sjz.onion:58086/introducer
pb://c6w5ernw7y7rp3uwmdyu5clujyt2y4m4@w2zrwz5gplkkufix7cb4gmxfbrkwg2abnsgk62bm5iifzlahe7kq.b32.i2p.xyz/introducer
pb://exupps5kk3amc5iq4q6f5ahggkm4s5fl@oj7cffq5fnk46iw3i3h2sdgncxrqbxm7wh6i4h2cbpmqsydygkcq.b32.i2p.xyz/introducer
pb://md2tltfmdjvzptg4mznha5zktaxatpmz@5nrsgknvztikjxnpvidlokquojjlsudf7xlnrnyobj7e7trdmuta.b32.i2p.xyz/introducer
pb://fmcbgy7zd6ubrbphilmrlocvb7f327z5@gdr3tt5uewgnm7r7xn54k2qikf2kuwwegjjsnkz44pjticcacsua.b32.i2p.xyz/introducer
pb://tq7rx35yopkvodmsxkqra4qqkbho3yaa@6ga2r2h2fyq6tzcyh6bf3hpio3i7r4edadbq7l4wnh4y62taj6ia.b32.i2p.xyz/introducer
pb://cys5w43lvx3oi5lbgk6liet6rbguekuo@sagljtwlctcoktizkmyv3nyjsuygty6tpkn5riwxlruh3f2oze2q.b32.i2p.xyz/introducer
pb://r3bs6joub24gtsofe7ohnnjcnwfmo2jy@qaihdh5z7osn7tc3326ahv3z46badiuaulff43wchmap7skg7euq.b32.i2p.xyz/42mrbm7zxmjemz6hzejo3i7aunx4eoun
pb://hckqqn4vq5ggzuukfztpuu4wykwefa6d@publictestgrid.twilightparadox.com:50213,publictestgrid.lukas-pirl.de:50213,publictestgrid.e271.net:50213,198.186.193.74:50213,68.34.102.231:50213/introducer
EOF

sudo -u amnesia ln -sf /home/amnesia/Persistent/Packages/Settings/tahoe /home/amnesia/.tahoe

echo "Starting Tahoe LAFS daemon ..."
sudo -u amnesia /usr/bin/tahoe start

# Poke a hole in the firewall for TCP 3456
/sbin/iptables -A OUTPUT -o lo -p tcp --dport 3456 -j ACCEPT

set +x

count=0
n=3
	while [ "$count" -lt "$n" ]; do
	count=$(http_proxy="" curl -s http://127.0.0.1:3456/|grep 'Connected to'|egrep -Eo '[0-9]+')
	echo -en "\x0d$(date) Connected to $count servers (waiting for $n)"
	sleep 1
	done
echo

grid_news_read_cap=URI:DIR2-RO:j7flrry23hfiix55xdakehvayy:pn7wdmukxulpwxc3khdwqcmahdusgvfljjt4gx5oe4z35cyxngga
echo "Creating 'tahoe:' alias"
    sudo -u amnesia /usr/bin/tahoe create-alias tahoe || true
    echo Adding Onion-Grid-News alias
    sudo -u amnesia /usr/bin/tahoe add-alias Onion-Grid-News $grid_news_read_cap || true
    echo
    echo "This is the write capability for your 'tahoe:' (default) directory:"
    sudo -u amnesia /usr/bin/tahoe list-aliases | grep tahoe
    echo "(you might want to save that somewhere else)"
    echo
    echo "To access your tahoe directory in a browser, run this command:"
    echo "      tahoe webopen tahoe:"
    echo
    echo "To read the latest Onion Grid News, run this:"
    echo "      tahoe webopen Onion-Grid-News:Latest/index.html"

fi

/usr/bin/sudo -u amnesia /usr/bin/notify-send "Tahoe LAFS Installed" "Web interface on 127.0.0.1:3456 with Applications > Internet > Tor Browser"

fi

