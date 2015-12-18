#!/bin/bash

touch all.replication.log

if [ -z "$1" ];
then
  duration=500
else
  duration=$1
fi

if [ -z "$2" ];
then
  COUNTER=1
else
  COUNTER=$2
fi

m_port=11215
s_port=11216

cp_repl_test_log=1

run_all_kill=1
run_slave_kill=1
run_master_kill=1
run_all_stop=1
run_slave_stop=1
run_master_stop=1
run_switchover=1
run_none=1
run_client=0

all_test=1

if [ $all_test -eq 0 ];
then
run_all_kill=0
run_slave_kill=0
run_master_kill=0
run_all_stop=0
run_slave_stop=0
run_master_stop=0
run_switchover=0
run_none=1
run_client=0
fi

rm -f repl_test.*.$COUNTER.log

# client
if [ $run_client -eq 1 ];
then
  echo `date` >> all.replication.log
  echo "perl run_client_repl_test.pl $m_port $s_port client $duration compare" >> all.replication.log
  perl run_client_repl_test.pl $m_port $s_port client $duration compare >& repl_test.log
  grep "Finished" repl_test.log >> all.replication.log
  if [ $cp_repl_test_log -eq 1 ];
  then
    cp repl_test.log repl_test.client.$COUNTER.log
  fi
fi

# all_kill
if [ $run_all_kill -eq 1 ];
then
  echo `date` >> all.replication.log
  echo "perl run_all_repl_test.pl $m_port $s_port all_kill $duration compare" >> all.replication.log
  perl run_all_repl_test.pl $m_port $s_port all_kill $duration compare >& repl_test.log
  grep "Finished" repl_test.log >> all.replication.log
  if [ $cp_repl_test_log -eq 1 ];
  then
    cp repl_test.log repl_test.all_kill.$COUNTER.log
  fi
fi

# slave_kill
if [ $run_slave_kill -eq 1 ];
then
  echo `date` >> all.replication.log
  echo "perl run_all_repl_test.pl $m_port $s_port slave_kill $duration compare" >> all.replication.log
  perl run_all_repl_test.pl $m_port $s_port slave_kill $duration compare >& repl_test.log
  grep "Finished" repl_test.log >> all.replication.log
  if [ $cp_repl_test_log -eq 1 ];
  then
    cp repl_test.log repl_test.slave_kill.$COUNTER.log
  fi
fi

# master_kill
if [ $run_master_kill -eq 1 ];
then
  echo `date` >> all.replication.log
  echo "perl run_all_repl_test.pl $m_port $s_port master_kill $duration compare" >> all.replication.log
  perl run_all_repl_test.pl $m_port $s_port master_kill $duration compare >& repl_test.log
  grep "Finished" repl_test.log >> all.replication.log
  if [ $cp_repl_test_log -eq 1 ];
  then
    cp repl_test.log repl_test.master_kill.$COUNTER.log
  fi
fi

# all_stop
if [ $run_all_stop -eq 1 ];
then
  echo `date` >> all.replication.log
  echo "perl run_all_repl_test.pl $m_port $s_port all_stop $duration compare" >> all.replication.log
  perl run_all_repl_test.pl $m_port $s_port all_stop $duration compare >& repl_test.log
  grep "Finished" repl_test.log >> all.replication.log
  if [ $cp_repl_test_log -eq 1 ];
  then
    cp repl_test.log repl_test.all_stop.$COUNTER.log
  fi
fi

# slave_stop
if [ $run_slave_stop -eq 1 ];
then
  echo `date` >> all.replication.log
  echo "perl run_all_repl_test.pl $m_port $s_port slave_stop $duration compare" >> all.replication.log
  perl run_all_repl_test.pl $m_port $s_port slave_stop $duration compare >& repl_test.log
  grep "Finished" repl_test.log >> all.replication.log
  if [ $cp_repl_test_log -eq 1 ];
  then
    cp repl_test.log repl_test.slave_stop.$COUNTER.log
  fi
fi

# master_stop
if [ $run_master_stop -eq 1 ];
then
  echo `date` >> all.replication.log
  echo "perl run_all_repl_test.pl $m_port $s_port master_stop $duration compare" >> all.replication.log
  perl run_all_repl_test.pl $m_port $s_port master_stop $duration compare >& repl_test.log
  grep "Finished" repl_test.log >> all.replication.log
  if [ $cp_repl_test_log -eq 1 ];
  then
    cp repl_test.log repl_test.master_stop.$COUNTER.log
  fi
fi

# switchover
if [ $run_switchover -eq 1 ];
then
  echo `date` >> all.replication.log
  echo "perl run_all_repl_test.pl $m_port $s_port switchover $duration compare" >> all.replication.log
  perl run_all_repl_test.pl $m_port $s_port switchover $duration compare >& repl_test.log
  grep "Finished" repl_test.log >> all.replication.log
  if [ $cp_repl_test_log -eq 1 ];
  then
    cp repl_test.log repl_test.switchover.$COUNTER.log
  fi
fi

# none
if [ $run_none -eq 1 ];
then
  echo `date` >> all.replication.log
  echo "perl run_all_repl_test.pl $m_port $s_port none $duration compare" >> all.replication.log
  perl run_all_repl_test.pl $m_port $s_port none $duration compare >& repl_test.log
  grep "Finished" repl_test.log >> all.replication.log
  if [ $cp_repl_test_log -eq 1 ];
  then
    cp repl_test.log repl_test.none.$COUNTER.log
  fi
fi

