#!/bin/bash

canonical_filename=`readlink -f $0`
source $(dirname $canonical_filename)/../include/config.sh

backup_file /root/.bashrc move
cp $PROJECT_CONF/system/bashrc_${LINUX_DIST} /root/.bashrc
echo "[INFO] run : source ~/.bashrc"
exit 0
