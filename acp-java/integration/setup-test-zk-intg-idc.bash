# Find os type. if system`s os is Mac OS X, we use greadlink.
case "$OSTYPE" in
  darwin*) DIR=`greadlink -f $0`;;
  *) DIR=`readlink -f $0`;;
esac

DIR=`dirname $DIR`

ZK_CLI="$DIR/../../../arcus/zookeeper/bin/zkCli.sh"
ZK_ADDR="-server localhost:9181"

if [ $# -eq 2 ]; then
    N3_CLUSTER_IP="$1"
    N4_CLUSTER_IP="$2"
else
    echo "Usage) ./integration/setup-test-zk-intg-idc.bash <3nodeClusterIp> <4nodeClusterIp>"
    exit 1;
fi

$ZK_CLI $ZK_ADDR create /arcus_repl 0

$ZK_CLI $ZK_ADDR create /arcus_repl/client_list 0
$ZK_CLI $ZK_ADDR create /arcus_repl/client_list/test_idc 0

$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_log 0

$ZK_CLI $ZK_ADDR create /arcus_repl/cache_list 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_list/test_idc 0

$ZK_CLI $ZK_ADDR create /arcus_repl/group_list 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_idc 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_idc/g0 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_idc/g1 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_idc/g2 0

$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_idc/g3 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_idc/g4 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_idc/g5 0
$ZK_CLI $ZK_ADDR create /arcus_repl/group_list/test_idc/g6 0

$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping 0

# cluster A (3 node)
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N3_CLUSTER_IP:11301 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N3_CLUSTER_IP:11301/test_idc^g0^$N3_CLUSTER_IP:20221^$N3_CLUSTER_IP:21221^$N3_CLUSTER_IP:22221 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N3_CLUSTER_IP:11302 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N3_CLUSTER_IP:11302/test_idc^g0^$N3_CLUSTER_IP:20222^$N3_CLUSTER_IP:21222^$N3_CLUSTER_IP:22222 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N3_CLUSTER_IP:11303 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N3_CLUSTER_IP:11303/test_idc^g1^$N3_CLUSTER_IP:20223^$N3_CLUSTER_IP:21223^$N3_CLUSTER_IP:22223 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N3_CLUSTER_IP:11304 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N3_CLUSTER_IP:11304/test_idc^g1^$N3_CLUSTER_IP:20224^$N3_CLUSTER_IP:21224^$N3_CLUSTER_IP:22224 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N3_CLUSTER_IP:11305 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N3_CLUSTER_IP:11305/test_idc^g2^$N3_CLUSTER_IP:20225^$N3_CLUSTER_IP:21225^$N3_CLUSTER_IP:22225 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N3_CLUSTER_IP:11306 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N3_CLUSTER_IP:11306/test_idc^g2^$N3_CLUSTER_IP:20226^$N3_CLUSTER_IP:21226^$N3_CLUSTER_IP:22226 0

$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N3_CLUSTER_IP:11301 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N3_CLUSTER_IP:11302 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N3_CLUSTER_IP:11303 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N3_CLUSTER_IP:11304 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N3_CLUSTER_IP:11305 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N3_CLUSTER_IP:11306 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N3_CLUSTER_IP:11301/test_idc^$N3_CLUSTER_IP:23221 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N3_CLUSTER_IP:11302/test_idc^$N3_CLUSTER_IP:23222 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N3_CLUSTER_IP:11303/test_idc^$N3_CLUSTER_IP:23223 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N3_CLUSTER_IP:11304/test_idc^$N3_CLUSTER_IP:23224 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N3_CLUSTER_IP:11305/test_idc^$N3_CLUSTER_IP:23225 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N3_CLUSTER_IP:11306/test_idc^$N3_CLUSTER_IP:23226 0

# cluster B (4 node)
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N4_CLUSTER_IP:11307 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N4_CLUSTER_IP:11307/test_idc^g3^$N4_CLUSTER_IP:20227^$N4_CLUSTER_IP:21227^$N4_CLUSTER_IP:22227 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N4_CLUSTER_IP:11308 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N4_CLUSTER_IP:11308/test_idc^g3^$N4_CLUSTER_IP:20228^$N4_CLUSTER_IP:21228^$N4_CLUSTER_IP:22228 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N4_CLUSTER_IP:11309 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N4_CLUSTER_IP:11309/test_idc^g4^$N4_CLUSTER_IP:20229^$N4_CLUSTER_IP:21229^$N4_CLUSTER_IP:22229 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N4_CLUSTER_IP:11310 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N4_CLUSTER_IP:11310/test_idc^g4^$N4_CLUSTER_IP:20230^$N4_CLUSTER_IP:21230^$N4_CLUSTER_IP:22230 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N4_CLUSTER_IP:11311 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N4_CLUSTER_IP:11311/test_idc^g5^$N4_CLUSTER_IP:20231^$N4_CLUSTER_IP:21231^$N4_CLUSTER_IP:22231 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N4_CLUSTER_IP:11312 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N4_CLUSTER_IP:11312/test_idc^g5^$N4_CLUSTER_IP:20232^$N4_CLUSTER_IP:21232^$N4_CLUSTER_IP:22232 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N4_CLUSTER_IP:11313 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N4_CLUSTER_IP:11313/test_idc^g6^$N4_CLUSTER_IP:20233^$N4_CLUSTER_IP:21233^$N4_CLUSTER_IP:22233 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N4_CLUSTER_IP:11314 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cache_server_mapping/$N4_CLUSTER_IP:11314/test_idc^g6^$N4_CLUSTER_IP:20234^$N4_CLUSTER_IP:21234^$N4_CLUSTER_IP:22234 0

$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N4_CLUSTER_IP:11307 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N4_CLUSTER_IP:11308 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N4_CLUSTER_IP:11309 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N4_CLUSTER_IP:11310 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N4_CLUSTER_IP:11311 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N4_CLUSTER_IP:11312 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N4_CLUSTER_IP:11313 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N4_CLUSTER_IP:11314 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N4_CLUSTER_IP:11307/test_idc^$N4_CLUSTER_IP:23227 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N4_CLUSTER_IP:11308/test_idc^$N4_CLUSTER_IP:23228 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N4_CLUSTER_IP:11309/test_idc^$N4_CLUSTER_IP:23229 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N4_CLUSTER_IP:11310/test_idc^$N4_CLUSTER_IP:23230 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N4_CLUSTER_IP:11311/test_idc^$N4_CLUSTER_IP:23231 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N4_CLUSTER_IP:11312/test_idc^$N4_CLUSTER_IP:23232 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N4_CLUSTER_IP:11313/test_idc^$N4_CLUSTER_IP:23233 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_server_mapping/$N4_CLUSTER_IP:11314/test_idc^$N4_CLUSTER_IP:23234 0

$ZK_CLI $ZK_ADDR create /arcus_repl/xdcr_list 0
$ZK_CLI $ZK_ADDR create /arcus_repl/xdcr_list/test_idc 0

$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_list 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_list/test_idc 0
$ZK_CLI $ZK_ADDR create /arcus_repl/bridge_list/test_idc/xdcr_node 0

$ZK_CLI $ZK_ADDR create /arcus_repl/zkensemble_list 0
$ZK_CLI $ZK_ADDR create /arcus_repl/zkensemble_list/test_idc 0

$ZK_CLI $ZK_ADDR create /arcus_repl/cloud_stat 0
$ZK_CLI $ZK_ADDR create /arcus_repl/cloud_stat/test_idc 0
