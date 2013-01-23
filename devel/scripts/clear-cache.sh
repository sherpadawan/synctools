#!/bin/bash
#Keep this script up to date for every new component added to the system that has some caching capabilities enabled.

path=$(readlink -f $0)
source $(dirname $path)/include/config.sh

#varnish flush
if [ "$VARNISH_USE" == "1" ];then
  service varnish stop
  service varnish start
fi

#apc flush
if [ "$LINUX_DIST" == "redhat" ];then
  service httpd stop
  service httpd start
else
  service apache2 stop
  service apache2 start  
fi

#memcached flush
if [ "$MEMCACHED_USE" == "1" ];then
  service memcached stop
  service memcached start
fi
sleep 1

for site in ${SITES[@]};do
  cd $PROJECTROOTDIR/src && drush -l $site cc all --root="$PROJECTROOTDIR/src"
done
