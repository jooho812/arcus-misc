#!/bin/bash

if [ -z "$1" ];
then
  port_num=11401
else
  port_num="$1"
fi

# Find os type. if system`s os is Mac OS X, we use greadlink.
case "$OSTYPE" in
  darwin*) DIR=`greadlink -f $0`;;
  *) DIR=`readlink -f $0`;;
esac

DIR=`dirname $DIR`
MEMC_DIR_NAME=arcus-memcached
MEMC_DIR=$DIR/../../../$MEMC_DIR_NAME
thread_count=16
sleep_time=3
touch $MEMC_DIR_NAME.log

USE_SYSLOG=1

if [ $USE_SYSLOG -eq 1 ];
then
  $MEMC_DIR/memcached -E $MEMC_DIR/.libs/squall_engine.so -e config_file=$DIR/conf/squall_engine.conf -X $MEMC_DIR/.libs/syslog_logger.so -X $MEMC_DIR/.libs/ascii_scrub.so -d -v -r -R5 -U 0 -D: -b 8192 -m2048 -p $port_num -c 1000 -t $thread_count -o 60
  echo "$MEMC_DIR/memcached -E $MEMC_DIR/.libs/squall_engine.so -e config_file=$DIR/conf/squall_engine.conf -X $MEMC_DIR/.libs/syslog_logger.so -X $MEMC_DIR/.libs/ascii_scrub.so -d -v -r -R5 -U 0 -D: -b 8192 -m2048 -p $port_num -c 1000 -t $thread_count -o 60"
else
  $MEMC_DIR/memcached -E $MEMC_DIR/.libs/squall_engine.so -X $MEMC_DIR/.libs/ascii_scrub.so -d -v -r -R5 -U 0 -D: -b 8192 -m2048 -p $port_num -c 1000 -t $thread_count -z 127.0.0.1:9181 -e "replication_config_file=replication.config;" -P pidfiles/memcached.127.0.0.1:$port_num -o 3 -g 100 >> $MEMC_DIR_NAME.log 2>&1
fi
