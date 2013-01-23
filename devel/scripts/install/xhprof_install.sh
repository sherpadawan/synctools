#!/bin/bash

echo "[WARNING] Script not tested yet ... ;)"
exit 1

DIST=debian
PHP_CONF_DIR=/etc/php5/apache2/conf.d
if [ -f /etc/redhat-release  ];then
   DIST=redhat
   PHP_CONF_DIR=/etc/php.d/conf.d
fi


if [ -z `which gcc` ];then
	echo "[INFO] gcc is required -> installing it!"
	if [ "$DIST" == 'debian' ];then
	    yum install gcc
	else 
	    apt-get install gcc
	fi
fi

pecl config-set preferred_state beta
pecl install xhprof

cat > $PHP_CONF_DIR/xhprof.ini << EOF
extension=xhprof.so
xhprof.output_dir="/tmp/xhprof"
EOF

exit 0
