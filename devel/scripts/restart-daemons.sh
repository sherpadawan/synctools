#!/bin/bash
#This script is used to restart the daemons so that the configurations updates will be applied
#execute it every after svn:up
#You must keep this script up to date (new component=new lines in this script)

path=$(readlink -f $0)
source $(dirname $path)/include/config.sh

if [ "$LINUX_DIST" == "redhat" ];then
  service mysqld stop
  service mysqld start
else
  service mysql stop
  service mysql start
fi


if [ "$MEMCACHED_USE" == "1" ];then
   service memcached stop
   service memcached start
fi

if [ "$LINUX_DIST" == "redhat"  ];then
  service httpd stop
  service httpd start
else
  service apache2 stop
  service apache2 start
fi

if [ "$VARNISH_USE" == "1" ];then
   service varnish stop
   service varnish start
fi

if [ "$SOLR_USE" == "1" ];then
  /etc/init.d/solr stop
  /etc/init.d/solr start
fi
