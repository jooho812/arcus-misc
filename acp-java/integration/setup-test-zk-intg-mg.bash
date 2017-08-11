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
# ehpemeral znode = <group>^M^<ip:port-hostname> 0 // created by cache node
# ehpemeral znode = <group>^S^<ip:port-hostname> 0 // created by cache node

$ZK_CLI $ZK_ADDR create /arcus_repl/group_list 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_mg 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_mg/g0 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_mg/g1 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_mg/g2 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_mg/g3 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_mg/g4 0
# ehpemeral/sequence znode = <nodeip:port>^<listenip:port>^<sequence> 0
# ehpemeral/sequence znode = <nodeip:port>^<listenip:port>^<sequence> 0

$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11281 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11281/test_mg^g0^127.0.0.1:20125^127.0.0.1:21125 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11282 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11282/test_mg^g0^127.0.0.1:20126^127.0.0.1:21126 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11283 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11283/test_mg^g1^127.0.0.1:20127^127.0.0.1:21127 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11284 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11284/test_mg^g1^127.0.0.1:20128^127.0.0.1:21128 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11285 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11285/test_mg^g2^127.0.0.1:20129^127.0.0.1:21129 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11286 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11286/test_mg^g2^127.0.0.1:20130^127.0.0.1:21130 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11287 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11287/test_mg^g3^127.0.0.1:20131^127.0.0.1:21131 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11288 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11288/test_mg^g3^127.0.0.1:20132^127.0.0.1:21132 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11289 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11289/test_mg^g4^127.0.0.1:20133^127.0.0.1:21133 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11290 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11290/test_mg^g4^127.0.0.1:20134^127.0.0.1:21134 0

$ZK_CLI $ZK_ADDR create /arcus_repl/cloud_stat 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cloud_stat/test_mg 0
