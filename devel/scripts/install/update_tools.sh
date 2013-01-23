#!/bin/bash

canonical_filename=`readlink -f $0`
source $(dirname $canonical_filename)/../include/config.sh

read -p "[WARNING] This scripts will overwrite scripts/ and build/lib/ directories, continue (N/y) " _ans
if [ "$_ans" != "y" ];then
    echo "[INFO] Interrupted!"
    exit 1
fi

cd $PROJECT_ROOT
_SVN_BASE_URL=https://sources.gnb.intranet/svn/utils/trunk/devel/
svn export --force $_SVN_BASE_URL/scripts/ scripts/
svn export --force $_SVN_BASE_URL/build/lib/ build/lib/
