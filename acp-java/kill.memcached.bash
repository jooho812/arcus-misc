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

do_not_kill_async_master=1

mkdir -p pidfiles

if [ "$kill_type" != "NONE" ];
then
  if [ -f "pidfiles/memcached.127.0.0.1:$port_num" ];
  then
    while [ $do_not_kill_async_master -eq 1 ];
    do
      is_master=`echo "stats replication" | nc 127.0.0.1 $port_num | grep "mode master" | wc -l`
      if [ "$is_master" == "0" ];
      then
        break
      fi
      is_async=`echo "stats replication" | nc 127.0.0.1 $port_num | grep "state ASYNC_RUN" | wc -l`
      if [ "$is_async" == "0" ];
      then
        break
      fi
      echo ">>>>>> memcached.127.0.0.1:$port_num is master but in async... Please wait a second.."
      sleep 1
    done
    echo ">>>>>> kill -$kill_type `cat pidfiles/memcached.127.0.0.1:$port_num`"
    kill -$kill_type `cat pidfiles/memcached.127.0.0.1:$port_num`
  fi
fi
