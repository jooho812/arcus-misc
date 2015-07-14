#!/bin/bash

echo ">>>>>> $0 master_port slave_port node_type kill_type start_time run_interval run_count"

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
  node_type="all"
else
  node_type=$3
fi

if [ -z "$4" ];
then
  kill_type="INT"
else
  kill_type=$4
fi

if [ -z "$5" ];
then
  start_time=30
else
  start_time=$5
fi

if [ -z "$6" ];
then
  run_interval=30
else
  run_interval=$6
fi

if [ -z "$7" ];
then
  run_count=1000000
else
  run_count=$7
fi

echo ">>>>>> $0 $master_port $slave_port $node_type $kill_type $start_time $run_interval $run_count"

can_test_failure="__can_test_failure__"

echo ">>>>>> sleep for $start_time before starting"
sleep $start_time

action_node="slave"
action_port=$slave_port

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

    if  [ "$node_type" == "all" ];
    then
      if  [ `expr \( $COUNTER - 1 \) % 4` == 0 ];
      then
        action_node="master"
        action_port=$master_port
      elif  [ `expr \( $COUNTER - 1 \) % 4` == 1 ];
      then
        action_node="master"
        action_port=$master_port
      elif  [ `expr \( $COUNTER - 1 \) % 4` == 2 ];
      then
        action_node="slave"
        action_port=$slave_port
      else
        action_node="slave"
        action_port=$slave_port
      fi
    elif  [ "$node_type" == "master" ];
    then
      if  [ `expr \( $COUNTER - 1 \) % 2` == 0 ];
      then
        action_node="master"
        action_port=$master_port
      else
        action_node="slave"
        action_port=$slave_port
      fi
    fi

    echo ">>>>>> kill and run node($action_port)"
    echo ">>>>>> ./killandrun.memcached.bash $action_node $action_port $kill_type"
    ./killandrun.memcached.bash $action_node $action_port $kill_type
  else
    echo ">>>>>> cannot kill and run node (test case ended)"
    exit 1
  fi
  echo ">>>>>> sleep for $run_interval"
  sleep $run_interval
  echo ">>>>>> wakeup"

#  ./start_memcached.bash

  let COUNTER=COUNTER+1
done
