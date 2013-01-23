#!/bin/bash
canonical_filename=`readlink -f $0`
source $(dirname $canonical_filename)/include/config.sh

_db=$1
offset=$(_check_array_index $_db ${SITES_DBS[@]})
if [ $offset -eq -1  ];then
    echo "[ERROR] Bad db name $_db"
    exit 1
fi
_pass=
if [ -n "$LOCAL_MYSQL_ROOT_PASS" ];then
    _pass='-p'$LOCAL_MYSQL_ROOT_PASS
fi
echo "[INFO] Create database"
mysql -uroot $_pass -e "create database ${_db}"

exit 0
