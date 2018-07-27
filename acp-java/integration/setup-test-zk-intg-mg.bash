# Find os type. if system`s os is Mac OS X, we use greadlink.
case "$OSTYPE" in
  darwin*) DIR=`greadlink -f $0`;;
  *) DIR=`readlink -f $0`;;
esac

DIR=`dirname $DIR`

ZK_CLI="$DIR/../../../arcus/zookeeper/bin/zkCli.sh"
ZK_ADDR="-server localhost:9181"

if [ $# -eq 0 ]; then
  SERVER_IP=`ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print \$1}'`
else
  echo "Usage) ./integration/setup-test-zk-intg-rp.bash";
  exit 1;
fi

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
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$SERVER_IP:11281 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$SERVER_IP:11281/test_mg^g0^$SERVER_IP:20125^$SERVER_IP:21125 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$SERVER_IP:11282 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$SERVER_IP:11282/test_mg^g0^$SERVER_IP:20126^$SERVER_IP:21126 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$SERVER_IP:11283 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$SERVER_IP:11283/test_mg^g1^$SERVER_IP:20127^$SERVER_IP:21127 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$SERVER_IP:11284 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$SERVER_IP:11284/test_mg^g1^$SERVER_IP:20128^$SERVER_IP:21128 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$SERVER_IP:11285 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$SERVER_IP:11285/test_mg^g2^$SERVER_IP:20129^$SERVER_IP:21129 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$SERVER_IP:11286 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$SERVER_IP:11286/test_mg^g2^$SERVER_IP:20130^$SERVER_IP:21130 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$SERVER_IP:11287 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$SERVER_IP:11287/test_mg^g3^$SERVER_IP:20131^$SERVER_IP:21131 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$SERVER_IP:11288 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$SERVER_IP:11288/test_mg^g3^$SERVER_IP:20132^$SERVER_IP:21132 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$SERVER_IP:11289 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$SERVER_IP:11289/test_mg^g4^$SERVER_IP:20133^$SERVER_IP:21133 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$SERVER_IP:11290 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$SERVER_IP:11290/test_mg^g4^$SERVER_IP:20134^$SERVER_IP:21134 0

$ZK_CLI $ZK_ADDR rmr /arcus_repl/cloud_stat 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cloud_stat 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cloud_stat/test_mg 0
