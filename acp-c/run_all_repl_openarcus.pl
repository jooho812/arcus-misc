#!/usr/bin/perl -w

$m_port = 0; # master port
$s_port = 0; # slave  port

sub print_usage {
  print "Usage) perl ./run_all_repl_openarcus.pl master_port slave_port\n";
}

if ($#ARGV == 1) {
  $m_port = $ARGV[0];
  $s_port = $ARGV[1];
} else {
  print_usage();
  die;
}

$base_dir = "/home/usename/arcus-c-client";

@script_list = (
    "simple_getset",
    "simple_set",
    "standard_mix",
    "torture_btree_bytebkey",
    "torture_btree_bytemaxbkeyrange",
    "torture_btree",
    "torture_btree_decinc",
    "torture_btree_exptime",
    "torture_btree_ins_del",
    "torture_btree_maxbkeyrange",
    "torture_btree_replace",
    "torture_btree_piped_ins",
    "torture_btree_piped_ins_bulk",
    "torture_list",
    "torture_list_ins_del",
    "torture_list_piped_ins",
    "torture_set",
    "torture_set_ins_del",
    "torture_set_piped_ins",
    "torture_set_piped_exist",
    "torture_simple_cas",
    "torture_simple_decinc",
# Need to start memcached with -g
#    "torture_simple_sticky",
    "torture_simple_zero_exptime",
);

foreach $script (@script_list) {
    # Flush all before each test
    $cmd = "./flushall.bash localhost $m_port";
    print "DO_FLUSH_ALL. $cmd\n";
    system($cmd);
    sleep 1;

    # Flush all before each test
    $cmd = "./flushall.bash localhost $s_port";
    print "DO_FLUSH_ALL. $cmd\n";
    system($cmd);
    sleep 1;

    # Create a temporary config file to run the test
    open CONF, ">tmp-config.txt" or die $!;
    print CONF 
	"zookeeper=127.0.0.1:2181\n" .
	"service_code=test\n" .
	"client=20\n" .
	"rate=10\n" .
	"request=0\n" .
	"time=0\n" .
	"keyset_size=1000000\n" .
	"valueset_min_size=10\n" .
	"valueset_max_size=2000\n" .
	"pool=1\n" .
	"pool_size=1\n" .
	"key_prefix=tmptest:\n" .
	"client_profile=" . $script . "\n";
    close CONF;

    $cmd = "LD_LIBRARY_PATH=$base_dir/lib ./acp -poll-timeout 2000 -config tmp-config.txt";
    printf "TEST=$script RUN COMMAND=%s\n", $cmd;

    local $SIG{TERM} = sub { print "TERM SIGNAL\n" };

    $ret = system($cmd);
    printf "EXIT CODE=%d\n", $ret;
}

print "END RUN_MC_TESTSCRIPTS\n";
#print "To see errors.  Try grep -e \"RUN COMMAND\" -e \"bad=\" -e \"not ok\"\n";
