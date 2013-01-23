#!/bin/bash
canonical_filename=`readlink -f $0`
source $(dirname $canonical_filename)/include/config.sh

backup_file=$1
if [ -z "$backup_file"  ];then
    echo "[ERROR] Not backup file name provided"
    exit 1
    #TODO check ${bakup_file/.gz/} != $backup_file
fi

db=$2
offset=$(_check_array_index $db ${SITES_DBS[@]})
if [ $offset -eq -1  ];then
    echo "[ERROR] Bad db name $db"
    exit 1
fi
 
if [ -z "$db" ];then
    echo "[ERROR] empty $db name"
    exit 1
fi

if [ ! -d "$BACKUP_DIR/mysql"  ];then
    mkdir -p $BACKUP_DIR/mysql
    if [ $? -ne 0 ];then
       echo "[ERROR] Unable to create backup dir"
       exit 1
    fi
fi

backup_file=$BACKUP_DIR/mysql/$backup_file
echo "[INFO] Backup local db in ${backup_file}.gz"
mysqldump -u${LOCAL_MYSQL_USER} -p${LOCAL_MYSQL_PASS} $db > $backup_file
sed -i -E -e "/^INSERT INTO \`(cache|watchdog|sessions)/d"  $backup_file
gzip $backup_file


exit 0
