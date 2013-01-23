#!/bin/bash
canonical_filename=`readlink -f $0`
source $(dirname $canonical_filename)/include/config.sh

$SCRIPTS_DIR/make-symlink.sh
$SCRIPTS_DIR/drupal-make-symlinks.sh
$SCRIPTS_DIR/drupal-set-variables.sh
$SCRIPTS_DIR/clear-cache.sh

exit 0
