#!/bin/bash

echo ">>>>>> $0 case_name start_time run_interval run_count"

if [ -z "$1" ];
then
  case_name=case1
else
  case_name=$1
fi

if [ -z "$2" ];
then
  start_time=30
else
  start_time=$2
fi

if [ -z "$3" ];
then
  run_interval=30
else
  run_interval=$3
fi

if [ -z "$4" ];
then
  run_count=1000000
else
  run_count=$4
fi

echo ">>>>>> $0 $case_name $start_time $run_interval $run_count"

can_test_failure="__can_test_failure__"

echo ">>>>>> sleep for $start_time before starting"
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
      echo ">>>>>> cannot kill and run node (test case changed)"
      exit 1
    fi

    file_time=`stat -c %Y $can_test_failure`

    ./client.$case_name.bash
  else
    echo ">>>>>> cannot execute client test case (test case ended)"
    exit 1
  fi
  echo ">>>>>> sleep for $run_interval"
  sleep $run_interval
  echo ">>>>>> wakeup"

  let COUNTER=COUNTER+1
done
