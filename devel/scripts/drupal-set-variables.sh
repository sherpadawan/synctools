#!/bin/bash
canonical_filename=`readlink -f $0`
source $(dirname $canonical_filename)/include/config.sh

drupal_ini_all=$PROJECT_CONF/drupal/variables.ini__ALL__
drupal_ini=$PROJECT_CONF/drupal/variables.ini__${ENV}__

if [[ ! -r $drupal_ini || ! -r $drupal_ini_all ]];then
    echo "[ERROR] Missing configuration files $drupal_ini_all or $drupal_ini"
    exit 1
fi

cd $PROJECT_SRC
for site in ${SITES[@]};do
    echo ""
    echo "[INFO] Processing settings for site $site"
    echo ""
    drush -l $site php-script $PROJECT_ROOT/scripts/drupal-settings.php $site $drupal_ini $drupal_ini_all
done
