#!/bin/bash

join_num=0;
leave_num=0;
can_migtest_failure="__can_migtest_failure__";
touch all.migration.log

#g0_m_port=11281
#g0_s_port=11282
g1_m_port=11283
g1_s_port=11284
g2_m_port=11285
g2_s_port=11286
g3_m_port=11287
g3_s_port=11288
g4_m_port=11289
g4_s_port=11290

echo "all migration node run\n"
./integration/start_memcached_migration.bash

sleep 5

while [ 1 ]
do
   if [ ! -f "$can_migtest_failure" ];
   then
     echo ">>>>>>> migration join/leave test stopped (test case ended)";
     echo ">>>>>>> test finished! join count: $join_num, leave count: $leave_num"
     exit 1
   fi

   echo "Migration join count: $join_num"
   echo "g1 M-$g1_m_port, S-$g1_s_port migration join"
   echo cluster join begin | nc localhost $g1_m_port
   sleep 3
   echo "g2 M-$g2_m_port, S-$g2_s_port migration join"
   echo cluster join | nc localhost $g2_m_port
   echo "g3 M-$g3_m_port, S-$g3_s_port migration join"
   echo cluster join | nc localhost $g3_m_port
   echo "g4 M-$g4_m_port, S-$g4_s_port migration join"
   echo cluster join end | nc localhost $g4_m_port
   echo "send all migration join command"
   join_num=`expr $join_num + 1`;

   sleep 30
   if [ ! -f "$can_migtest_failure" ];
   then
     echo ">>>>>>> migration join/leave test stopped (test case ended)";
     echo ">>>>>>> test finished! join count: $join_num, leave count: $leave_num"
     exit 1
   fi

   echo "Migration leave count: $leave_num"
   echo "g1 M-$g1_m_port, S-$g1_s_port migration leave"
   echo cluster leave begin | nc localhost $g1_m_port
   sleep 3
   echo "g2 M-$g2_m_port, S-$g2_s_port migration leave"
   echo cluster leave | nc localhost $g2_m_port
   echo "g3 M-$g3_m_port, S-$g3_s_port migration leave"
   echo cluster leave | nc localhost $g3_m_port
   echo "g4 M-$g4_m_port, S-$g4_s_port migration leave"
   echo cluster leave end | nc localhost $g4_m_port
   echo "send all migration leave command"
   leave_num=`expr $leave_num + 1`;

   sleep 30
done
