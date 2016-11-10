# Find os type. if system`s os is Mac OS X, we use greadlink.
case "$OSTYPE" in
  darwin*) DIR=`greadlink -f $0`;;
  *) DIR=`readlink -f $0`;;
esac

DIR=`dirname $DIR`

ZK_CLI="$DIR/../../arcus/zookeeper/bin/zkCli.sh"
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
# ehpemeral/sequence znode = <nodeip:port>^<listenip:port>^<sequence> 0
# ehpemeral/sequence znode = <nodeip:port>^<listenip:port>^<sequence> 0

$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11215 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11215/test^g0^127.0.0.1:20125 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11216 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11216/test^g0^127.0.0.1:20126 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11217 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11217/test^g0^127.0.0.1:20127 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11218 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11218/test^g0^127.0.0.1:20128 0

$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11415 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11415/test^g1^127.0.0.1:20325 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11416 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11416/test^g1^127.0.0.1:20326 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11417 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11417/test^g1^127.0.0.1:20327 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11418 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11418/test^g1^127.0.0.1:20328 0
