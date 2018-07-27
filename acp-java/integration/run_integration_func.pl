#!/usr/bin/perl -w
$t_ip = 0;   # test ip
$t_port = 0; # test port
sub print_usage {
      print "Usage) perl ./integration/run_integration_func.pl <test_ip> <test_port>\n";
}

if ($#ARGV eq 1) {
    $t_ip = $ARGV[0];
    $t_port = $ARGV[1];
    print "test_ip = $t_ip\n";
    print "test_port = $t_port\n";
} else {
    print_usage();
    die;
}

use Cwd 'abs_path';
use File::Basename;

@script_list = (
    "integration_simplekv"
  , "integration_list"
  , "integration_set"
  , "integration_map"
  , "integration_btree"
);

foreach $script (@script_list) {
    # Create a temporary config file to run the test
    open CONF, ">tmp-integration-config.txt" or die $!;
    print CONF
        #"zookeeper=127.0.0.1:9181\n" .
        #"service_code=test\n" .
        "single_server=" . $t_ip . ":" . $t_port . "\n" .
        "client=1\n" .
        "rate=0\n" .
        "request=0\n" .
        "time=5\n" .
        "keyset_size=5000000\n" .
        "valueset_min_size=20\n" .
        "valueset_max_size=20\n" .
        "pool=1\n" .
        "pool_size=20\n" .
        "pool_use_random=false\n" .
        "key_prefix=integrationtest:\n" .
        "client_exptime=120\n" .
        "client_profile=" . $script . "\n";
    close CONF;

    $cmd = "./run.bash -config tmp-integration-config.txt";
    printf "RUN COMMAND=%s\n", $cmd;

    local $SIG{TERM} = sub { print "TERM SIGNAL\n" };

    $ret = system($cmd);

    if ($ret ne 0) {
        printf "TEST FAILED CODE=%d\n", $ret;
        printf "script name=$script\n";
        last;
    }
}

if ($ret eq 0) {
    print "############################\n";
    print "TEST SUCCESS\n";
    print "############################\n";
} else {
    print "############################\n";
    print "exit with ERROR CODE : $ret\n";
    print "############################\n";
}
