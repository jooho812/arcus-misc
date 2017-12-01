#!/usr/bin/perl -w

use strict;

# use port 11281 ~ 11290, 21125 ~ 21134
my $run_time = 600;
my $keyset_size = 10000000;

sub print_usage {
    print "Usage) perl ./integration/run_integration_mig.pl\n";
}

if ($#ARGV == -1) {
    print "runtime = $run_time\n";
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

###########################################
######### 1. group g0 node alone ##########
###########################################
my $cmd = "./integration/run.memcached.bash master 11281";
system($cmd);
$cmd = "./integration/run.memcached.bash slave 11282";
system($cmd);
$cmd = "echo \"cluster join alone\" | nc localhost 11281";
system($cmd);
#print "g0 M-11281, S-11282 migration join\n";
sleep(3);

###########################################
####### 2. start change node daemon #######
###########################################
my $can_migtest_failure = "__can_migtest_failure__";
$cmd = "touch $can_migtest_failure";
system($cmd);
print "migration join/leave daemon start....\n";
$cmd = "./integration/loop.joinleave.mig.bash &";
system($cmd);
sleep(20); # wait for nodes to start

###########################################
############# 3. insert data ##############
###########################################
open CONF, ">tmp-integration-config.txt" or die $!;
print CONF
    "zookeeper=127.0.0.1:9181\n" .
    "service_code=test_mg\n" .
    #"single_server=" . $t_ip . ":" . $t_port . "\n" .
    "client=30\n" .
    "rate=0\n" .
    "request=0\n" .
    "time=100000\n" .
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

$cmd = "java -Xmx3g -Xms3g -Dnet.spy.log.LoggerImpl=net.spy.memcached.compat.log.Log4JLogger" .
       " -classpath $cls_path:. acp -config tmp-integration-config.txt";
printf "RUN COMMAND=%s\n", $cmd;

local $SIG{TERM} = sub { print "TERM SIGNAL\n" };
my $ret = system($cmd);

if ($ret ne 0) {
  print "#########################\n";
  print "TEST FAILED CODE=$ret >> migration insert data\n";
  print "#########################\n";
  $cmd = "rm -rf $can_migtest_failure";
  system($cmd);
  exit(1);
}

###########################################
############### 3. get data ###############
###########################################
open CONF, ">tmp-integration-config.txt" or die $!;
print CONF
    "zookeeper=127.0.0.1:9181\n" .
    "service_code=test_mg\n" .
    #"single_server=" . $t_ip . ":" . $t_port . "\n" .
    "client=20\n" .
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
$cmd = "java -Xmx3g -Xms3g -Dnet.spy.log.LoggerImpl=net.spy.memcached.compat.log.Log4JLogger" .
       " -classpath $cls_path:. acp -config tmp-integration-config.txt";
printf "RUN COMMAND=%s\n", $cmd;

local $SIG{TERM} = sub { print "TERM SIGNAL\n" };
$ret = system($cmd);

$cmd = "rm -rf $can_migtest_failure";
system($cmd);

if ($ret ne 0) {
  print "#########################\n";
  print "TEST FAILED CODE=$ret >> switchover get data\n";
  print "#########################\n";
  exit(1);
}

print "#########################\n";
print "SUCCESS MIGRATION TEST\n";
print "#########################\n";
