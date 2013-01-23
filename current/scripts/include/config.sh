include_dir=$(dirname $(readlink -f ${BASH_ARGV[0]}))

eval $(php -r 'require_once("'$include_dir'/../../build/lib/GNBUtilsConfig.php");echo GNBUtilsConfig::getInstance()->export();')

APACHE_USER=www-data
APACHE_CONFD=/etc/apache2/sites-enabled/
APACHE_CONF=/etc/apache2/
PHP_CONFD_APACHE=/etc/php5/apache2/conf.d/
PHP_CONFD_CLI=/etc/php5/cli/conf.d/
PHP_CONF_APACHE=/etc/php5/apache2/
PHP_CONF_CLI=/etc/php5/cli/
LINUX_DIST=debian
if [ -f /etc/redhat-release ];then
    APACHE_USER=apache
    APACHE_CONF=/etc/httpd/
    APACHE_CONFD=/etc/httpd/conf.d/
    PHP_CONFD_APACHE=/etc/php.d/
    PHP_CONFD_CLI=/etc/php.d/
    PHP_CONF_APACHE=/etc/php5/
    PHP_CONF_CLI=/etc/php5/
    LINUX_DIST=redhat
fi

export APACHE_USER
export APACHE_CONF
export PHP_CONFD_APACHE
export PHP_CONFD_CLI
export LINUX_DIST

export MYSQL_EMPTY_DUMPFILE_SIZE=500


#OP TIMESTAMP
if [ -z "$OP_TIMESTAMP" ];then
    export OP_TIMESTAMP=$(date "+%Y%m%d-%H%M%S")
    echo "[INFO] Timestamp operation is $OP_TIMESTAMP"
fi

#set env (DEV, INTEG, REMOTETEST, PROD)
if [ -z "$ENV" ];then
    read -p "[WARNING] ENV is not set - possible values are ${ENVS[*]} ? " ans
    if [ -z "$ans" ];then
        echo "Cancelled!"
        exit 1
    fi
    if [[ "$ans" == 'DEV' || "$ans" == 'INTEG' || "$ans" == 'REMOTETEST' || "$ans" == 'PROD' || "$ans" == 'TEST' || "$ans" == 'STAGE' ]];then
        ENV=$ans       
    else 
        echo "[ERROR] Unknown ENV value"
        exit 1
    fi
fi
export ENV

#include functions
source $include_dir/functions.sh

#backup directory
if [ ! -d $BACKUP_DIR ];then
    if [ -z "$BACKUP_DIR" ];then
        echo "[WARNING] Creating default backup directory $HOME/backup"
        BACKUP_DIR=$HOME/backup
    fi
    mkdir -p $BACKUP_DIR
fi

if [[ ! -d $PROJECT_ROOT || ! -d $PROJECT_CONF || ! -d $PROJECT_SRC ]];then
   echo "PROJECT_ROOT | PROJECT_CONF | PROJECT_SRC does not exists";
   exit 1
fi

if [[ -z "$SITES"  ]];then
  echo '[ERROR] SITES is not defined'
  exit 1
fi

#check if the smile user exists and add it to apache group
id smile &> /dev/null
if [ $? -eq 1 ];then
    useradd -U -G $APACHE_USER -m -s /bin/bash smile
fi

#compatibility with scriptparameters
export PROJECTROOTDIR=$PROJECT_ROOT
export APACHEUSER=$APACHE_USER
export APACHEGROUP=$APACHE_USER
export APACHEDEVHOSTFILENAME=$PROJECT_NAME.conf
export PROJECTUSER=$PROJECT_USER
export ApacheWritablesDirs=


