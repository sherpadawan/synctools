#!/bin/bash

#if [ ${__FUNCTIONS_SH__} -eq 1 ];then
#   return
#fi
#export __FUNCTIONS_SH__=1

function restart_service() {
   local service_name=$1
   if [ "$service_name" == "apache" ];then
      if [ "$LINUX_DIST" == 'redhat' ];then
          service httpd stop
          service httpd start
      else 
          service apache2 stop
          service apache2 start
      fi
   elif [ "$service_name" == 'varnish'  ];then
        service varnish stop
        service varnish start 
   elif [ "$service_name" == "memcached" ];then
        service memcached stop 
        service memcached start
   elif [ "$service_name" == "solr" ];then
        /etc/init.d/solr stop
        /etc/init.d/solr start
   fi
}


function backup_file() {
    if [ "$OP_TIMESTAMP" != ""  ];then
       ts=$OP_TIMESTAMP
    else
       ts=$(date "+%Y%m%d-%H%M%S")
    fi
    if [ -f $1 ];then
        \cp -f $1 $1.${ts}
        echo "[INFO] Backing up file $1 to ${1}.$ts" 
    else
        echo "[WARNING] No file to back up file $1" 
    fi
}

function require_user() {
    user=$1
    if [ $(id -u $user) -eq $(id -u) ];then
        echo 1
    else 
        echo 0
    fi
}

#this function check mysql connection
function check_mysql_connection() {
    local user=$1
    local pass=$2
    local db=$3
    local host=$4
    if [ -n "$pass" ];then
        pass='-p'$pass
    fi
    if [ -n "$host" ];then
        host='-h'$host
    fi 
    mysql -A -u${user} $pass $host $db -e "" &> /dev/null
    if [ $? -ne 0 ];then
        echo 0
    fi
    echo 1 
}


function filesize() {
    echo `stat -c"%s" $1`
}

function get_linux_distrib_name() {
    if [ -f /etc/redhat-release ];then
        echo 'redhat'
    elif [ -f /etc/debian_version ];then	
	echo 'debian'
    else
       echo ''
    fi
}

function get_linux_distrib_version() {
    if [ -f /etc/redhat-release ];then
       echo $(cat /etc/redhat-release | perl -ne '/(\d\.\d)/ and print $1')
    elif [ -f /etc/debian_version ];then
       echo $(cat /etc/debian_version | perl -ne '/\w+\/(\w+)/ and print $1')
    else
       echo ''
    fi
}

function _check_array_index() {
    local found
    local i
    local offset=$1 
    shift
    local array=( $@ )
    found=-1
    i=0

    for index in "${array[@]}"
    do
        if [[ "$index" == "$offset" ]]; then
            found=$i
        fi
        ((i++)) 
    done
    echo $found
}

