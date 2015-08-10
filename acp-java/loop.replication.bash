#!/bin/bash

COUNTER=1
while :
do 
  duration=`expr \( \( $COUNTER - 1 \) % 5 + 1 \) \* 100`
  #duration=100

  echo "./all.replication.bash $duration $COUNTER"
  ./all.replication.bash $duration $COUNTER

  let COUNTER=COUNTER+1

done
