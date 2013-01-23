#!/bin/bash
canonical_filename=`readlink -f $0`
source $(dirname $canonical_filename)/include/config.sh


for site in ${SITES[@]}
do
if [[ -f $PROJECT_SRC/sites/${site}/settings.php__${ENV}__ && `readlink -f $PROJECT_SRC/sites/${site}/settings.php` != $PROJECT_SRC/sites/${site}/settings.php__${ENV}__ ]];then
    echo "[INFO] Linking Drupal settings.php file for site $site in env $ENV"
    rm -f $PROJECT_SRC/sites/$site/settings.php
    cd $PROJECT_SRC/sites/$site/
    ln -s settings.php__${ENV}__ settings.php
fi
done

if [[ -f $PROJECT_SRC/sites/sites.php__${ENV}__ && `readlink -f $PROJECT_SRC/sites/sites.php` != $PROJECT_SRC/sites/sites.php__${ENV}__ ]];then
    echo "[INFO] Linking Drupal sites.php file for env $ENV"
    rm -f $PROJECT_SRC/sites/sites.php
    cd $PROJECT_SRC/sites/
    ln -s sites.php__${ENV}__ sites.php
fi


