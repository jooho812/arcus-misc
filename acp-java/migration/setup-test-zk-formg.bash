# Find os type. if system`s os is Mac OS X, we use greadlink.
case "$OSTYPE" in
  darwin*) DIR=`greadlink -f $0`;;
  *) DIR=`readlink -f $0`;;
esac

DIR=`dirname $DIR`

ZK_CLI="$DIR/../../../../arcus/zookeeper/bin/zkCli.sh"
ZK_ADDR="-server localhost:2181"

$ZK_CLI $ZK_ADDR create /arcus_repl 0

$ZK_CLI $ZK_ADDR create /arcus_repl/client_list 0
$ZK_CLI $ZK_ADDR create /arcus_repl/client_list/test 0

$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_log 0

$ZK_CLI $ZK_ADDR create /arcus_repl/cache_list 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_list/test 0
# ehpemeral znode = <group>^M^<ip:port-hostname> 0 // created by cache node
# ehpemeral znode = <group>^S^<ip:port-hostname> 0 // created by cache node

$ZK_CLI $ZK_ADDR create /arcus_repl/group_list 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test/g0 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test/g1 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test/g2 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test/g3 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test/g4 0
# ehpemeral/sequence znode = <nodeip:port>^<listenip:port>^<sequence> 0
# ehpemeral/sequence znode = <nodeip:port>^<listenip:port>^<sequence> 0

$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11213 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11213/test^g0^127.0.0.1:20123^127.0.0.1:21123 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11214 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11214/test^g0^127.0.0.1:20124^127.0.0.1:21124 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11215 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11215/test^g1^127.0.0.1:20125^127.0.0.1:21125 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11216 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11216/test^g1^127.0.0.1:20126^127.0.0.1:21126 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11217 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11217/test^g2^127.0.0.1:20127^127.0.0.1:21127 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11218 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11218/test^g2^127.0.0.1:20128^127.0.0.1:21128 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11219 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11219/test^g3^127.0.0.1:20129^127.0.0.1:21129 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11220 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11220/test^g3^127.0.0.1:20130^127.0.0.1:21130 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11221 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11221/test^g4^127.0.0.1:20131^127.0.0.1:21131 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11222 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11222/test^g4^127.0.0.1:20132^127.0.0.1:21132 0

#$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11215 0
#$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11215/test^g0^127.0.0.1:20125^217.0.0.1:21125 0
#$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11216 0
#$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11216/test^g0^127.0.0.1:20126^127.0.0.1:21126 0

$ZK_CLI $ZK_ADDR create /arcus_repl/cloud_stat 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cloud_stat/test 0
