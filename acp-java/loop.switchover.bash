#!/bin/bash

echo ">>>>>> $0 master_port slave_port start_time run_interval run_count"

if [ -z "$1" ];
then
  master_port=11211
else
  master_port=$1
fi

if [ -z "$2" ];
then
  slave_port=11212
else
  slave_port=$2
fi

if [ -z "$3" ];
then
  start_time=30
else
  start_time=$3
fi

if [ -z "$4" ];
then
  run_interval=30
else
  run_interval=$4
fi

if [ -z "$5" ];
then
  run_count=1000000
else
  run_count=$5
fi

echo ">>>>>> $0 $master_port $slave_port $start_time $run_interval $run_count"

can_test_failure="__can_test_failure__"

echo ">>>>>> sleep for $start_time before switchover"
sleep $start_time

file_time=0

COUNTER=1
while [ $COUNTER -le $run_count ];
do 
  echo ">>>>>> $0 running ($COUNTER/$run_count)"
  if  [ -f "$can_test_failure" ];
  then

    if [ $file_time == 0 ];
    then
      file_time=`stat -c %Y $can_test_failure`
    fi

    if [ `stat -c %Y $can_test_failure` -ne $file_time ];
    then
      echo ">>>>>> cannot switchover (test case changed)"
      exit 1
    fi

    file_time=`stat -c %Y $can_test_failure`

    if  [ `expr $COUNTER % 2` == 1 ];
    then
      echo ">>>>>> execute switchover : $master_port"
      echo "replication switchover" | nc localhost $master_port
    else
      echo ">>>>>> execute switchover : $slave_port"
      echo "replication switchover" | nc localhost $slave_port
    fi
  else
    echo ">>>>>> cannot switchover (test case ended)"
    exit 1
  fi
  echo ">>>>>> sleep for $run_interval"
  sleep $run_interval
  echo ">>>>>> wakeup"

  ./start_memcached.bash

  let COUNTER=COUNTER+1
done
