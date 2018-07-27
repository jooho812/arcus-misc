#!/bin/bash

join_num=0;
leave_num=0;
stime=10;
can_migtest_failure="__can_migtest_failure__";

g0_m_port=11281
g0_s_port=11282
g1_m_port=11283
g1_s_port=11284
g2_m_port=11285
g2_s_port=11286
g3_m_port=11287
g3_s_port=11288
g4_m_port=11289
g4_s_port=11290

if [ $# -le 1 ]; then
    if [ $# -eq 1 ]; then
      SERVER_IP="$1";
    else
      SERVER_IP="127.0.0.1";
    fi
else
    echo "Usage) ./integration/migration_start_auto.bash [SERVER_IP]\n";
    exit 1;
fi

####################################
############ function ##############
####################################

function g0_stats() {
   echo stats | nc $SERVER_IP $g0_m_port | grep curr_items
}

function g1_stats() {
   echo stats | nc $SERVER_IP $g1_m_port | grep curr_items
}

function g2_stats() {
   echo stats | nc $SERVER_IP $g2_m_port | grep curr_items
}

function g3_stats() {
   echo stats | nc $SERVER_IP $g3_m_port | grep curr_items
}

function g4_stats() {
    echo stats | nc $SERVER_IP $g4_m_port | grep curr_items
}

# migration state
function g0_migstats() {
   echo stats migration | nc $SERVER_IP $g0_m_port | grep $1
}

function g1_migstats() {
   echo stats migration | nc $SERVER_IP $g1_m_port | grep $1
}

function g2_migstats() {
   echo stats migration | nc $SERVER_IP $g2_m_port | grep $1
}

function g3_migstats() {
   echo stats migration | nc $SERVER_IP $g3_m_port | grep $1
}

function g4_migstats() {
   echo stats migration | nc $SERVER_IP $g4_m_port | grep $1
}

g0_count=0
g1_count=0
g2_count=0
g3_count=0
g4_count=0

function print_item_count() {
  tot=0
  echo ">>> $g0_m_port items"
  g0_str=$(g0_stats)
  if [ -z "$g0_str" ]; then
    echo "g0 down"
  else
    g0_sub=${g0_str:16}
    g0_count=`echo $g0_sub | sed 's/[^0-9]//g'`
    echo $g0_str
    let tot+=${g0_str//[^0-9]/}
  fi

  echo ">>> $g1_m_port items"
  g1_str=$(g1_stats)
  if [ -z "$g1_str" ]; then
    echo "g1 down"
  else
    g1_sub=${g1_str:16}
    g1_count=`echo $g1_sub | sed 's/[^0-9]//g'`
    echo $g1_str
    let tot+=${g1_str//[^0-9]/}
  fi

  echo ">>> $g2_m_port items"
  g2_str=$(g2_stats)
  if [ -z "$g2_str" ]; then
    echo "g2 down"
  else
    g2_sub=${g2_str:16}
    g2_count=`echo $g2_sub | sed 's/[^0-9]//g'`
    echo $g2_str
    let tot+=${g2_str//[^0-9]/}
  fi

  echo ">>> $g3_m_port items"
  g3_str=$(g3_stats)
  if [ -z "$g3_str" ]; then
    echo "g3 down"
  else
    g3_sub=${g3_str:16}
    g3_count=`echo $g3_sub | sed 's/[^0-9]//g'`
    echo $g3_str
    let tot+=${g3_str//[^0-9]/}
  fi

  echo ">>> $g4_m_port items"
  g4_str=$(g4_stats)
  if [ -z "$g4_str" ]; then
    echo "g4 down"
  else
    g4_sub=${g4_str:16}
    g4_count=`echo $g4_sub | sed 's/[^0-9]//g'`
    echo $g4_str
    let tot+=${g4_str//[^0-9]/}
  fi
  echo -e "\\033[32mtotal item count : $tot\\033[0m"
}

function print_state() {
  if [[ "$2" == "UNKNOWN"* ]]; then
    echo -e "$1 state : \\033[32m$2\\033[0m"
  else
    echo -e "$1 state : \\033[33m$2\\033[0m"
  fi
}

function mig_state() {
  str=$(${1}_migstats sm_info.mg_state)
  state=${str:22}
  echo $state
}

####################################
############ run test ##############
####################################

migration_state="NONE"

while [ 1 ]
do
  if [ ! -f "$can_migtest_failure" ];
  then
    echo -e "\e[32m>>>>>>> migration join/leave test stopped (test case ended)\e[0m"
    echo -e "\e[32m>>>>>>> test finished! join count: $join_num, leave count: $leave_num\e[0m"
    exit 0
  fi

  while true
  do
    g0_state=$(mig_state g0)
    g1_state=$(mig_state g1)
    g2_state=$(mig_state g2)
    g3_state=$(mig_state g3)
    g4_state=$(mig_state g4)
    if [[ !(($g0_state =~ ^UNKNOWN)
         && ($g1_state =~ ^UNKNOWN)
         && ($g2_state =~ ^UNKNOWN)
         && ($g3_state =~ ^UNKNOWN)
         && ($g4_state =~ ^UNKNOWN)) ]]; then
      # migration running
      sleep 1
      continue
    fi

    sleep $stime

    # leave
    response=`echo cluster leave begin| nc $SERVER_IP $g3_m_port`
    if [ "${response:0:2}" == "OK" ]; then
      echo "g3 M-$g3_m_port, S-$g3_s_port migration leave"
      migration_state="LEAVE"
      break
    fi
    sleep 1

    # join
    response=`echo cluster join begin| nc $SERVER_IP $g3_m_port`
    if [ "${response:0:2}" == "OK" ]; then
      echo "g3 M-$g3_m_port, S-$g3_s_port migration join"
      migration_state="JOIN"
      break
    fi
    sleep 1
  done

  if [ "$migration_state" == "LEAVE" ]; then
  ###########################################3
  #  echo "g1 M-$g1_m_port, S-$g1_s_port migration leave"
  #  response='';
  #  while [ "${response:0:2}" != "OK" ]
  #  do
  #  response=`echo cluster leave | nc $SERVER_IP $g1_m_port`
  #  sleep 1
  #  done
  #
  #  echo "g2 M-$g2_m_port, S-$g2_s_port migration leave"
  #  response='';
  #  while [ "${response:0:2}" != "OK" ]
  #  do
  #  response=`echo cluster leave | nc $SERVER_IP $g2_m_port`
  #  sleep 1
  #  done
  ############################################
    echo "g4 M-$g4_m_port, S-$g4_s_port migration leave"
    response='';
    while [ "${response:0:2}" != "OK" ]
    do
    response=`echo cluster leave end | nc $SERVER_IP $g4_m_port`
    sleep 0.1
    done
    echo -e "\e[32msend all migration leave command\e[0m"
    leave_num=`expr $leave_num + 1`;
    
  else # $migration_state == JOIN
  #############################################
  #  echo "g1 M-$g1_m_port, S-$g1_s_port migration join"
  #  response='';
  #  while [ "${response:0:2}" != "OK" ]
  #  do
  #  response=`echo cluster join | nc $SERVER_IP $g1_m_port`
  #  sleep 1
  #  done
  #
  #  echo "g2 M-$g2_m_port, S-$g2_s_port migration join"
  #  response='';
  #  while [ "${response:0:2}" != "OK" ]
  #  do
  #  response=`echo cluster join | nc $SERVER_IP $g2_m_port`
  #  sleep 1
  #  done
  ########################################3
    echo "g4 M-$g4_m_port, S-$g4_s_port migration join"
    response='';
    while [ "${response:0:2}" != "OK" ]
    do
    response=`echo cluster join end | nc $SERVER_IP $g4_m_port`
    sleep 0.1
    done
    echo -e "\e[32msend all migration join command\e[0m"
    join_num=`expr $join_num + 1`;
  fi
done

