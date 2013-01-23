#!/bin/bash
canonical_filename=`readlink -f $0`
source $(dirname $canonical_filename)/include/config.sh

cd $PROJECT_SRC
count=`svn status | grep -v ^? | grep -v "settings.php$" | grep -v "sites.php$" | wc -l`
if [ $count -gt 0 ];then
echo `svn status | grep -v ^? | grep -v "settings.php$" | grep -v "sites.php$"` | mail -s "$HOSTNAME ENV=$ENV svn status" $PROJECT_MAILINGLIST
fi

exit 0
