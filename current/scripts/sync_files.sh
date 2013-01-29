#!/bin/bash
canonical_filename=`readlink -f $0`
source $(dirname $canonical_filename)/include/config.sh

site=$1
if [ -z "$1" ];then
    echo "[ERROR] No site specified ..."
    exit 1
fi

cd $PROJECT_SRC
echo 'Syncing sites/'$site'/files ...'
rsync -rv --exclude="css" --exclude="js" --exclude="*.gz" --exclude="*.svn*" ${REMOTE_USER}@${REMOTE_SERVERNAME}:$PROJECT_SRC/sites/$site/files/*  sites/$site/files/

$SCRIPTS_DIR/fix-perms.sh

exit 0
