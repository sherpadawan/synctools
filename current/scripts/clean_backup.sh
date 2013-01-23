#!/bin/bash 
canonical_filename=`readlink -f $0`
source $(dirname $canonical_filename)/include/config.sh

if [[ -z "$1" ]];then
    echo "[ERROR] clean_backup.sh OLDER_THAN (x days)"
    exit 1
fi

BACKUP_FILE_REMOVE_DURATION=$1
echo "[INFO] Removing file older than $BACKUP_FILE_REMOVE_DURATION"
find $BACKUP_DIR/mysql -ctime +${BACKUP_FILE_REMOVE_DURATION} -exec rm -f {} \;

echo "[INFO] Cleaning empty mysqldump files..."
find  $BACKUP_DIR/mysql -name "*.gz" -size -${MYSQL_EMPTY_DUMPFILE_SIZE}c -exec rm -f {} \;


exit 0
