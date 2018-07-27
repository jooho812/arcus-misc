#!/usr/bin/perl -w

use strict;

# use port 11301 ~ 11314, 21221 ~ 21234
my $run_time = 600;
my $keyset_size = 10000000;
my $cluster_number; #   0 : Configure cluster with four nodes.
                    # > 0 : Configure cluster with three nodes.
sub print_usage {
    print "Usage) perl ./integration/run_integration_idc.pl <cluster_number(0(4node) or 1(3node))>\n";
}

if ($#ARGV == 0) {
    $cluster_number = $ARGV[0];
    print "runtime = $run_time\n";
    print "keyset_size = $keyset_size\n";
    print "cluster_number = $cluster_number\n";
} else {
    print_usage();
    die;
}

use Cwd 'abs_path';
use File::Basename;

my $filename = abs_path($0);
my $dir_path = dirname($filename);
my $cmd;

print "filename = $filename\n";
print "dir_path = $dir_path\n";

my $jar_path = "$dir_path/../../../arcus-java-client/target";
my $cls_path = "$jar_path/arcus-java-client-1.11.0.jar" .
    ":$jar_path/zookeeper-3.4.5.jar:$jar_path/log4j-1.2.16.jar" .
    ":$jar_path/slf4j-api-1.6.1.jar:$jar_path/slf4j-log4j12-1.6.1.jar";

###########################################
########### 1. start cluster  #############
###########################################
if ($cluster_number) { # 3 nodes
    $cmd = "./integration/run.memcached.bash 11301;"
         . "./integration/run.memcached.bash 11302;"
         . "./integration/run.memcached.bash 11303;"
         . "./integration/run.memcached.bash 11304;"
         . "./integration/run.memcached.bash 11305;"
         . "./integration/run.memcached.bash 11306";
    system($cmd);
    $cmd = "echo \"cluster join alone\" | nc localhost 11301";
    system($cmd); sleep(3);
    $cmd = "echo \"cluster join begin\" | nc localhost 11303";
    system($cmd); sleep(3);
    $cmd = "echo \"cluster join end\" | nc localhost 11305";
    system($cmd); sleep(1);
} else { # 4 nodes
    $cmd = "./integration/run.memcached.bash 11307;"
         . "./integration/run.memcached.bash 11308;"
         . "./integration/run.memcached.bash 11309;"
         . "./integration/run.memcached.bash 11310;"
         . "./integration/run.memcached.bash 11311;"
         . "./integration/run.memcached.bash 11312;"
         . "./integration/run.memcached.bash 11313;"
         . "./integration/run.memcached.bash 11314";
    system($cmd);
    $cmd = "echo \"cluster join alone\" | nc localhost 11307";
    system($cmd); sleep(3);
    $cmd = "echo \"cluster join begin\" | nc localhost 11309";
    system($cmd); sleep(3);
    $cmd = "echo \"cluster join\" | nc localhost 11311";
    system($cmd); sleep(1);
    $cmd = "echo \"cluster join end\" | nc localhost 11313";
    system($cmd); sleep(1);
}

print "#########################\n";
print "START IDC CLUSTER $cluster_number\n";
print "#########################\n";
