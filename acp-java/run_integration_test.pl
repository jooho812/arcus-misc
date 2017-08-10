#!/usr/bin/perl -w
$t_ip = 0;   # test ip
$t_port = 0; # test port

sub print_usage {
      print "Usage) perl ./run_arcus_test.pl test_ip test_port\n";
}

if ($#ARGV eq 1) {
    $t_ip = $ARGV[0];
    $t_port = $ARGV[1];
    print "master_ip = $t_ip\n";
    print "master_port = $t_port\n";
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
$cls_path = "$jar_path/arcus-java-client-1.10.1-SNAPSHOT.jar" .
   ":$jar_path/zookeeper-3.4.5.jar:$jar_path/log4j-1.2.16.jar" .
   ":$jar_path/slf4j-api-1.6.1.jar:$jar_path/slf4j-log4j12-1.6.1.jar";

@script_list = (
#    "simple_getset" # performance test
#  , "integration_simplekv"
    "integration_simplekv"
);

foreach $script (@script_list) {
    if ($script eq "simple_getset") {
        $client = 20; #for performance
    } else {
        $client = 1;
    }
    # Create a temporary config file to run the test
    open CONF, ">tmp-config.txt" or die $!;
    print CONF
        #"zookeeper=127.0.0.1:2181\n" .
        #"service_code=test\n" .
        "single_server=" . $t_ip . ":" . $t_port . "\n" .
        "client=" . $client . "\n" .
        "rate=0\n" .
        "request=0\n" .
        "time=5\n" .
        "keyset_size=10000000\n" .
        "valueset_min_size=20\n" .
        "valueset_max_size=20\n" .
        "pool=1\n" .
        "pool_size=30\n" .
        "pool_use_random=false\n" .
        "key_prefix=tmptest:\n" .
        "client_exptime=120\n" .
        "client_profile=" . $script . "\n";
    close CONF;

    $cmd = "java -Xmx2g -Xms2g -ea -Dnet.spy.log.LoggerImpl=net.spy.memcached.compat.log.Log4JLogger" .
           " -classpath $cls_path:. acp -config tmp-config.txt";
    printf "RUN COMMAND=%s\n", $cmd;

    local $SIG{TERM} = sub { print "TERM SIGNAL\n" };

    $ret = system($cmd);

    if ($ret eq 0) {
        printf "EXIT CODE=%d\n", $ret;
    } else {
        last;
    }
}

if ($ret eq 0) {
    print "############################\n";
    print "TEST SUCCESS\n";
    print "############################\n";
    print "To see errors.  Try grep -e \"RUN COMMAND\" -e \"DIFFRENT\" -e \"bad=\" -e \"not ok\"\n";
} else {
    print "############################\n";
    print "exit with ERROR CODE : $ret\n";
    print "############################\n";
}
