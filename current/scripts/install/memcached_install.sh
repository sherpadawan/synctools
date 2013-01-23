#!/bin/bash

canonical_filename=`readlink -f $0`
dir=`dirname $canonical_filename`
source $dir/../include/config.sh

CACHESIZE=256
LISTEN_ADDR=127.0.0.1

if [ "$LINUX_DIST" == 'debian' ];then
    apt-get install memcached php5-memcached 
    memcached_conf=/etc/memcached.conf
    backup_file $memcached_conf
    sed -i -e 's/^-m 64/-m '$CACHESIZE'/' $memcached_conf 
else
    yum install memcached php-pecl-memcached
    memcached_conf=/etc/sysconfig/memcached
    backup_file $memcached_conf
    sed -i -e 's/CACHESIZE="64"/CACHESIZE="'$CACHESIZE'"/' $memcached_conf
    sed -i -e 's/OPTIONS=""/OPTIONS="-l '$LISTEN_ADDR'"/' $memcached_conf
fi


cd $PROJECT_SRC
drush dl memcache
drush en -y memcache

for site in "${SITES[@]}";do
    for e in "${ENVS[@]}";do
cat >> $PROJECT_SRC/sites/$site/settings.php__${e}__ <<EOF
#MEMCACHE
\$conf['cache_backends'][] = 'sites/all/modules/memcache/memcache.inc';
\$conf['cache_default_class'] = 'MemCacheDrupal';
\$conf['cache_class_cache_form'] = 'DrupalDatabaseCache';
\$conf['memcache_key_prefix'] = '$PROJECT_NAME';
EOF
    done
drush -l $site vset --always-set show_memcache_statistics 0 
done

restart_service apache
restart_service memcached






