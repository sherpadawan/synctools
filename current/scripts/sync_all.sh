#!/bin/bash
canonical_filename=`readlink -f $0`
source $(dirname $canonical_filename)/include/config.sh

if [ $(_check_array_index $1 ${SITES[@]}) -gt -1  ];then
  SITES=($1) 
fi

for site in "${SITES[@]}"
do
    $SCRIPTS_DIR/sync_db.sh $site
    if [ $? -ne 0 ];then
       exit 1
    fi
    $SCRIPTS_DIR/sync_files.sh $site
    if [ $? -ne 0 ];then
       exit 1
    fi
    $SCRIPTS_DIR/sync_src.sh $site
    if [ $? -ne 0 ];then
       exit 1
    fi

    drush -l $site cc all
done

