#!/bin/bash
#This script is used to setup your project system configuration. It remove the possibly hardcoded files and create symlinks.
#If you are facing issues with apparmor, you can uninstall it. 
#You must keep this script up to date (new component=new configuration)

path=$(readlink -f $0)
source $(dirname $path)/include/config.sh

## VARNISH CONFIGURATION
if [ "$VARNISH_USE" == "1" ];then
  _PROJECT_VARNISH_VCL=$PROJECTROOTDIR/conf/varnish/default.vcl__${ENV}__
  _PROJECT_VARNISH_CONF=$PROJECTROOTDIR/conf/varnish/varnish__${ENV}__
  if [ "$LINUX_DIST" == "debian" ];then
    _VARNISH_VCL=/etc/varnish/default.vcl
    _VARNISH_CONF=/etc/default/varnish
  else
    _VARNISH_VCL=/etc/varnish/default.vcl
    _VARNISH_CONF=/etc/sysconfig/varnish
  fi
  if [ -f $_PROJECT_VARNISH_VCL ];then
    rm -f $_VARNISH_VCL
    ln -s $_PROJECT_VARNISH_VCL  $_VARNISH_VCL
  else
    echo "[WARNING] Varnish default.vcl for project not found" 
  fi
  if [ -f $_PROJECT_VARNISH_CONF ];then
    rm -f $_VARNISH_CONF
    ln -s $_PROJECT_VARNISH_CONF $_VARNISH_CONF
  else
    echo "[WARNING] Varnish system conf for project not found" 
  fi
else
  echo "[WARNING] Varnish service usage not activated"
fi

## PHP5 CONFIGURATION
#conf php apache
_PROJECT_PHP_INI_FILE_APACHE=$PROJECTROOTDIR/conf/php/apache2/php.ini__${ENV}__ 
#conf php cli
_PROJECT_PHP_INI_FILE_CLI=""
if [ "$LINUX_DIST" == "debian" ];then
    _PROJECT_PHP_INI_FILE_CLI=$PROJECTROOTDIR/conf/php/cli/php.ini__${ENV}__ 
fi

if [ -f $_PROJECT_PHP_INI_FILE_APACHE ];then
    rm -f $PHP_CONF_APACHE/php.ini
    ln -s $_PROJECT_PHP_INI_FILE_APACHE                $PHP_CONF_APACHE/php.ini
else
  echo "[WARNING] No project apache php.ini file found"
fi

if [ -f $_PROJECT_PHP_INI_FILE_CLI ];then
  rm -f $PHP_CONF_CLI/php.ini
  ln -s $_PROJECT_PHP_INI_FILE_CLI                   $PHP_CONF_CLI/php.ini
else
  echo "[WARNING] No project cli php.ini file found"
fi


## APC CONFIGURATION (apache2/conf.d and cli/conf.d are the same on debian)
_PROJECT_APC_INI_FILE=$PROJECTROOTDIR/conf/php/apc.ini__${ENV}__
if [ -f $_PROJECT_APC_INI_FILE ];then
  rm -f $PHP_CONFD_APACHE/apc.ini
  ln -s $_PROJECT_APC_INI_FILE $PHP_CONFD_APACHE/apc.ini
else
  echo "[WARNING] No project apc.ini file found"
fi

##APACHE2 CONFIGURATION
if [ "$LINUX_DIST" == "redhat" ];then
  rm -f $APACHE_CONF/conf.d/$APACHEDEVHOSTFILENAME
  ln -s $PROJECTROOTDIR/conf/apache/${APACHEDEVHOSTFILENAME}__${ENV}__    $APACHE_CONF/conf.d/$APACHEDEVHOSTFILENAME
else
  rm -f $APACHE_CONF/ports.conf
  rm -f $APACHE_CONF/conf.d/charset

  rm -f $APACHE_CONF/sites-available/$APACHEDEVHOSTFILENAME
  ln -s $PROJECTROOTDIR/conf/apache/ports.conf__${ENV}__                  $APACHE_CONF/ports.conf
  ln -s $PROJECTROOTDIR/conf/apache/${APACHEDEVHOSTFILENAME}__${ENV}__    $APACHE_CONF/sites-available/$APACHEDEVHOSTFILENAME
  a2ensite $APACHEDEVHOSTFILENAME
fi
