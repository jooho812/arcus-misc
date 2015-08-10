#!/bin/bash

mkdir -p pidfiles

./killandrun.memcached.bash master 11215 NONE
./killandrun.memcached.bash slave 11216 NONE

