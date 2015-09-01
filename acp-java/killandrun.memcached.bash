#!/bin/bash

if [ -z "$1" ];
then
  pidfile="master"
else
  pidfile="$1"
fi

if [ -z "$2" ];
then
  port_num=11211
else
  port_num=$2
fi

if [ -z "$3" ];
then
  kill_type="INT"
else
  kill_type="$3"
fi

DIR=`readlink -f $0`
DIR=`dirname $DIR`
MEMC_DIR_NAME=arcus-memcached
MEMC_DIR=$DIR/../../$MEMC_DIR_NAME
thread_count=32
sleep_time=5

touch $MEMC_DIR_NAME.log

mkdir -p pidfiles

if [ "$kill_type" != "NONE" ];
then
  if [ -f "pidfiles/memcached.127.0.0.1:$port_num" ];
  then
    echo ">>>>>> kill -$kill_type `cat pidfiles/memcached.127.0.0.1:$port_num`"
    kill -$kill_type `cat pidfiles/memcached.127.0.0.1:$port_num`
    if [ "$kill_type" == "KILL" ];
    then
      sleep_time=40
    fi
    echo ">>>>>> wait a second to terminate $pidfile : `date`"
    echo ">>>>>> sleep for $sleep_time"
    sleep $sleep_time
  fi
fi

echo ">>>>>> start memcached as $pidfile... : `date`"
sleep 1

USE_SYSLOG=1

if [ $USE_SYSLOG -eq 1 ];
then
  $MEMC_DIR/memcached -E $MEMC_DIR/.libs/default_engine.so -X $MEMC_DIR/.libs/syslog_logger.so -X $MEMC_DIR/.libs/ascii_scrub.so -d -v -r -R5 -U 0 -D: -b 8192 -m2000 -p $port_num -c 1000 -t $thread_count -z 127.0.0.1:2181 -e "replication_config_file=replication.config;" -P pidfiles/memcached.127.0.0.1:$port_num -o 3 -g 100
else
  $MEMC_DIR/memcached -E $MEMC_DIR/.libs/default_engine.so -X $MEMC_DIR/.libs/ascii_scrub.so -d -v -r -R5 -U 0 -D: -b 8192 -m2000 -p $port_num -c 1000 -t $thread_count -z 127.0.0.1:2181 -e "replication_config_file=replication.config;" -P pidfiles/memcached.127.0.0.1:$port_num -o 3 -g 100 >> $MEMC_DIR_NAME.log 2>&1
fi
