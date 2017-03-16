#!/bin/bash

mkdir -p pidfiles

#g0 m-11213 | s-11214
./killandrun.memcached.mg.bash master 11213 NONE
./killandrun.memcached.mg.bash slave 11214 NONE

#g1 m-11215 | s-11216
./killandrun.memcached.mg.bash master 11215 NONE
./killandrun.memcached.mg.bash slave 11216 NONE

#g2 m-11217 | s-11218
./killandrun.memcached.mg.bash master 11217 NONE
./killandrun.memcached.mg.bash slave 11218 NONE

#g3 m-11219 | s-11220
./killandrun.memcached.mg.bash master 11219 NONE
./killandrun.memcached.mg.bash slave 11220 NONE

#g4 m-11221 | s-11222
./killandrun.memcached.mg.bash master 11221 NONE
./killandrun.memcached.mg.bash slave 11222 NONE

