#!/bin/bash

casename='case #11'
prefix_msg='DEBUGDEBUG'

echo ">>>>>> $prefix_msg client test $casename : preparing..."

pkill -INT memcached
sleep 2

rm zk_noti
rm op_ignore
touch ch_exception
touch delay_switchover

./run.memcached.bash master 11215
sleep 1
./run.memcached.bash master 11216
sleep 5

echo ">>>>>> $prefix_msg client test $casename : begin..."

touch zk_noti
./kill.memcached.bash master 11215 KILL
sleep 1
./run.memcached.bash master 11217
sleep 2

touch op_ignore
rm zk_noti
sleep 1

echo "replication switchover" | nc localhost 11216
rm op_ignore

sleep 2

rm delay_switchover
rm ch_exception

echo ">>>>>> $prefix_msg client test $casename : end..."
