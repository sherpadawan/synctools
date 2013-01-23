#!/bin/bash
canonical_filename=`readlink -f $0`
source $(dirname $canonical_filename)/include/config.sh

db=$1
offset=$(_check_array_index $db ${SITES_DBS[@]})
if [ $offset -eq -1  ];then
    echo "[ERROR] Bad db name $db"
    exit 1
fi
 
if [ -z "$db" ];then
    echo "[ERROR] empty $db name"
    exit 1
fi

backup_file=$2
if [[ ! -f $backup_file ]];then
    echo "[ERROR] File not found $backup_file"
    exit 1
fi

echo '[INFO] Dropping local database '$db'...'
mysql -u${LOCAL_MYSQL_USER} -p${LOCAL_MYSQL_PASS} -e "drop database $db"
echo '[INFO] Creating a new local database '$db'...'
mysql -u${LOCAL_MYSQL_USER} -p${LOCAL_MYSQL_PASS} -e "create database ${db} DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci"

echo "[INFO] Restore local db in $BACKUP_DIR/$backup_file"
zcat $backup_file | mysql -u${LOCAL_MYSQL_USER} -p${LOCAL_MYSQL_PASS} $db

exit 0
