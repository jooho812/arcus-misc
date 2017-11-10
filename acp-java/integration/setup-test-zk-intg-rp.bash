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

$ZK_CLI $ZK_ADDR create /arcus_repl/group_list 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_rp 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_rp/g0 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_rp/g1 0 #for switchover

$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11291 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11291/test_rp^g0^10.32.27.100:20121 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11292 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11292/test_rp^g0^10.32.27.100:20122 0

$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11293 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11293/test_rp^g1^10.32.27.100:20123 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11294 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/10.32.27.100:11294/test_rp^g1^10.32.27.100:20124 0

