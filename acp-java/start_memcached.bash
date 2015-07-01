DIR=`readlink -f $0`
DIR=`dirname $DIR`
MEMC_DIR=$DIR/../../arcus-memcached
thread_count=32

mkdir -p pidfiles

#$MEMC_DIR/memcached -E $MEMC_DIR/.libs/default_engine.so -X $MEMC_DIR/.libs/ascii_scrub.so -d -v -r -R5 -U 0 -D: -b 8192 -m2000 -p 11215 -c 1000 -t $thread_count -z 127.0.0.1:2181 -e "replication_config_file=replication.config;" -P pidfiles/memcached.127.0.0.1:11215 -o 3 -g 100
#$MEMC_DIR/memcached -E $MEMC_DIR/.libs/default_engine.so -X $MEMC_DIR/.libs/ascii_scrub.so -d -v -r -R5 -U 0 -D: -b 8192 -m2000 -p 11216 -c 1000 -t $thread_count -z 127.0.0.1:2181 -e "replication_config_file=replication.config;" -P pidfiles/memcached.127.0.0.1:11216 -o 3 -g 100
$MEMC_DIR/memcached -E $MEMC_DIR/.libs/default_engine.so -X $MEMC_DIR/.libs/syslog_logger.so -X $MEMC_DIR/.libs/ascii_scrub.so -d -v -r -R5 -U 0 -D: -b 8192 -m2000 -p 11215 -c 1000 -t $thread_count -z 127.0.0.1:2181 -e "replication_config_file=replication.config;" -P pidfiles/memcached.127.0.0.1:11215 -o 3 -g 100
$MEMC_DIR/memcached -E $MEMC_DIR/.libs/default_engine.so -X $MEMC_DIR/.libs/syslog_logger.so -X $MEMC_DIR/.libs/ascii_scrub.so -d -v -r -R5 -U 0 -D: -b 8192 -m2000 -p 11216 -c 1000 -t $thread_count -z 127.0.0.1:2181 -e "replication_config_file=replication.config;" -P pidfiles/memcached.127.0.0.1:11216 -o 3 -g 100
