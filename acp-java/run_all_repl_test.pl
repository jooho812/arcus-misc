#!/usr/bin/perl -w

$m_port = 0; # master port
$s_port = 0; # slave  port
$failure_type = "none"; # failure type
$compare_flag = 0;

sub print_usage {
  print "Usage) perl ./run_all_repl_test.pl master_port slave_port failure_type [compare]\n";
}

if ($#ARGV >= 1 && $#ARGV <= 3) {
  $m_port = $ARGV[0]; 
  $s_port = $ARGV[1]; 
  $failure_type = $ARGV[2]; 
  if ($#ARGV == 3) {
    if ($ARGV[3] eq 'compare') {
      $compare_flag = 1;
    } else {
      print_usage();
      die;
    }
  }  
  print "master_port = $m_port\n";
  print "slave_port  = $s_port\n";
  print "failure_type  = $failure_type\n";
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
$cls_path = "$jar_path/arcus-java-client-1.8.1.jar" .
    ":$jar_path/zookeeper-3.4.5.jar:$jar_path/log4j-1.2.16.jar" .
    ":$jar_path/slf4j-api-1.6.1.jar:$jar_path/slf4j-log4j12-1.6.1.jar";

$comp_dir = "$dir_path/../compare";
$comp_cmd = "java -classpath $cls_path:$comp_dir" .
            " compare -keydump $dir_path/keydump*" .
            " -server localhost:$m_port -server localhost:$s_port";
print "comp_cmd = $comp_cmd\n";

@script_list = (
    "standard_mix"
  , "simple_getset"
  , "simple_set"
  , "tiny_btree"
  , "torture_arcus_integration"
  , "torture_btree"
  , "torture_btree_bytebkey"
  , "torture_btree_bytemaxbkeyrange"
  , "torture_btree_decinc"
  , "torture_btree_exptime"
  , "torture_btree_ins_del"
  , "torture_btree_maxbkeyrange"
  , "torture_btree_replace"
  , "torture_cas"
  , "torture_list"
  , "torture_list_ins_del"
  , "torture_set"
  , "torture_set_ins_del"
  , "torture_simple_decinc"
  #, "torture_simple_sticky"
);

#$cmd = "rm -f __can_test_failure__";
#system($cmd);

foreach $script (@script_list) {
  # Flush all before each test
  $cmd = "./flushall.bash localhost $m_port";
  print "DO_FLUSH_ALL. $cmd\n";
  system($cmd);
  sleep 1;

  # Create a temporary config file to run the test
  open CONF, ">tmp-config.txt" or die $!;
  print CONF 
    "zookeeper=127.0.0.1:2181\n" .
    "service_code=test\n" .
    "client=30\n" .
    "rate=0\n" .
    "request=0\n" .
    "time=500\n" .
    "keyset_size=1000000\n" .
    "valueset_min_size=10\n" .
    "valueset_max_size=4000\n" .
    "pool=1\n" .
    "pool_size=30\n" .
    "pool_use_random=false\n" .
    "key_prefix=tmptest:\n" .
    "client_exptime=0\n" .
    "client_profile=" . $script . "\n";
  close CONF;

  $cmd = "touch __can_test_failure__";
  system($cmd);

  if (($failure_type eq "master_kill") || ($failure_type eq "all_kill")) {
    $cmd = "./loop.memcached.bash master $m_port KILL 40 20 5 &";
    $ret = system($cmd);
  }
  if (($failure_type eq "slave_kill") || ($failure_type eq "all_kill")) {
    $cmd = "./loop.memcached.bash slave $s_port KILL 10 20 5 &";
    $ret = system($cmd);
  }
  if (($failure_type eq "master_stop") || ($failure_type eq "all_stop")) {
    $cmd = "./loop.memcached.bash master $m_port INT 40 20 5 &";
    $ret = system($cmd);
  }
  if (($failure_type eq "slave_stop") || ($failure_type eq "all_stop")) {
    $cmd = "./loop.memcached.bash slave $s_port INT 10 20 5 &";
    $ret = system($cmd);
  }
  if ($failure_type eq "switchover") {
    $cmd = "./loop.switchover.bash $m_port $s_port 10 60 6 &";
    $ret = system($cmd);
  }

  $cmd = "java -Xmx2g -Xms2g -Dnet.spy.log.LoggerImpl=net.spy.memcached.compat.log.Log4JLogger" .
         " -classpath $cls_path:. acp -config tmp-config.txt";
  printf "RUN COMMAND=%s\n", $cmd;

  local $SIG{TERM} = sub { print "TERM SIGNAL\n" };

  $ret = system($cmd);
  printf "EXIT CODE=%d\n", $ret;

  $cmd = "rm -f __can_test_failure__";
  system($cmd);

  # Run comparison tool
  if ($compare_flag) {
    sleep 40;
    $cmd = "./start_memcached.bash";
    $ret = system($cmd);
    sleep 40;

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

print "END RUN_MC_TESTSCRIPTS\n";
print "To see errors.  Try grep -e \"RUN COMMAND\" -e \"DIFFRENT\" -e \"bad=\" -e \"not ok\"\n";
