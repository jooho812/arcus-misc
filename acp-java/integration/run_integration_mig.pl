#!/usr/bin/perl -w

use strict;
use Term::ANSIColor qw(:constants);

# use port 11281 ~ 11290, 21125 ~ 21134
my $t_ip   = "127.0.0.1";
my $t_port = "9181";
my $t_server = $t_ip . ":" . $t_port;
my $flag = -1; # -1 : start test(client, server)
               #  0 : start test(only server)
               # >0 : start test(only client)
my $run_time = 600;
my $keyset_size = 10000000;
my $cmd;
my $ret;

sub print_usage {
    print "Usage) perl ./integration/run_integration_mig.pl [server(0) client(1)]\n";
}

if ($#ARGV le 0) {
    if ($#ARGV eq 0) {
        if ($ARGV[0] ) {
            $flag = 1;
        } else {
            $flag = 0;
        }
    }
    print "runtime = $run_time\n";
    print "keyset_size = $keyset_size\n";
    print "t_server = $t_server\n";
    print "flag = $flag\n";
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

if ($flag eq -1 || $flag eq 0) {
    ###########################################
    ######### 1. group g0 node alone ##########
    ###########################################
    $cmd = "./integration/run.memcached.bash master 11281;"
            . "./integration/run.memcached.bash slave 11282;"
            . "./integration/run.memcached.bash master 11283;"
            . "./integration/run.memcached.bash slave 11284;"
            . "./integration/run.memcached.bash master 11285;"
            . "./integration/run.memcached.bash slave 11286;"
            . "./integration/run.memcached.bash master 11287;"
            . "./integration/run.memcached.bash slave 11288;"
            . "./integration/run.memcached.bash master 11289;"
            . "./integration/run.memcached.bash slave 11290";
    system($cmd);
    print "11281, 11282, 11283, 11284, 11285, 11286, 11287, 11288, 11289, 11290 memcached node start";
    sleep(3);
    $cmd = "echo \"cluster join alone\" | nc localhost 11281"; system($cmd);
    print GREEN, "g0 M-11281, S-11282 migration join\n", RESET; sleep(3);
    $cmd = "echo \"cluster join begin\" | nc localhost 11283"; system($cmd);
    print GREEN, "g0 M-11283, S-11284 migration join\n", RESET; sleep(1);
    $cmd = "echo \"cluster join end\" | nc localhost 11285"; system($cmd);
    print GREEN, "g0 M-11285, S-11286 migration join\n", RESET; sleep(10);
    $ret = 0;
}

if ($flag eq -1 || $flag eq 1) {
    ###########################################
    ############# 2. insert data ##############
    ###########################################
    open CONF, ">tmp-integration-config.txt" or die $!;
    print CONF
        "zookeeper=$t_server\n" .
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
        "pool_use_random=true\n" .
        "key_prefix=integrationtest:\n" .
        "client_exptime=0\n" .
        "client_profile=integration_onlyset\n";
    close CONF;

    $cmd = "java -Xmx3g -Xms3g -Dnet.spy.log.LoggerImpl=net.spy.memcached.compat.log.Log4JLogger" .
           " -classpath $cls_path:. acp -config tmp-integration-config.txt";
    printf "RUN COMMAND=%s\n", $cmd;

    local $SIG{TERM} = sub { print "TERM SIGNAL\n" };
    $ret = system($cmd);

    if ($ret ne 0) {
      print RED, "#########################\n";
      print "TEST FAILED CODE=$ret >> migration insert data\n";
      print "#########################\n", RESET;
      exit(1);
    }

    ###########################################
    ############### 3. get data ###############
    ###########################################
    open CONF, ">tmp-integration-config.txt" or die $!;
    print CONF
        "zookeeper=$t_server\n" .
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
        "pool_use_random=true\n" .
        "key_prefix=integrationtest:\n" .
        "client_exptime=0\n" .
        "client_profile=integration_onlyget\n";
    close CONF;
    $cmd = "java -Xmx3g -Xms3g -Dnet.spy.log.LoggerImpl=net.spy.memcached.compat.log.Log4JLogger" .
           " -classpath $cls_path:. acp -config tmp-integration-config.txt";
    printf "RUN COMMAND=%s\n", $cmd;

    local $SIG{TERM} = sub { print "TERM SIGNAL\n" };
    $ret = system($cmd);

    if ($ret ne 0) {
      print RED, "#########################\n";
      print "TEST FAILED CODE=$ret >> switchover get data\n";
      print "#########################\n", RESET;
      exit(1);
    }

    ###########################################
    ############## 4. flush data ##############
    ###########################################
#    $cmd = "./integration/migration_start_manual.bash 2 $t_ip"; # flush_all and scrub all nodes
#    system($cmd);
#    print GREEN, "flush_all and scrub all nodes sleep 15 sec\n", RESET;
#    sleep 15;

    ###########################################
    ########## 5. join/leave start ############
    ###########################################
    print GREEN, "join/leave start\n", RESET;
    $cmd = "touch __can_migtest_failure__";
    system($cmd);
    sleep 1;
    $cmd = "./integration/migration_start_auto.bash $t_ip &";
    system($cmd);
    sleep 5;

    ###########################################
    ############## 6. intg test ###############
    ###########################################
    open CONF, ">tmp-integration-config.txt" or die $!;
    print CONF
        "zookeeper=$t_server\n" .
        "service_code=test_mg\n" .
        #"single_server=" . $t_ip . ":" . $t_port . "\n" .
        "client=30\n" .
        "rate=500\n" .
        "request=0\n" .
        "time=$run_time\n" .
        "keyset_size=$keyset_size\n" .
        "valueset_min_size=20\n" .
        "valueset_max_size=20\n" .
        "pool=1\n" .
        "pool_size=20\n" .
        "pool_use_random=true\n" .
        "key_prefix=integrationtest:\n" .
        "client_exptime=0\n" .
        "client_profile=integration_arcus\n";
    close CONF;
    $cmd = "java -Xmx3g -Xms3g -Dnet.spy.log.LoggerImpl=net.spy.memcached.compat.log.Log4JLogger" .
           " -classpath $cls_path:. acp -config tmp-integration-config.txt";
    printf "RUN COMMAND=%s\n", $cmd;

    local $SIG{TERM} = sub { print "TERM SIGNAL\n" };
    $ret = system($cmd);

    $cmd = "rm -rf __can_migtest_failure__";
    system($cmd);
}

if ($ret ne 0) {
  print RED, "#########################\n";
  print "TEST FAILED CODE=$ret >> integration test in migration\n";
  print "#########################\n", RESET;
  exit(1);
} else {
  print GREEN, "#########################\n";
  print "SUCCESS MIGRATION TEST\n";
  print "#########################\n", RESET;
}
