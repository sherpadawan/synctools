#!/bin/sh

SOLR_ROOT=/usr/local/solr
LOG_FILE=$SOLR_ROOT/logs/solr-output.log
JAVA_HOME=/usr/local/jre

cd $SOLR_ROOT
exec $JAVA_HOME/bin/java -Dsolr.solr.home=$SOLR_ROOT/solr -jar start.jar >> $LOG_FILE 2>&1

