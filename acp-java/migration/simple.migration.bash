#!/bin/bash

join_num=0;
leave_num=0;

touch all.migration.log

if [ -z "$1" ];
then
g0_m_port=11213
else
g0_m_port=$1
fi

if [ -z "$2" ];
then
g0_s_port=11214
else
g0_s_port=$2
fi

if [ -z "$3" ];
then
g1_m_port=11215
else
g1_m_port=$3
fi

if [ -z "$4" ];
then
g1_s_port=11216
else
g1_s_port=$4
fi

if [ -z "$5" ];
then
g2_m_port=11217
else
g2_m_port=$5
fi

if [ -z "$6" ];
then
g2_s_port=11218
else
g2_s_port=$6
fi

if [ -z "$7" ];
then
g3_m_port=11219
else
g3_m_port=$7
fi

if [ -z "$8" ];
then
g3_s_port=11220
else
g3_s_port=$8
fi

if [ -z "$9" ];
then
g4_m_port=11221
else
g4_m_port=$9
fi

if [ -z "$10" ];
then
g4_s_port=11222
else
g4_s_port=$10
fi

#a0_s_port=11214
#g1_m_port=11215
#g1_s_port=11216
#g2_m_port=11217
#g2_s_port=11218
#g3_m_port=11219
#g3_s_port=11220
#g4_m_port=11221
#g4_s_port=11222

echo "all migration node run"
./start_memcached_migration.bash

echo "g0 M-$g0_m_port, S-$g0_s_port migration join"
echo cluster join alone | nc localhost $g1_m_port

sleep 5

while [ 1 ]
do
   echo "Migration join count: $join_num"
   echo "g1 M-$g1_m_port, S-$g1_s_port migration join"
   echo cluster join begin | nc localhost $g1_m_port
   echo "g2 M-$g2_m_port, S-$g2_s_port migration join"
   echo cluster join | nc localhost $g2_m_port
   echo "g3 M-$g3_m_port, S-$g3_s_port migration join"
   echo cluster join | nc localhost $g3_m_port
   echo "g4 M-$g4_m_port, S-$g4_s_port migration join"
   echo cluster join end | nc localhost $g4_m_port
   echo "send all migration join command"
   join_num=`expr $join_num +1`;

   sleep 10

   echo "Migration leave count: $leave_num"
   echo "g1 M-$g1_m_port, S-$g1_s_port migration leave"
   echo cluster leave begin | nc localhost $g1_m_port
   echo "g2 M-$g2_m_port, S-$g2_s_port migration leave"
   echo cluster leave | nc localhost $g2_m_port
   echo "g3 M-$g3_m_port, S-$g3_s_port migration leave"
   echo cluster leave | nc localhost $g3_m_port
   echo "g4 M-$g4_m_port, S-$g4_s_port migration leave"
   echo cluster leave end | nc localhost $g4_m_port
   echo "send all migration leave command"
   leave_num=`expr $leave_num +1`;

   sleep 30
done
