#!/bin/bash

join_num=0;
leave_num=0;

touch all.migration.log

g0_m_port=11213
g0_s_port=11214
g1_m_port=11215
g1_s_port=11216
g2_m_port=11217
g2_s_port=11218
g3_m_port=11219
g3_s_port=11220
g4_m_port=11221
g4_s_port=11222

echo "all migration node run"
./start_memcached_migration.bash

echo "g0 M-$g0_m_port, S-$g0_s_port migration join"
echo cluster join alone | nc localhost $g0_m_port

sleep 5

while [ 1 ]
do
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
