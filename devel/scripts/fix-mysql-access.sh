#!/bin/bash
canonical_filename=`readlink -f $0`
source $(dirname $canonical_filename)/include/config.sh

site=$1
offset=$(_check_array_index $site ${SITES[@]})
if [ -z "$offset" ];then
    echo "[ERROR] Unknown site site"
    exit 1
fi
_mysql_db=${SITES_DBS[$offset]}
if [ -z "$_mysql_db" ];then
    echo "[ERROR] Unknown site or db not set for $site"
    exit 1
fi

echo "[INFO] Fix mysql access for site db $_mysql_db (require root access)"
mysql_pass=
if [ $LOCAL_MYSQL_ROOT_PASS ];then
    mysql_pass="-p$LOCAL_MYSQL_ROOT_PASS"
fi
mysql -uroot ${mysql_pass} -e "grant all privileges on ${_mysql_db}.*  to '${LOCAL_MYSQL_USER}'@'localhost' identified by '${LOCAL_MYSQL_PASS}';flush privileges;";

echo "[INFO] Fix extra db access ... "
for db in "${EXTRA_DBS[@]}"
do
    mysql -uroot ${mysql_pass} -e "grant all privileges on ${db}.*  to '${LOCAL_MYSQL_USER}'@'localhost' identified by '${LOCAL_MYSQL_PASS}';flush privileges;";
done
