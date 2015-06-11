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
MEMC_DIR=$DIR/../../arcus-memcached
thread_count=32

if [ -f "$pidfile.pid" ];
then
  echo ">>>>>> kill -$kill_type `cat $pidfile.pid`"
  kill -$kill_type `cat $pidfile.pid`
  echo ">>>>>> wait a second to terminate $pidfile"
  sleep 5
fi

echo ">>>>>> start memcached as $pidfile..."
sleep 1
$MEMC_DIR/memcached -E $MEMC_DIR/.libs/default_engine.so  -X $MEMC_DIR/.libs/syslog_logger.so -X $MEMC_DIR/.libs/ascii_scrub.so -d -v -r -R5 -U 0 -D: -b 8192 -m2000 -p $port_num -c 1000 -t $thread_count -z 127.0.0.1:2181 -e "replication_config_file=replication.config;" -P "$pidfile.pid" -o 3 -g 100
