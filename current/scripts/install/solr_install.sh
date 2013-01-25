#!/bin/bash

canonical_filename=`readlink -f $0`
dir=`dirname $canonical_filename`
source $dir/../include/config.sh

if [ -f /etc/redhat-release  ];then
    yum install java-1.6.0-openjdk
    if [ $? -ne 0 ];then
        echo "Stopped on error!"; exit 1;
    fi 
    JAVA_HOME=/usr/lib/jvm/jre
else
    apt-get install openjdk-6-jre
    if [ $? -ne 0 ];then
        echo "Stopped on error!"; exit 1;
    fi 
    JAVA_HOME=/usr/lib/jvm/java-1.6.0-openjdk/
fi



INSTALL_DIR=/usr/local
SOLR_VERSION=3.6.0

function usage() {
    echo "[USAGE] solr_install.sh [--java JAVA_HOME] [--prefix $INSTALL_DIR] [--solr-version X.X.X] [--multicore] [--drupal-module [search_api]]"
}

SOLR_MULTICORE=0
while [ -n "$1" ];do
    case $1 in
        --prefix)INSTALL_DIR=$2;shift;;
        --java)JAVA_HOME=$2;shift;;
        --solr-version)SOLR_VERSION=$2;shift;;
        --multicore)SOLR_MULTICORE=1;;
        --drupal-module)DRUPAL_MODULE=$2;shift;;
        --help)usage;exit 1;;
        *)usage;exit 1;;
    esac
    shift
done

#install dir
if [ ! -d $INSTALL_DIR ];then
    echo "[ERROR] Install directory does not exist"
    usage
    exit 1
fi
#check java 
if [  ! -d $JAVA_HOME ];then
    echo "[ERROR] java home does not exist $JAVA_HOME" 
    usage
    exit 1
fi

#drupal module default is search api
if [ -z "$DRUPAL_MODULE" ];then
  DRUPAL_MODULE=search_api
fi

SOLR_ROOT=$INSTALL_DIR/solr
SOLR_ARCHIVE=apache-solr-${SOLR_VERSION}.tgz
SOLR_REPO='http://apache.crihan.fr/dist/lucene/solr/'$SOLR_VERSION

SOLR_ARCHIVE_DOWNLOAD=1
if [ -f /tmp/${SOLR_ARCHIVE} ];then
   read -p "[WARNING] Archive already exists on filesystem, redownload it (yes/no)?" ans
   if [ "$ans" == "yes" ];then
      rm -f /tmp/${SOLR_ARCHIVE}
      SOLR_ARCHIVE_DOWNLOAD=1
   else 
      SOLR_ARCHIVE_DOWNLOAD=0
   fi
fi

if [ $SOLR_ARCHIVE_DOWNLOAD -eq 1  ];then
    wget $SOLR_REPO/$SOLR_ARCHIVE -O /tmp/$SOLR_ARCHIVE
fi

#check solr archive
if [ ! -f "/tmp/$SOLR_ARCHIVE" ];then
    echo "[ERROR] Solr archive not found"
    usage
    exit 1
fi

echo "[INFO] Create user and group ... "
adduser --home $SOLR_ROOT --system solr
groupadd solr
usermod -G solr solr

echo "[INFO] Extracting solr archive $SOLR_ARCHIVE to $INSTALL_DIR"
if [ -d $INSTALL_DIR/${SOLR_ARCHIVE/.tgz/} ];then
   echo  "[WARNING] $INSTALL_DIR/${SOLR_ARCHIVE/.tgz/} already exists"
   backup_file "$INSTALL_DIR/${SOLR_ARCHIVE/.tgz/}" move
fi
tar xpPzf /tmp/$SOLR_ARCHIVE -C $INSTALL_DIR 
#rm /tmp/$SOLR_ARCHIVE

echo "[INFO] Installing solr-php-client library"
wget http://solr-php-client.googlecode.com/files/SolrPhpClient.r60.2011-05-04.tgz
backup_file $PROJECT_SRC/sites/all/libraries/SolrPhpClient move
tar zxf SolrPhpClient.r60.2011-05-04.tgz -C $PROJECT_SRC/sites/all/libraries/

echo "[INFO] Drupal module install/update ?"
cd $PROJECT_SRC

if [[ "$DRUPAL_MODULE" == 'search_api' ]];then
    drush dl search_api --select 
    drush dl search_api_solr --select
    drush dl search_api_facetapi --select
    drush dl search_api_page --select
    drush dl search_api_views --select
fi

if [[ "$DRUPAL_MODULE" == 'apachesolr' ]];then
    drush dl apachesolr --select
    drush dl apachesolr_search --select
    drush dl apachesolr_access --select
fi


for site in ${SITES[*]}
do
  if [ "$DRUPAL_MODULE" == 'search_api' ];then
    echo "[WARNING] Disabling conflicting module apachesolr"
    drush -l $site dis apachesolr 
    drush -l $site dis apachesolr_search 
    drush -l $site dis apachesolr_access 

    drush -l $site en search_api
    drush -l $site en search_api_solr
    drush -l $site en search_api_facetapi
    drush -l $site en search_api_page
    drush -l $site en search_api_views
  else
    echo "[WARNING] Disabling conflicting module search_api"
    drush -l $site dis search_api -y
    drush -l $site apachesolr --select
    drush -l $site apachesolr_search --select
    drush -l $site apachesolr_access --select
  fi
done


echo "[INFO] Prepare Solr Configuration ..."
backup_file $SOLR_ROOT move
if [ ! -d $SOLR_ROOT ];then
    mkdir -p $SOLR_ROOT
fi

cd $INSTALL_DIR
if [ -d solr${SOLR_VERSION}  ];then
   backup_file solr${SOLR_VERSION} move
fi
mv ${SOLR_ARCHIVE/.tgz/} solr${SOLR_VERSION}
cd solr${SOLR_VERSION}  

echo "[INFO] Copying solr example configuration"
cp -r example/* $SOLR_ROOT/

echo "[INFO] Copy Drupal 7 apachesolr configuration to $SOLR_ROOT/solr/conf"
if [ "$DRUPAL_MODULE" == 'search_api' ];then
  cp -f $PROJECT_SRC/sites/all/modules/search_api_solr/solr-conf/solr-3.x/* $SOLR_ROOT/solr/conf/
  cp -f $PROJECT_SRC/sites/all/modules/contrib/search_api_solr/solr-conf/solr-3.x/* $SOLR_ROOT/solr/conf/
else
  cp -f $PROJECT_SRC/sites/all/modules/apachesolr/solr-conf/solr-3.x/* $SOLR_ROOT/solr/conf/
  cp -f $PROJECT_SRC/sites/all/modules/contrib/apachesolr/solr-conf/solr-3.x/* $SOLR_ROOT/solr/conf/
fi

echo "[INFO] Install system scripts ..."
cd $PROJECT_CONF/solr/
for f in `find . -type f | grep -v "svn"`  
do
   src_dir=`dirname $f`
   tgt_dir=${src_dir/\./}
   echo "[INFO] Copy $f to $tgt_dir"
   if [ ! -d $tgt_dir ];then
     mkdir -p $tgt_dir
   fi
   cp -f $f $tgt_dir/
   chmod a+rx ${f/\./}
done

sed -i -e 's|JAVA_HOME=.*|JAVA_HOME='$JAVA_HOME'|' $SOLR_ROOT/bin/solr.sh
sed -i -e 's|SOLR_ROOT=.*|SOLR_ROOT='$SOLR_ROOT'|' $SOLR_ROOT/bin/solr.sh
sed -i -e 's|<mergePolicy>org.apache.lucene.index.LogByteSizeMergePolicy</mergePolicy>|<mergePolicy class="org.apache.lucene.index.LogByteSizeMergePolicy" />|' $SOLR_ROOT/solr/conf/solrconfig.xml

if [ $SOLR_MULTICORE -eq 1 ];then
  echo "[INFO] Configuring multicore, press ENTER to continue (exit on empty entry)"
  cd $SOLR_ROOT
  i=0
  read -p "Enter Site name #${i} (e.g. site_examplecom) " core
  while [ -n "$core" ]
  do
     mkdir solr/$core
     cp -r solr/conf solr/$core/
     chown -R root:solr solr/$core
     chmod -R 775 solr/$core
     ((i++))
     read -p "Enter Site name #${i} (e.g. site_examplecom) " core
  done
  rm solr/conf -fr 
  rm solr/solr.xml
  cp multicore/solr.xml solr/
  vim solr/solr.xml
else
  mkdir $SOLR_ROOT/solr/data
  chgrp -R solr $SOLR_ROOT/solr/data
  chmod -R 775 $SOLR_ROOT/solr/data
fi

chown -R root:solr $SOLR_ROOT/logs/
chmod -R 775 $SOLR_ROOT/logs/

if [ -f /etc/redhat-release ];then
   mv /etc/init.d/solr.redhat /etc/init.d/solr
   chkconfig --add solr
else
   mv /etc/init.d/solr.debian /etc/init.d/solr
   update-rc.d solr defaults
fi

/etc/init.d/solr restart


