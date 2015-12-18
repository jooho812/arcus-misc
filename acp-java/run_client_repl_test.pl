#!/usr/bin/perl -w

$m_port = 0; # master port
$s_port = 0; # slave  port
$failure_type = "none"; # failure type
$run_duration = 0;
$compare_flag = 0;

sub print_usage {
  print "Usage) perl ./run_all_repl_test.pl master_port slave_port failure_type run_duration [compare]\n";
}

if ($#ARGV >= 3 && $#ARGV <= 4) {
  $m_port = $ARGV[0];
  $s_port = $ARGV[1];
  $failure_type = $ARGV[2];
  $run_duration = $ARGV[3];
  if ($#ARGV == 4) {
    if ($ARGV[4] eq 'compare') {
      $compare_flag = 0;
    } else {
      print_usage();
      die;
    }
  }
  print "master_port = $m_port\n";
  print "slave_port  = $s_port\n";
  print "failure_type  = $failure_type\n";
  print "run_duration = $run_duration\n";
  print "compare_flag = $compare_flag\n";
} else {
  print_usage();
  die;
}

use Cwd 'abs_path';
use File::Basename;

$filename = abs_path($0);
$dir_path = dirname($filename);

print "filename = $filename\n";
print "dir_path = $dir_path\n";

$jar_path = "$dir_path/../../arcus-java-client/target";
$cls_path = "$jar_path/arcus-java-client-1.9.2.jar" .
    ":$jar_path/zookeeper-3.4.5.jar:$jar_path/log4j-1.2.16.jar" .
    ":$jar_path/slf4j-api-1.6.1.jar:$jar_path/slf4j-log4j12-1.6.1.jar";

$comp_dir = "$dir_path/../compare";
$comp_cmd = "java -classpath $cls_path:$comp_dir" .
            " compare -keydump $dir_path/keydump*" .
            " -server localhost:$m_port -server localhost:$s_port";
print "comp_cmd = $comp_cmd\n";

# Create a temporary default config file to run the test
open CONF, ">tmp-default-config.txt" or die $!;
print CONF
  "zookeeper=127.0.0.1:2181\n" .
  "service_code=test\n" .
  "client=2\n" .
#  "rate=300\n" .
  "rate=0\n" .
  "request=0\n" .
  "time=" . $run_duration . "\n" .
  "keyset_size=1000000\n" .
  "valueset_min_size=10\n" .
  "valueset_max_size=4000\n" .
  "pool=1\n" .
  "pool_size=1\n" .
  "pool_use_random=false\n" .
  "client_timeout=3000\n" .
  "client_exptime=0\n";
close CONF;

$cmd = "perl config_file_generator.pl tmp-default-config.txt basic_repl_test_description.txt";
system($cmd);

@configfile_list = (
    "config-repl-standard_mix.txt"
  , "config-repl-simple_getset.txt"
  , "config-repl-simple_set.txt"
  , "config-repl-tiny_btree.txt"
  , "config-repl-torture_arcus_integration.txt"
  , "config-repl-torture_btree.txt"
  , "config-repl-torture_btree_bytebkey.txt"
  , "config-repl-torture_btree_bytemaxbkeyrange.txt"
  , "config-repl-torture_btree_decinc.txt"
  , "config-repl-torture_btree_exptime.txt"
  , "config-repl-torture_btree_ins_del.txt"
  , "config-repl-torture_btree_maxbkeyrange.txt"
  , "config-repl-torture_btree_replace.txt"
  , "config-repl-torture_cas.txt"
  , "config-repl-torture_list.txt"
  , "config-repl-torture_list_ins_del.txt"
  , "config-repl-torture_set.txt"
  , "config-repl-torture_set_ins_del.txt"
  , "config-repl-torture_simple_decinc.txt"
  , "config-repl-torture_list_ins_bulkdel.txt"
  , "config-repl-torture_btree_ins_bulkdel.txt"
  , "config-repl-torture_list_ins_getwithdelete.txt"
  , "config-repl-torture_btree_ins_getwithdelete.txt"
  , "config-repl-torture_set_ins_getwithdelete.txt"
  , "config-repl-torture_btree_ins_maxelement.txt"
  , "config-repl-torture_list_ins_maxelement.txt"
  , "config-repl-simple_set_1mb.txt"
);

#@configfile_list = (
#  "config-repl-torture_btree_ins_maxelement.txt"
#  "config-repl-simple_set_1mb.txt"
#    "config-repl-standard_mix.txt"
#);

#$cmd = "rm -f __can_test_failure__";
#system($cmd);

@clientcase_list = (
    "case1"
  , "case2"
  , "case3"
  , "case4"
  , "case5"
  , "case6"
  , "case7"
  , "case8"
  , "case9"
  , "case10"
  , "case11"
  , "case12"
);

foreach $configfile (@configfile_list) {
foreach $clientcase (@clientcase_list) {
  # Flush all before each test
  $cmd = "./flushall.bash localhost $m_port";
  print "DO_FLUSH_ALL. $cmd\n";
  system($cmd);
  sleep 1;

  $cmd = "./flushall.bash localhost $s_port";
  print "DO_FLUSH_ALL. $cmd\n";
  system($cmd);
  sleep 1;

  $cmd = "touch __can_test_failure__";
  system($cmd);

  if ($failure_type eq "all_kill") {
    $cmd = "./loop.memcached.bash $m_port $s_port all KILL 10 10 1000000 &";
    $ret = system($cmd);
  }
  elsif ($failure_type eq "all_stop") {
    $cmd = "./loop.memcached.bash $m_port $s_port all INT 10 10 1000000 &";
    $ret = system($cmd);
  }
  elsif ($failure_type eq "master_kill") {
    $cmd = "./loop.memcached.bash $m_port $s_port master KILL 10 10 1000000 &";
    $ret = system($cmd);
  }
  elsif ($failure_type eq "master_stop") {
    $cmd = "./loop.memcached.bash $m_port $s_port master INT 10 10 1000000 &";
    $ret = system($cmd);
  }
  elsif ($failure_type eq "slave_kill") {
    $cmd = "./loop.memcached.bash $m_port $s_port slave KILL 10 10 1000000 &";
    $ret = system($cmd);
  }
  elsif ($failure_type eq "slave_stop") {
    $cmd = "./loop.memcached.bash $m_port $s_port slave INT 10 10 1000000 &";
    $ret = system($cmd);
  }
  elsif ($failure_type eq "switchover") {
    $cmd = "./loop.switchover.bash $m_port $s_port 10 10 1000000 &";
    $ret = system($cmd);
  }
  elsif ($failure_type eq "client") {
    $cmd = "./loop.client.bash $clientcase 5 5 1000000 &";
    $ret = system($cmd);
  }

  $cmd = "java -Xmx2g -Xms2g -Dnet.spy.log.LoggerImpl=net.spy.memcached.compat.log.Log4JLogger" .
         " -classpath $cls_path:. acp -config $configfile";
  printf "RUN COMMAND=%s\n", $cmd;

  local $SIG{TERM} = sub { print "TERM SIGNAL\n" };

  $ret = system($cmd);
  printf "EXIT CODE=%d\n", $ret;

  $cmd = "date";
  system($cmd);
  print "Please wait a second until failure or switchover script ends...\n";
  $cmd = "rm -f __can_test_failure__";
  system($cmd);
  sleep 5; # for stopping loop.*.bash

  # Run comparison tool
  if ($compare_flag) {
    sleep 40; # for stopping loop.*.bash

    $cmd = "./start_memcached.bash"; # to make sure that master & slave run
    $ret = system($cmd);
    sleep 5; # for starting memcached

    $cmd = "rm -f $dir_path/keydump*";
    print "$cmd\n";
    system($cmd);

    $cmd = "./dumpkey.bash localhost $m_port";
    print "$cmd\n";
    system($cmd);

    $cmd = "./dumpkey.bash localhost $s_port";
    print "$cmd\n";
    system($cmd);

    system($comp_cmd);
  }
}
}

if ($compare_flag == 0) {
  print "sleep 60\n";
  sleep 60; # for stopping loop.*.bash
}

$cmd = "pkill -INT memcached";
print "$cmd\n";
system($cmd);

$cmd = "./start_memcached.bash";
print "$cmd\n";
system($cmd);

print "sleep 5\n";
sleep 5;

print "END RUN_MC_TESTSCRIPTS\n";
print "To see errors.  Try grep -e \"RUN COMMAND\" -e \"DIFFRENT\" -e \"bad=\" -e \"not ok\"\n";
