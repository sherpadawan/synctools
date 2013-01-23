#!/bin/bash

canonical_filename=`readlink -f $0`
dir=`dirname $canonical_filename`
source $dir/../include/config.sh

if [ $(require_user root) -eq 0 ];then
    echo "[ERROR] Must be executed as root"
    exit 1
fi

apc_conf=$PROJECT_CONF/php/apc.ini__${ENV}__
if [[ ! -f $apc_conf ]];then
    echo "[ERROR] File not found $apc_conf " 
    exit 1
fi

create_conf=0
if [ "$LINUX_DIST" == 'debian' ];then
    apt-get install php-apc
else
    yum install php-pecl-apc
    if [ $? -gt 0 ];then
        pecl install apc
        create_conf=1
    fi
fi

if [ $create_conf -eq 0 ];then
    extension_dir=$(php -i |grep extension_dir | perl -ne '/=>\s+(.*)\s+=>/ and print $1')
    backup_file $PHP_CONFD_APACHE/apc.ini
    \cp -f $apc_conf $PHP_CONFD_APACHE/apc.ini 

    echo "extension=$extension_dir/apc.so " >> $PHP_CONFD_APACHE/apc.ini 
    echo "[INFO] Using config $PHP_CONFD_APACHE/apc.ini"
    echo "###############################"
    cat $PHP_CONFD_APACHE/apc.ini
    echo "###############################"
else
    echo "[INFO] You may want to use this settings ..."
    cat $PHP_CONFD_APACHE/apc.ini
fi

restart_service apache 

exit 0
