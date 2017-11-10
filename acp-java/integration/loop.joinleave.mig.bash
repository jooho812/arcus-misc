#!/bin/bash

join_num=0;
leave_num=0;
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

####################################
############ function ##############
####################################

function g0_stats() {
   echo stats | nc localhost $g0_m_port | grep curr_items
}

function g1_stats() {
   echo stats | nc localhost $g1_m_port | grep curr_items
}

function g2_stats() {
   echo stats | nc localhost $g2_m_port | grep curr_items
}

function g3_stats() {
   echo stats | nc localhost $g3_m_port | grep curr_items
}

function g4_stats() {
    echo stats | nc localhost $g4_m_port | grep curr_items
}

g0_count=0
g1_count=0
g2_count=0
g3_count=0
g4_count=0

function print_item_count() {
  echo ">>> $g0_m_port items"
  g0_str=$(g0_stats)
  g0_sub=${g0_str:16}
  g0_count=`echo $g0_sub | sed 's/[^0-9]//g'`
  echo $g0_str

  echo ">>> $g1_m_port items"
  g1_str=$(g1_stats)
  g1_sub=${g1_str:16}
  g1_count=`echo $g1_sub | sed 's/[^0-9]//g'`
  echo $g1_str

  echo ">>> $g2_m_port items"
  g2_str=$(g2_stats)
  g2_sub=${g2_str:16}
  g2_count=`echo $g2_sub | sed 's/[^0-9]//g'`
  echo $g2_str

  echo ">>> $g3_m_port items"
  g3_str=$(g3_stats)
  g3_sub=${g3_str:16}
  g3_count=`echo $g3_sub | sed 's/[^0-9]//g'`
  echo $g3_str

  echo ">>> $g4_m_port items"
  g4_str=$(g4_stats)
  g4_sub=${g4_str:16}
  g4_count=`echo $g4_sub | sed 's/[^0-9]//g'`
  echo $g4_str
}

####################################
############ run test ##############
####################################

#echo "all migration node run\n"
#./integration/start_memcached_migration.bash
#sleep 5

response=0
while [ 1 ]
do
   if [ ! -f "$can_migtest_failure" ];
   then
     echo -e "\e[32m>>>>>>> migration join/leave test stopped (test case ended)\e[0m"
     echo -e "\e[32m>>>>>>> test finished! join count: $join_num, leave count: $leave_num\e[0m"
     exit 0
   fi

# join
   echo "g3 M-$g3_m_port, S-$g3_s_port migration join"
   response='';
   while [ "${response:0:2}" != "OK" ]
   do
       response=`echo cluster join begin| nc localhost $g3_m_port`
       sleep 10
   done

   echo "g4 M-$g4_m_port, S-$g4_s_port migration join"
   response='';
   while [ "${response:0:2}" != "OK" ]
   do
       response=`echo cluster join end | nc localhost $g4_m_port`
       sleep 0.1
   done
   echo "send all migration join command"
   join_num=`expr $join_num + 1`;

   sleep 200
   if [ ! -f "$can_migtest_failure" ];
   then
     echo -e "\e[32m>>>>>>> migration join/leave test stopped (test case ended)\e[0m"
     echo -e "\e[32m>>>>>>> test finished! join count: $join_num, leave count: $leave_num\e[0m"
     exit 0
   fi

# leave
   echo "g3 M-$g3_m_port, S-$g3_s_port migration leave"
   response='';
   while [ "${response:0:2}" != "OK" ]
   do
       response=`echo cluster leave begin| nc localhost $g3_m_port`
       sleep 0.1
   done

   echo "g4 M-$g4_m_port, S-$g4_s_port migration leave"
   response='';
   while [ "${response:0:2}" != "OK" ]
   do
       response=`echo cluster leave end | nc localhost $g4_m_port`
       sleep 0.1
   done
   echo "send all migration leave command"
   leave_num=`expr $leave_num + 1`;

   sleep 200
done

print_item_count
