#!/bin/bash

echo ">>>>>> $0 pidfile port_num kill_type start_time run_interval run_count"

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

if [ -z "$4" ];
then
  start_time=30
else
  start_time=$4
fi

if [ -z "$5" ];
then
  run_interval=30
else
  run_interval=$5
fi

if [ -z "$6" ];
then
  run_count=1000000
else
  run_count=$6
fi

echo ">>>>>> $0 $pidfile $port_num $kill_type $start_time $run_interval $run_count"

can_test_failure="__can_test_failure__"

echo ">>>>>> sleep for $start_time before starting"
sleep $start_time

COUNTER=1
while [ $COUNTER -le $run_count ];
do 
  echo ">>>>>> $0 running ($COUNTER/$run_count)"
  if  [ -f "$can_test_failure" ];
  then
    echo ">>>>>> kill and run $pidfile"
    ./killandrun.memcached.bash $pidfile $port_num $kill_type
  else
    echo ">>>>>> cannot kill and run slave"
  fi
  echo ">>>>>> sleep for $run_interval"
  sleep $run_interval
  echo ">>>>>> wakeup"

  let COUNTER=COUNTER+1
done

#sleep 40
#./start_memcached.bash
