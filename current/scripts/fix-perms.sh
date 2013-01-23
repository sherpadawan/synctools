#!/bin/bash
#This script is used to fix the system permissions. execute it every after svn:up
#You must keep this script up to date (new component=new system user=new lines in this script)

path=$(readlink -f $0)
source $(dirname $path)/include/config.sh

echo Fix some rights on project subtree
chmod -R u+rwx $SCRIPTS_DIR

echo Chown folders to the project user 

chown -R $PROJECTUSER.$PROJECTUSER $PROJECTROOTDIR

chmod -R a-rwx $PROJECTROOTDIR"/src/"

chmod -R u+rwX $PROJECTROOTDIR"/src/"
chmod -R a+rX $PROJECTROOTDIR"/src/"

ApacheWritablesDirs=""
for site in ${SITES[@]}
do
    ApacheWritableDirs="$ApacheWritableDirs $PROJECTROOTDIR/src/sites/$site/files"
done

echo Fix Apache writable directories

for i in $ApacheWritableDirs
do
  chgrp -R $APACHEGROUP $i
  chmod -R g+rwX $i
done

echo Fix OK
