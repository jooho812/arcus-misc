#!/usr/bin/perl -w

use strict;

my $m_port = 11291; # master port
my $s_port = 11292; # slave  port
my $run_time = 0;
my $keyset_size = 10000000;

sub print_usage {
  print "Usage) perl ./integration/run_integration_repl.pl master_port slave_port run_time [keyset_size]\n";
}

if ($#ARGV == 2 || $#ARGV == 3) {
  $m_port = $ARGV[0];
  $s_port = $ARGV[1];
  $run_time = $ARGV[2];
  if ($#ARGV == 3) {
    $keyset_size = $ARGV[3];
  }
  print "master_port = $m_port\n";
  print "slave_port  = $s_port\n";
  print "run_time = $run_time\n";
  print "keyset_size = $keyset_size\n";
} else {
  print_usage();
  die;
}

use Cwd 'abs_path';
use File::Basename;

my $filename = abs_path($0);
my $dir_path = dirname($filename);

print "filename = $filename\n";
print "dir_path = $dir_path\n";

my $jar_path = "$dir_path/../../../arcus-java-client/target";
my $cls_path = "$jar_path/arcus-java-client-1.11.0.jar" .
    ":$jar_path/zookeeper-3.4.5.jar:$jar_path/log4j-1.2.16.jar" .
    ":$jar_path/slf4j-api-1.6.1.jar:$jar_path/slf4j-log4j12-1.6.1.jar";

########################################
# 1. start node(znode must be created) #
########################################
my $cmd = "./integration/start_memcached_replication.bash $m_port $s_port";
system($cmd);
sleep 1;

########################################
###### 2. opertion in master node ######
########################################
open CONF, ">tmp-integration-config.txt" or die $!;
print CONF
    "zookeeper=127.0.0.1:9181\n" .
    "service_code=test_rp\n" .
    #"single_server=" . $t_ip . ":" . $t_port . "\n" .
    "client=30\n" .
    "rate=0\n" .
    "request=0\n" .
    "time=99999\n" .
    "keyset_size=$keyset_size\n" .
    "valueset_min_size=20\n" .
    "valueset_max_size=20\n" .
    "pool=1\n" .
    "pool_size=20\n" .
    "pool_use_random=false\n" .
    "key_prefix=integrationtest:\n" .
    "client_exptime=0\n" .
    "client_profile=integration_onlyset\n";
close CONF;

$cmd = "java -Xmx2g -Xms2g -Dnet.spy.log.LoggerImpl=net.spy.memcached.compat.log.Log4JLogger" .
       " -classpath $cls_path:. acp -config tmp-integration-config.txt";
printf "RUN COMMAND=%s\n", $cmd;

local $SIG{TERM} = sub { print "TERM SIGNAL\n" };
my $ret = system($cmd);

if ($ret ne 0) {
  print "#########################\n";
  print "TEST FAILED CODE=$ret >> replication operation in master node\n";
  print "#########################\n";
  exit(1);
}

########################################
############ 3. master kill ############
########################################
$cmd = "kill \$(ps -ef | awk '/-e replication_config_file=replication.config; -p $m_port/ {print \$2}')";
printf "RUN COMMAND = $cmd\n";
printf "master node($m_port) kill\n";
system($cmd);

sleep 1; # wait switchover time

########################################
### 4. check cache item in slave node ##
########################################
open CONF, ">tmp-integration-config.txt" or die $!;
print CONF
    "zookeeper=127.0.0.1:9181\n" .
    "service_code=test_rp\n" .
    #"single_server=" . $t_ip . ":" . $t_port . "\n" .
    "client=1\n" .
    "rate=0\n" .
    "request=0\n" .
    "time=$run_time\n" .
    "keyset_size=$keyset_size\n" .
    "valueset_min_size=20\n" .
    "valueset_max_size=20\n" .
    "pool=1\n" .
    "pool_size=20\n" .
    "pool_use_random=false\n" .
    "key_prefix=integrationtest:\n" .
    "client_exptime=0\n" .
    "client_profile=integration_onlyget\n";
close CONF;
$cmd = "java -Xmx2g -Xms2g -Dnet.spy.log.LoggerImpl=net.spy.memcached.compat.log.Log4JLogger" .
       " -classpath $cls_path:. acp -config tmp-integration-config.txt";
printf "RUN COMMAND=%s\n", $cmd;

local $SIG{TERM} = sub { print "TERM SIGNAL\n" };
$ret = system($cmd);

if ($ret ne 0) {
  print "#########################\n";
  print "TEST FAILED CODE=$ret >> replication check cache item in slave node\n";
  print "#########################\n";
  exit(1);
}

########################################
############ 5. slave kill #############
########################################
$cmd = "kill \$(ps -ef | awk '/-e replication_config_file=replication.config; -p $s_port/ {print \$2}')";
printf "RUN COMMAND = $cmd\n";
printf "slave node($s_port) kill\n";
system($cmd);

print "#########################\n";
print "SUCCESS REPLICATION TEST\n";
print "#########################\n";
