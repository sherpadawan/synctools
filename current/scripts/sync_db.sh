#!/bin/bash

canonical_filename=`readlink -f $0`
source $(dirname $canonical_filename)/include/config.sh

if [ $REMOTE -eq 0  ];then
    echo "[ERROR] REMOTE is disabled, set REMOTE=1 in build/project.properties"
    exit 1
fi

site=$1
offset=$(_check_array_index "$site" ${SITES[@]})
if [ -z "$offset" ];then
    echo "[ERROR] Unknown site $site"
    exit 1
fi
_mysql_db=${SITES_DBS[$offset]}
if [ -z "$_mysql_db" ];then
    echo "[ERROR] Unknown site or db not set for $site"
    exit 1
fi


if [ "`check_mysql_connection $LOCAL_MYSQL_USER $LOCAL_MYSQL_PASS $_mysql_db localhost`" == "0" ];then
    echo "[ERROR] Mysql server not available, try to restart it ..."
    exit 1
fi

# see http://drupal.org/node/670460
today=`date +%Y%m%d%H%M`
remote_dump_file=dump-${REMOTE_SERVERNAME}-${_mysql_db}-${today}.sql.gz

#get remote db
echo '[INFO] Dumping remote server '$REMOTE_SERVERNAME' db ...'
ssh ${REMOTE_USER}@${REMOTE_SERVERNAME} "mysqldump -u${REMOTE_MYSQL_USER} -p${REMOTE_MYSQL_PASS} ${_mysql_db} | gzip > /tmp/${remote_dump_file}"

echo '[INFO] Copying dump file to local FS ...'
scp ${REMOTE_USER}@${REMOTE_SERVERNAME}:/tmp/${remote_dump_file}  /tmp/
s=`filesize /tmp/${remote_dump_file}`
if [ $s -lt $MYSQL_EMPTY_DUMPFILE_SIZE  ];then
    echo "[ERROR] Remote server ${REMOTE_SERVERNAME} may be off, dump file is too small [${s} bytes] ..."
    exit 1 
fi

#backup local db
backup_file=dump-$(hostname)-${_mysql_db}-${today}.sql
$SCRIPTS_DIR/backup_db.sh $backup_file $_mysql_db
if [ $? -ne 0 ];then
   echo "[ERROR] Backup local database failed, stopping process! check config.sh__${ENV}__"
   exit 1
fi

echo "[INFO] To rollback to your old db run restore_db.sh $backup_file"
mysql -u${LOCAL_MYSQL_USER} -p${LOCAL_MYSQL_PASS} -e "drop database ${_mysql_db}"
mysql -u${LOCAL_MYSQL_USER} -p${LOCAL_MYSQL_PASS} -e "create database ${_mysql_db} DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci"

echo '[INFO] Loading dump into local db ... [set max_allowed_packet=1000000000 in /etc/my.cnf]'
zcat /tmp/${remote_dump_file} | mysql --max_allowed_packet=1000000000 -u${LOCAL_MYSQL_USER} -p${LOCAL_MYSQL_PASS} ${_mysql_db} && rm /tmp/${remote_dump_file}
cd $PROJECT_SRC

$SCRIPTS_DIR/fix-env.sh

exit 0
