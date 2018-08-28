#!/usr/bin/perl -w
use Benchmark;

my $cmd;
my $Afile;
my $Bfile;

my $Aresult;
my $Bresult;
my $line;

my $t0 = new Benchmark;
my $t1;
my $td;

if ($#ARGV ne 1) {
  $cmd = "Usage) ./integration/compare.bash <compAfile> <compBfile>";
} else {
  $Afile = $ARGV[0];
  $Bfile = $ARGV[1];
}

sub printHlight {
    my ($str, $color) = @_;
    system("echo -e \'\033[$color\m$str\033[0m\'");
}

sub readSortFile {
  my $fname = shift;
  my @it_array;
  my $result;
  print "$fname read & sort...\n";
  open F, $fname;
  while(<F>) {
    $line = $_;
    chomp($line);
    push @it_array, $line;
  }
  return join(",",sort(@it_array));
}


#########################
# main
#########################

# read & sort file
$Aresult = readSortFile($Afile);
$Bresult = readSortFile($Bfile);

$t1 = new Benchmark;
$td = timediff($t1, $t0);
printHlight "elapsed time : " . timestr($td), 33;


# result
if ($Aresult eq $Bresult) {
    printHlight "$Afile $Bfile equall", 32;
} else {
    printHlight "$Afile $Bfile not equall", 31;
    exit 1;
}
