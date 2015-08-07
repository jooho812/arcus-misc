#!/bin/bash
################################################################################
# acp-misc : make config.txt 
################################################################################
#
#  0. configure file name
#
#  0. pretty_stat
#  1. zookeeper
#  2. service code
#  3. single_server
#  4. client
#  5. rate
#  6. irg
#  7. request
#  8. time
#  9. pool
# 10. pool_size
# 11. pool_use_random
# 12. keyset_profile
# 13. keyset_size
# 14. keyset_length
# 15. key_prefix
# 16. valueset_profile
# 17. valueset_min_size
# 18. valueset_max_size
# 19. client_profile
# 20. client_exptime
# 21. client_mget_keys
#
################################################################################


##
##
##
##
##

bool_mkconf=0

function usage() {
  echo "Usage:"
  echo "  $0 -c <configure_file_name>"
  echo "  $0 -m <configure_file_name>"
}

function get_opts() {
	# check number of argv..
	if [ "$#" -ne 2 ]; then
		usage
		exit 1
	fi

	# check option validation..
	if [ "$1" == "-c" ]; then
		bool_mkconf=1
	elif [ "$1" == "m"]; then
		bool_mkconf=2		
	fi
}

function mkconf() {
	configure=$'pretty_stat=1\n\n'
	configure=$configure$'zookeeper=2\n\n'
	configure=$configure$'single_server=2\n\n'
	configure=$configure$'client=2\n\n'
	configure=$configure$'rate=2\n\n'
	configure=$configure$'irg=2\n\n'
	configure=$configure$'request=2\n\n'
	configure=$configure$'time=2\n\n'
	configure=$configure$'pool=2\n\n'
	configure=$configure$'pool_size=2\n\n'
	configure=$configure$'pool_use_random=2\n\n'
	configure=$configure$'keyset_profile=2\n\n'
	configure=$configure$'keyset_size=2\n\n'
	configure=$configure$'keyset_length=2\n\n'
	configure=$configure$'key_prefix=2\n\n'
	configure=$configure$'valueset_profile=2\n\n'
	configure=$configure$'valueset_min_size=2\n\n'
	configure=$configure$'valueset_max_size=2\n\n'
	configure=$configure$'client_profile=2\n\n'
	configure=$configure$'client_exptime=2\n\n'
	configure=$configure$'client_mget_keys=2\n\n'
	echo $'\n\n'
	#echo $0
	#echo $1
	#echo $2
	echo "$configure" >> $2
	#echo "$configure"
}



## MAIN ##
get_opts $*

if [ $bool_mkconf -eq 1 ]; then
	mkconf $*	
elif [ $bool_mkconf -eq 2]; then
	echo -m option...
fi





