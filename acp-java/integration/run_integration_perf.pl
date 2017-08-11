#!/usr/bin/perl -w
$t_ip = 0;   # test ip
$t_port = 0; # test port
$est_perf = 0; # estimated performance
sub print_usage {
      print "Usage) perl ./integration/run_integration_perf.pl test_ip test_port performance\n";
}

if ($#ARGV eq 2) {
    $t_ip = $ARGV[0];
    $t_port = $ARGV[1];
    $est_perf = $ARGV[2];
    print "master_ip = $t_ip\n";
    print "master_port = $t_port\n";
    print "estimated_performance = $est_perf\n";
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

$jar_path = "$dir_path/../../../arcus-java-client/target";
$cls_path = "$jar_path/arcus-java-client-1.11.0.jar" .
   ":$jar_path/zookeeper-3.4.5.jar:$jar_path/log4j-1.2.16.jar" .
   ":$jar_path/slf4j-api-1.6.1.jar:$jar_path/slf4j-log4j12-1.6.1.jar";

@script_list = (
    "integration_onlyset"      # only set operation
  , "integration_getset_ratio" # get/set ratio 4:1 performance test
);

foreach $script (@script_list) {
    $result_filename = "tmp-integration_perf_summary.txt"; #generate result file
    # Create a temporary config file to run the test
    open CONF, ">tmp-integration-config.txt" or die $!;
    print CONF
        #"zookeeper=127.0.0.1:9181\n" .
        #"service_code=test\n" .
        "single_server=" . $t_ip . ":" . $t_port . "\n" .
        "client=30\n" .
        "rate=0\n" .
        "request=0\n" .
        "time=600\n" .
        "keyset_size=10000000\n" .
        "valueset_min_size=8\n" .
        "valueset_max_size=32\n" .
        "pool=1\n" .
        "pool_size=20\n" .
        "pool_use_random=false\n" .
        "key_prefix=integrationtest:\n" .
        "generate_resultfile=" . $result_filename . "\n" .
        "client_exptime=0\n" .
        "client_profile=" . $script . "\n";
    close CONF;

    $cmd = "java -Xmx2g -Xms2g -ea -Dnet.spy.log.LoggerImpl=net.spy.memcached.compat.log.Log4JLogger" .
           " -classpath $cls_path:. acp -config tmp-integration-config.txt";
    printf "RUN COMMAND=%s\n", $cmd;

    local $SIG{TERM} = sub { print "TERM SIGNAL\n" };

    $ret = system($cmd);

    if ($ret eq 0) {
        print "performance check...\n";
        $success = 0;
        open (TEXT, $result_filename);
        while(<TEXT>) {
            $line = $_;
            @result = split/=/,$line;
            if ($result[0] eq "requests/s"){
                $real_perf = $result[1];
                if ($result[1] >= $est_perf) {
                    $success = 1;
                }
            }
        }
    } else {
        last;
    }
}
;
if ($ret eq 0) {
    print "RESULT >>> estimated perf : $est_perf, real perf : $real_perf\n";
    if ($success eq 1) {
        print "############################\n";
        print "SUCCESS PERFORMANCE TEST\n";
        print "############################\n";
    } else {
        print "############################\n";
        print "FAILED PERFORMANCE TESTn";
        print "############################\n";
    }
} else {
    print "############################\n";
    print "exit with ERROR CODE : $ret\n";
    print "############################\n";
}
