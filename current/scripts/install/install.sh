#!/bin/bash
#This is an executable documentation.
#This documentation must be kept up to date and the default file generated with spbuilder is just a sample
#set -eux

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

script_path=$(readlink -f $0)
source $(dirname $script_path)/../include/config.sh

# Core system components
aptitude update
echo 'Installing core components'
aptitude -y install mysql-server mysql-client
echo 'Installing PHP extensions'
aptitude -y install php5-mysql php5-xdebug php5-mcrypt php5-curl \
php5-gd php5-common php5-cli php-pear php-apc libapache2-mod-php5 php5-intl php5-sqlite
a2enmod rewrite expires headers
if [ "$MEMCACHED_USE" == "1" ];then
  bash $SCRIPT_DIR/install/memcached_install.sh
fi

if [ "$VARNISH_USE" == "1" ];then
  bash $SCRIPT_DIR/install/varnish_install.sh
fi

# PHP dependencies :
pear upgrade pear
pear channel-discover pear.drush.org
pear install drush/drush

#spbuilder installation
pear channel-discover pear.phing.info
pear channel-discover pear-channel.vitry.intranet
pear install phing/phing-2.4.12
pear install smile/SPBuilder

$SCRIPTS_DIR/fix-perms.sh
$SCRIPTS_DIR/make-symlink.sh
$SCRIPTS_SIR/restart-daemons.sh


bash $SCRIPTS_DIR/fix-perms.sh
$SCRIPTS_DIR/make-symlink.sh
$SCRIPTS_DIR/restart-daemons.sh

#add checkout of drupal from svn ?

#default settings for the install wizard 
cp $PROJECT_SRC/sites/default/default.settings.php $PROJECT_SRC/sites/default/settings.php

#Temporary permission for the install wizard 
chgrp -R $APACHEGROUP $PROJECTROOTDIR/src/sites/default/
chmod -R g+rw  $PROJECTROOTDIR/src/sites/default/

echo 'System configuration is up to date, check : '
echo 'http://biu-sorbonne.lxc/install.php for install wizard'
