#!/usr/bin/perl -w

use strict;

my $k_port = 0; # memcached kill port
my $k_intv = 0; # kill interval

sub print_usage {
  print "Usage) perl ./integration/kill.memcached.perl <kill_port> <kill_interval>\n";
}

if ($#ARGV == 1) {
  $k_port = $ARGV[0];
  $k_intv = $ARGV[1];
} else {
  print_usage();
  die;
}

sleep $k_intv;

my $cmd = "kill -9 \$(ps -ef | awk '/-e replication_config_file=replication.config; -p $k_port/ {print \$2}')";
printf "RUN COMMAND = $cmd\n";
system($cmd);

