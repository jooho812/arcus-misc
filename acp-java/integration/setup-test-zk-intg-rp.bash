# Find os type. if system`s os is Mac OS X, we use greadlink.
case "$OSTYPE" in
  darwin*) DIR=`greadlink -f $0`;;
  *) DIR=`readlink -f $0`;;
esac

DIR=`dirname $DIR`

ZK_CLI="$DIR/../../../arcus/zookeeper/bin/zkCli.sh"
ZK_ADDR="-server localhost:9181"

if [ $# -eq 1 ]; then
  M_SERVER_IP="$1"
  S_SERVER_IP="$1"
elif [ $# -eq 2 ]; then
  M_SERVER_IP="$1" # master node ip
  S_SERVER_IP="$2" # slave node ip
else
  echo "Usage) ./integration/setup-test-zk-intg-rp.bash <M_SERVER_IP> [S_SERVER_IP]"
  exit 1
fi

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
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$M_SERVER_IP:11291 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$M_SERVER_IP:11291/test_rp^g0^$M_SERVER_IP:20121 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$S_SERVER_IP:11292 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$S_SERVER_IP:11292/test_rp^g0^$S_SERVER_IP:20122 0

$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$M_SERVER_IP:11293 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$M_SERVER_IP:11293/test_rp^g1^$M_SERVER_IP:20123 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$S_SERVER_IP:11294 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$S_SERVER_IP:11294/test_rp^g1^$S_SERVER_IP:20124 0
