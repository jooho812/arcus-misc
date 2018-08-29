#!/usr/bin/perl -w

#use Benchmark;

my $cmd;
my $Afile;
my $Bfile;

my @Aresult;
my @Bresult;
my $line;

my $resultfile;
#my $t0 = new Benchmark;
#my $t1;
#my $td;

if ($#ARGV ne 2) {
  $cmd = "Usage) ./integration/compare.bash <compAfile(set)> <compBfile(get)> <resultfile>";
  exit 1;
} else {
  $Afile = $ARGV[0];
  $Bfile = $ARGV[1];
  $resultfile = $ARGV[2];
}

sub write_result_file {
  my $txt = shift;
  open RESULT, "> $resultfile" or die $!;
  print RESULT $txt . "\n";
  close RESULT;
  sleep 1;
}

#########################
# main
#########################

# A file read
open FA, $Afile;
while(<FA>) {
  $line = $_;
  chomp($line);
  push @Aresult, $line;
}
close FA;

# B file read
open FB, $Bfile;
while(<FB>) {
  $line = $_;
  chomp($line);
  push @Bresult, $line;
}
close FB;

#$t1 = new Benchmark;
#$td = timediff($t1, $t0);
######################################


# write result file
my @union = @intersection = @difference = ();
my %count = ();
my $element;
foreach $element (@Aresult, @Bresult) { $count{$element}++ }
foreach $element (keys %count) {
    push @union, $element;
    push @{ $count{$element} > 1 ? \@intersection : \@difference }, $element;
}

if ($#Aresult - $#intersection > 0) {
  print "Bfile key(get operation) must contain an unconditional Afile key(set operation)!\n";
  print "set operation file : $Afile\nget operation file : $Bfile\n";
  die;
}


if ($#difference >= 0) {
  my $difftxt = "";
  my $count = 0;
  foreach $element (@difference) {
    $difftxt .= "$element";
    if ($#difference != $count++) {
      $difftxt .= "\n";
    }
  }
  write_result_file($difftxt);
}
