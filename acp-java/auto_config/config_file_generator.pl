#!/usr/bin/perl -w

use strict;
use warnings;

# Hash and Array
my %config_list = ();   # Hash   : config_file 
my @config_order = ();  # Array  : only key
my @arr_temp = ();      # Array  : temporary key, value

########################################
# Sub routines ...
########################################
sub print_usage {
	print "Usage) perl ./config_file_generator.pl [default_setting_file] [test_description_file]\n";
}

sub check_param  {

	if ($#ARGV == 1) {

	} else {
		print_usage();
		exit 1;
	}
}

sub file_read {
	my $default = $ARGV[0];
	my $test_description = $ARGV[1];

	# FIXME Is argv file exists ? : exception
	# Read $default configure File.
	open (FP, "< $default") || die "cannot open file :  $default"; 
	while (my $line = <FP>) {
		# remove '\n' by chomp function.
		chomp($line);

		@arr_temp = split('=', $line);
		
		# add to %config_list
		$config_list{$arr_temp[0]} = "$arr_temp[1]";


		push @config_order, $arr_temp[0];
		#print "===================================\n";
		#print "test1 : " . $arr_temp[0] . "\n";
		#print "test2 : " . $arr_temp[1] . "\n";
	}
	close FP;

	# second file.
	# Read Test-Description File.
	my $new_filename = "";
	my $bool = 0;
	open (FP, "< $test_description") || die "cannot open file :  $test_description"; 
	while (my $line = <FP>) {

		chomp($line);

		if ($line eq "") {
			# Call file_write()
			file_write($new_filename);
			next;
		}


		# rex : \[.*\]
		# Check startswith '[' and endswith ']'
		if ($line =~ m/\[.*\]/) {
			$new_filename = substr $line, 1, -1;
		}
		else {
			@arr_temp = split('=', $line);

			# Check 
			$bool = 0;
			for my $element (@config_order) {
				if ($element eq $arr_temp[0]) {
					$bool = 1;
					last;
				} 
			}

			if ($bool == 1) {

			}
			else {
				push @config_order, $arr_temp[0];
			}
			$config_list{$arr_temp[0]} = "$arr_temp[1]";
		}
	}
	# Call file_write()
	file_write($new_filename);
	close FP;
}

sub file_write {
	# Assign parameter to local variable($new_filename)
	my $new_filename = shift @_;

	open(FFP, ">", $new_filename) || die "Couldn't open '".$new_filename."' for writing because: ".$!;

	for my $key (@config_order) {
		print FFP "$key" . "=" . "$config_list{$key}\n\n";
	}

	close FFP;

	print "$new_filename generated...\n"
}


########################################
# MAIN
########################################
check_param ($ARGV);
file_read ($ARGV);
