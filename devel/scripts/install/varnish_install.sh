#!/bin/bash

canonical_filename=`readlink -f $0`
dir=`dirname $canonical_filename`
source $dir/../include/config.sh

if [ $(require_user root) -eq 0 ];then
    echo "[ERROR] Must be executed as root"
    exit 1
fi

varnish_conf=$PROJECT_CONF/varnish/default.vcl__${ENV}__
if [[ ! -f $varnish_conf ]];then
    echo "[ERROR] File not found $varnish_conf " 
    exit 1
fi

if [ "$LINUX_DIST" == 'debian' ];then
    apt-get install varnish
else
    yum install varnish
fi

backup_file /etc/varnish/default.vcl
\cp -f $varnish_conf /etc/varnish/default.vcl 

if [ "$LINUX_DIST" == 'debian' ];then
    varnish_default=/etc/default/varnish
    apache_ports_conf=/etc/apache2/ports.conf
else
    varnish_default=/etc/sysconfig/varnish
    apache_ports_conf=/etc/httpd/conf/httpd.conf
fi

backup_file $varnish_default
backup_file $apache_ports_conf
sed -i -e "s/VARNISH_LISTEN_PORT=6081/VARNISH_LISTEN_PORT=80/" $varnish_default
sed -i -e 's/-a :6081/-a :80/g' $varnish_default
sed -i -e 's/Listen 80/Listen 81/' $apache_ports_conf 
sed -i -e 's/NameVirtualHost \*:80/NameVirtualHost \*:81/' $apache_ports_conf

echo "[INFO] Modify project apache configuration"
backup_file $APACHE_CONFD/${PROJECT_NAME}.conf
env_apache_conf=$(readlink -f $APACHE_CONFD/${PROJECT_NAME}.conf)
sed -i -e 's/NameVirtualHost \*:80/NameVirtualHost \*:81/' $env_apache_conf
sed -i -e 's/VirtualHost \*:80/VirtualHost \*:81/' $env_apache_conf 


restart_service apache
restart_service varnish 

exit 0
