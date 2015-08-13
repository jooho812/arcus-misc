#!/usr/bin/perl -w

use strict;
use warnings;

# Hash and Array
my %config_list = ();   # Hash   : config_file 
my @config_order = ();  # Array  : only key
my @arr_temp = ();      # Array  : temporary key, value

my $is_first = 1;
my $filename;

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

sub file_read_default_config {
	my $default = $ARGV[0];

	# FIXME Is argv file exists ? : exception
	# Read $default configure File.
	open (FPD, "< $default") || die "cannot open file :  $default"; 
	while (my $line = <FPD>) {
		# remove '\n' by chomp function.
		chomp($line);

		# Ignore comment.
		if (substr($line, 0, 1) eq "#") {
			next;
		}


		@arr_temp = split('=', $line);
		
		# Add to Hash %config_list
		$config_list{$arr_temp[0]} = "$arr_temp[1]";

		# Add to Array @config_order 
		push @config_order, $arr_temp[0];
	}
	close FPD;
}

sub reset_default_config {
	%config_list = ();
	@config_order = ();
}

sub file_read {

	my $test_description = $ARGV[1];

	# second file.
	# Read Test-Description File.
	my $new_filename = "";
	my $bool = 0;
	open (FP, "< $test_description") || die "cannot open file :  $test_description"; 
	while (my $line = <FP>) {
		chomp($line);

		# Ignore comment.
		if (substr($line, 0, 1) eq "#") {
			next;
		}

		if ($line eq "") {
			next;
		}

		# rex : \[.*\]
		# Check startswith '[' and endswith ']'
		if ($line =~ m/\[.*\]/) {

			$filename = $new_filename;
			$new_filename = substr $line, 1, -1;

			if ($is_first == 1) {
				$is_first = 0;
			} elsif ($is_first == 0) {
				# Call file_write()
				file_write($filename);
			}

			# Read default_setting_file.
			reset_default_config();
			file_read_default_config();

		}
		else {
			@arr_temp = split('=', $line);

			# Check element. Does element exists in @config_order?
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
				print "called..\n";
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
	print FFP "########################################\n";
	print FFP "# default_config_file + $new_filename\n";
	print FFP "########################################\n\n";

	for my $key (@config_order) {
		print FFP "$key=$config_list{$key}\n\n";
	}

	close FFP;

	print "$new_filename(default_config_file + $new_filename) generated...\n"
}


########################################
# MAIN
########################################
check_param ($ARGV);
file_read ($ARGV);
