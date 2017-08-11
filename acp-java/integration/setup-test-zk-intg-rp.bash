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
$ZK_CLI $ZK_ADDR create /arcus_repl/client_list/test_rp 0

$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_log 0

$ZK_CLI $ZK_ADDR create /arcus_repl/cache_list 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_list/test_rp 0
# ehpemeral znode = <group>^M^<ip:port-hostname> 0 // created by cache node
# ehpemeral znode = <group>^S^<ip:port-hostname> 0 // created by cache node

$ZK_CLI $ZK_ADDR create /arcus_repl/group_list 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_rp 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_rp/g0 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_rp/g1 0 #for switchover
# ehpemeral/sequence znode = <nodeip:port>^<listenip:port>^<sequence> 0
# ehpemeral/sequence znode = <nodeip:port>^<listenip:port>^<sequence> 0

$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11291 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11291/test_rp^g0^127.0.0.1:20121 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11292 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11292/test_rp^g0^127.0.0.1:20122 0

$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11293 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11293/test_rp^g1^127.0.0.1:20123 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11294 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/127.0.0.1:11294/test_rp^g1^127.0.0.1:20124 0

