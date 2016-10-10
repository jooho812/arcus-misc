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

# Find os type. if system`s os is Mac OS X, we use greadlink.
case "$OSTYPE" in
  darwin*) DIR=`greadlink -f $0`;;
  *) DIR=`readlink -f $0`;;
esac

DIR=`dirname $DIR`
MEMC_DIR_NAME=arcus-memcached
MEMC_DIR=$DIR/../../$MEMC_DIR_NAME
thread_count=32
sleep_time=3

touch $MEMC_DIR_NAME.log

mkdir -p pidfiles

echo ">>>>>> start memcached as $pidfile... : `date`"
sleep 1

USE_SYSLOG=1

while :
do
  if [ $USE_SYSLOG -eq 1 ];
  then
    $MEMC_DIR/memcached -E $MEMC_DIR/.libs/default_engine.so -X $MEMC_DIR/.libs/syslog_logger.so -X $MEMC_DIR/.libs/ascii_scrub.so -d -v -r -R5 -U 0 -D: -b 8192 -m1000 -p $port_num -c 1000 -t $thread_count -z 127.0.0.1:2181 -e "replication_config_file=replication.config;" -P pidfiles/memcached.127.0.0.1:$port_num -o 3 -g 100
  else
    $MEMC_DIR/memcached -E $MEMC_DIR/.libs/default_engine.so -X $MEMC_DIR/.libs/ascii_scrub.so -d -v -r -R5 -U 0 -D: -b 8192 -m1000 -p $port_num -c 1000 -t $thread_count -z 127.0.0.1:2181 -e "replication_config_file=replication.config;" -P pidfiles/memcached.127.0.0.1:$port_num -o 3 -g 100 >> $MEMC_DIR_NAME.log 2>&1
  fi

  sleep $sleep_time
  is_run=`echo "stats replication" | nc 127.0.0.1 $port_num | grep "STAT mode" | wc -l`
  if [ "$is_run" == "1" ];
  then
    break
  fi
  echo ">>>>>> memcached.127.0.0.1:$port_num is not ready to run... Please wait a second..."
  #sleep 1
done
