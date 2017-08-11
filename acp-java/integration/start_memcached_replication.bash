#!/bin/bash

echo ">>>>>> $0 master_port slave_port"

if [ -z "$1" ];
then
  master_port=11291
else
  master_port=$1
fi

if [ -z "$2" ];
then
  slave_port=11292
else
  slave_port=$2
fi

./integration/run.memcached.bash master $master_port
./integration/run.memcached.bash slave $slave_port
