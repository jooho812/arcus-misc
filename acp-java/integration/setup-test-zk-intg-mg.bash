# Find os type. if system`s os is Mac OS X, we use greadlink.
case "$OSTYPE" in
  darwin*) DIR=`greadlink -f $0`;;
  *) DIR=`readlink -f $0`;;
esac

DIR=`dirname $DIR`

ZK_CLI="$DIR/../../../arcus/zookeeper/bin/zkCli.sh"
ZK_ADDR="-server localhost:9181"

$ZK_CLI $ZK_ADDR create /arcus_repl 0

$ZK_CLI $ZK_ADDR create /arcus_repl/client_list 0
$ZK_CLI $ZK_ADDR create /arcus_repl/client_list/test_mg 0

$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_log 0

$ZK_CLI $ZK_ADDR create /arcus_repl/cache_list 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_list/test_mg 0

$ZK_CLI $ZK_ADDR create /arcus_repl/group_list 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_mg 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_mg/g0 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_mg/g1 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_mg/g2 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_mg/g3 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_mg/g4 0

$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11281 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11281/test_mg^g0^10.32.27.100:20125^10.32.27.100:21125 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11282 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11282/test_mg^g0^10.32.27.100:20126^10.32.27.100:21126 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11283 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11283/test_mg^g1^10.32.27.100:20127^10.32.27.100:21127 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11284 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11284/test_mg^g1^10.32.27.100:20128^10.32.27.100:21128 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11285 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11285/test_mg^g2^10.32.27.100:20129^10.32.27.100:21129 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11286 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11286/test_mg^g2^10.32.27.100:20130^10.32.27.100:21130 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11287 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11287/test_mg^g3^10.32.27.100:20131^10.32.27.100:21131 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11288 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11288/test_mg^g3^10.32.27.100:20132^10.32.27.100:21132 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11289 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11289/test_mg^g4^10.32.27.100:20133^10.32.27.100:21133 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11290 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11290/test_mg^g4^10.32.27.100:20134^10.32.27.100:21134 0

$ZK_CLI $ZK_ADDR rmr /arcus_repl/cloud_stat 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cloud_stat 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cloud_stat/test_mg 0
