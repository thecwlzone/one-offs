package TheTests;
use WriteTestFile;
use ReadTestFile;
use FSTCommon;
use Time::Local;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

use Exporter;
$VERSION = 0.24;
@ISA = qw(Exporter);

@EXPORT		= qw(&FSTest1 &FSTest2 &FSTest3 &FSTest4 &FSTest5 &FSTest6 &FSTest7 &FSTest8 &FSTest9 &FSTest10 &FSTest11 &FSTest12);
#@EXPORT_OK	= qw(...);

#
# This code violates the DRY principle - Don't Repeat Yourself
# Each test is standalone. Refactoring may make sense later on - or not.
#

# Change Log
#
# 0.20 - Added a --maxsize switch to globally limit the maximum file size to be used in any test.
#        If maxsize < filesize then filesize = maxsize
#        In Test 1, file sizes will be calculated based upon maxsize
#
# 0.21 - Removed 0755 directive in the mkdir commands to make GSA happy
#
# 0.22 - Added --fixname option. Test for it, and adjust the directory name if necessary
#
# 0.23 - Added FSTest12
#
# 0.24 - Added general support for the --datadir option
#        For each test:
#          If --datadir is not specified, do the "normal" test mode
#          If --datadir is specified but the directory does not exist, create the datadir,
#          create the test directory, create the files, and do a read test.
#          If --datadir is specified and exists, but a test directory does not exist,
#          create the test directory, create the files and do a read test.
#          If --datadir is specified and exists, and the test directory exists, just do the read test.
#
#        At any time, if a disk overflow is detected during a write operation, the program exits.
###
sub FSTest1 {
	# Test 1 - Large File Write/Read
	# Persistent mode requires 7.2G of disk space when --maxsize is set to 2.0G
	my $test_dir = "";
	my $unique_file_name = "";
	my $start_time = timelocal(localtime);
	my $user_number = $_[0];
	my $msg_name = "FSTest1-user" . $user_number . ": ";
	if ($main::fixname ne "") {
		$unique_file_name = "-user". $user_number . "-" . $main::fixname;
	}
	else {
		my $datestamp = get_datestamp();
		$unique_file_name = "-user" . $user_number . "-" . $datestamp;	
	}
	my @file_sizes = ("1.1G", "2.2G", "4.4G", "8.8G");

	# Recalculate if --maxsize was specified
	# This is incredibly clumsy
	if ($main::maxsize ne "") {
		$file_sizes[3] = $main::maxsize;
		
		my $num_val = $main::maxsize;
		chop $num_val;
		my $suffix = substr($main::maxsize, length($main::maxsize)-1, 1);
		$num_val = $num_val / 2;
		$file_sizes[2] = $num_val . $suffix;
		
		$num_val = $main::maxsize;
		chop $num_val;
		$suffix = substr($main::maxsize, length($main::maxsize)-1, 1);
		$num_val = $num_val / 4;
		$file_sizes[1] = $num_val . $suffix;
		
		$num_val = $main::maxsize;
		chop $num_val;
		$suffix = substr($main::maxsize, length($main::maxsize)-1, 1);
		$num_val = $num_val / 8;
		$file_sizes[0] = $num_val . $suffix;	
	}	

	print "Running FSTest1 for user number $user_number\n" if $main::verbose || $main::terse;
	write_to_logfile($msg_name . "Running FSTest1 for user number $user_number\n");
		
	# Normal mode
	if ($main::datadir eq "") {
		$test_dir = $main::outdir . "/FSTest1" . $unique_file_name;
		mkdir($test_dir) || die "Could not create directory: $!";
		# Write, read and delete each file
		foreach my $test_file_size (@file_sizes) {
			exit if ! write_test_file("FSTest1bin" . "-" . $test_file_size, $test_dir, "binary", $test_file_size);
			read_test_file("FSTest1bin" . "-" . $test_file_size, $test_dir);
			unlink($test_dir . "/FSTest1bin" . "-" . $test_file_size) or die "Could not remove file: $!\n" unless $main::noclean || $main::dryrun;
			exit if ! write_test_file("FSTest1ascii" . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
			read_test_file("FSTest1ascii" . "-" . $test_file_size, $test_dir);
			unlink($test_dir . "/FSTest1ascii" . "-". $test_file_size) or die "Could not remove file: $!\n" unless $main::noclean || $main::dryrun;
		}
		print "FSTest1 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest1 for user number $user_number completed\n\n");
		return(1);
	}

	# Persistent operation, create data dir, create test dir, create files, read files
	if ($main::datadir ne "" && ! -d $main::datadir) {
		mkdir($main::datadir) || die "Could not create directory: $!";
		$test_dir = $main::datadir . "/FSTest1" . $unique_file_name;
		mkdir($test_dir) || die "Could not create directory: $!";

		# Write the files		
		foreach my $test_file_size (@file_sizes) {
			exit if ! write_test_file("FSTest1bin" . "-" . $test_file_size, $test_dir, "binary", $test_file_size);
			exit if ! write_test_file("FSTest1ascii" . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
		}
		# Read the files
		# Reset the time to track the read times
		$start_time = timelocal(localtime);
		foreach my $test_file_size (@file_sizes) {
			read_test_file("FSTest1bin" . "-" . $test_file_size, $test_dir);
			read_test_file("FSTest1ascii" . "-" . $test_file_size, $test_dir);
		}
		print "FSTest1 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest1 for user number $user_number completed\n\n");
		return(1);
	}

	# Persistent operation, data dir exists
	if ($main::datadir ne "" && -d $main::datadir) { $test_dir = $main::datadir . "/FSTest1" . $unique_file_name; }
	if (! -d $test_dir) {
		# Test dir does not exist, create dir and files, read files
		mkdir($test_dir) || die "Could not create directory: $!";
		
		foreach my $test_file_size (@file_sizes) {
			exit if ! write_test_file("FSTest1bin" . "-" . $test_file_size, $test_dir, "binary", $test_file_size);
			exit if ! write_test_file("FSTest1ascii" . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
		}
		# Read the files
		# Reset the time to track the read times
		$start_time = timelocal(localtime);
		foreach my $test_file_size (@file_sizes) {
			read_test_file("FSTest1bin" . "-" . $test_file_size, $test_dir);
			read_test_file("FSTest1ascii" . "-" . $test_file_size, $test_dir);
		}
		print "FSTest1 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest1 for user number $user_number completed\n\n");	
		return(1);
	}
	else {
		# Test dir exists, read files
		# Reset the time to track the read times
		$start_time = timelocal(localtime);
		foreach my $test_file_size (@file_sizes) {
			read_test_file("FSTest1bin" . "-" . $test_file_size, $test_dir);
			read_test_file("FSTest1ascii" . "-" . $test_file_size, $test_dir);
		}
		print "FSTest1 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest1 for user number $user_number completed\n\n");
		return(1);
	}
}

sub FSTest2 {
	# Test 2 - Small File Write/Read
	# Persistent mode requires 361M of disk space
	my $test_dir = "";
	my $unique_file_name = "";
	my $start_time = timelocal(localtime);
	my $user_number = $_[0];
	my $msg_name = "FSTest2-user" . $user_number . ": ";
	if ($main::fixname ne "") {
		$unique_file_name = "-user". $user_number . "-" . $main::fixname;
		$test_dir = $main::outdir . "/FSTest2" . $unique_file_name;
	}
	else {
		my $datestamp = get_datestamp();
		$unique_file_name = "-user" . $user_number . "-" . $datestamp;
		$test_dir = $main::outdir . "/FSTest2" . $unique_file_name;
	}
	my @file_sizes = ("1K", "2K", "5K", "10K", "20K", "50K", "100K", "200K", "500K", "1M", "2M", "5M", "10M", "20M", "50M","100M");

	print "Running FSTest2 for user number $user_number\n" if $main::verbose || $main::terse;
	write_to_logfile($msg_name . "Running FSTest2 for user number $user_number\n");
		
	# Normal mode
	if ($main::datadir eq "") {	
		mkdir($test_dir) || die "Could not create directory: $!";

		# Write, read and delete each file
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			exit if ! write_test_file("FSTest2bin" . "-" . $test_file_size, $test_dir, "binary", $test_file_size);
			read_test_file("FSTest2bin" . "-" . $test_file_size, $test_dir);
			unlink($test_dir . "/FSTest2bin" . "-". $test_file_size) or die "Could not remove file: $!\n" unless $main::noclean || $main::dryrun;
			exit if ! write_test_file("FSTest2ascii" . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
			read_test_file("FSTest2ascii" . "-" . $test_file_size, $test_dir);
			unlink($test_dir . "/FSTest2ascii" . "-". $test_file_size) or die "Could not remove file: $!\n" unless $main::noclean  || $main::dryrun;
		}
		
		print "FSTest2 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest2 for user number $user_number completed\n\n");
		return(1);
	}
	
	# Persistent operation, create data dir, create test dir, create files, read files
	if ($main::datadir ne "" && ! -d $main::datadir) {
		mkdir($main::datadir) || die "Could not create directory: $!";
		$test_dir = $main::datadir . "/FSTest2" . $unique_file_name;
		mkdir($test_dir) || die "Could not create directory: $!";

		# Write the files
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			exit if ! write_test_file("FSTest2bin" . "-" . $test_file_size, $test_dir, "binary", $test_file_size);
			exit if ! write_test_file("FSTest2ascii" . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
		}
		# Read the files
		# Reset the time to track the read times
		$start_time = timelocal(localtime);
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			read_test_file("FSTest2bin" . "-" . $test_file_size, $test_dir);
			read_test_file("FSTest2ascii" . "-" . $test_file_size, $test_dir);
		}
			
		print "FSTest2 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest2 for user number $user_number completed\n\n");
		return(1);
	}
	
	# Persistent operation, data dir exists
	if ($main::datadir ne "" && -d $main::datadir) { $test_dir = $main::datadir . "/FSTest2" . $unique_file_name; }
	if (! -d $test_dir) {
		# Test dir does not exist, create dir and files, read files
		mkdir($test_dir) || die "Could not create directory: $!";
		# Write the files
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			exit if ! write_test_file("FSTest2bin" . "-" . $test_file_size, $test_dir, "binary", $test_file_size);
			exit if ! write_test_file("FSTest2ascii" . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
		}
		# Read the files
		# Reset the time to track the read times
		$start_time = timelocal(localtime);
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			read_test_file("FSTest2bin" . "-" . $test_file_size, $test_dir);
			read_test_file("FSTest2ascii" . "-" . $test_file_size, $test_dir);
		}
			
		print "FSTest2 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest2 for user number $user_number completed\n\n");
		return(1);
	}
	else {
		# Test dir exists, read files
		# Reset the time to track the read times
		$start_time = timelocal(localtime);
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			read_test_file("FSTest2bin" . "-" . $test_file_size, $test_dir);
			read_test_file("FSTest2ascii" . "-" . $test_file_size, $test_dir);
		}
			
		print "FSTest2 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest2 for user number $user_number completed\n\n");
		return(1);
	}
}

sub FSTest3 {
	# Test 3 - Multiple Large File Read
	# Persistent mode requires 500M of disk space
	my $test_dir = "";
	my $unique_file_name = "";
	my $start_time = timelocal(localtime);
	my $user_number = $_[0];
	my $msg_name = "FSTest3-user" . $user_number . ": ";
	if ($main::fixname ne "") {
		$unique_file_name = "-user". $user_number . "-" . $main::fixname;
		$test_dir = $main::outdir . "/FSTest3" . $unique_file_name;
	}
	else {
		my $datestamp = get_datestamp();
		$unique_file_name = "-user" . $user_number . "-" . $datestamp;
		$test_dir = $main::outdir . "/FSTest3" . $unique_file_name;
	}
	my $test_file_size = "500M";

	print "Running FSTest3 for user number $user_number\n" if $main::verbose || $main::terse;
	write_to_logfile($msg_name . "Running FSTest3 for user number $user_number\n");
		
	# Normal mode
	if ($main::datadir eq "") {		
		mkdir($test_dir) || die "Could not create directory: $!";

		if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };	
		exit if ! write_test_file("FSTest3" . "-" . $test_file_size, $test_dir, "binary", $test_file_size);
		for (1..10) {
			read_test_file("FSTest3" . "-" . $test_file_size, $test_dir);
		}
		unlink($test_dir . "/FSTest3" . "-". $test_file_size) or die "Could not remove file: $!\n" unless $main::noclean  || $main::dryrun;
		
		print "FSTest3 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest3 for user number $user_number completed\n\n");
		return(1);
	}

	# Persistent operation, create data dir, create test dir, create files, read files
	if ($main::datadir ne "" && ! -d $main::datadir) {
		mkdir($main::datadir) || die "Could not create directory: $!";
		$test_dir = $main::datadir . "/FSTest3" . $unique_file_name;
		mkdir($test_dir) || die "Could not create directory: $!";

		if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };	
		exit if ! write_test_file("FSTest3" . "-" . $test_file_size, $test_dir, "binary", $test_file_size);
		# Read the files
		# Reset the time to track the read times
		$start_time = timelocal(localtime);
		for (1..10) {
			read_test_file("FSTest3" . "-" . $test_file_size, $test_dir);
		}
		
		print "FSTest3 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest3 for user number $user_number completed\n\n");
		return(1);
	}
	
	# Persistent operation, data dir exists
	if ($main::datadir ne "" && -d $main::datadir) { $test_dir = $main::datadir . "/FSTest3" . $unique_file_name; }
	if (! -d $test_dir) {
		# Test dir does not exist, create dir and files, read files
		mkdir($test_dir) || die "Could not create directory: $!";
		# Write the files
		if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };	
		exit if ! write_test_file("FSTest3" . "-" . $test_file_size, $test_dir, "binary", $test_file_size);
		# Read the files
		# Reset the time to track the read times
		$start_time = timelocal(localtime);
		for (1..10) {
			read_test_file("FSTest3" . "-" . $test_file_size, $test_dir);
		}
		
		print "FSTest3 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest3 for user number $user_number completed\n\n");
		return(1);
	}
	else {
		# Test dir exists, read files
		# Reset the time to track the read times
		$start_time = timelocal(localtime);
		for (1..10) {
			read_test_file("FSTest3" . "-" . $test_file_size, $test_dir);
		}
		
		print "FSTest3 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest3 for user number $user_number completed\n\n");
		return(1);
	}
}

sub FSTest4 {
	# Test 4 - Multiple Small File Write
	# Simulate multiple writes of simulation, netlist and various other text files
	# Persistent mode requires 19M of disk space
	my $test_dir = "";
	my $unique_file_name = "";
	my $start_time = timelocal(localtime);
	my $user_number = $_[0];
	my $msg_name = "FSTest4-user" . $user_number . ": ";
	if ($main::fixname ne "") {
		$unique_file_name = "-user". $user_number . "-" . $main::fixname;
		$test_dir = $main::outdir . "/FSTest4" . $unique_file_name;
	}
	else {
		my $datestamp = get_datestamp();
		$unique_file_name = "-user" . $user_number . "-" . $datestamp;
		$test_dir = $main::outdir . "/FSTest4" . $unique_file_name;
	}
	my @file_sizes = ("1K", "10K", "23K", "150K", "435K", "2K", "20K", "46K", "300K", "870K");

	print "Running FSTest4 for user number $user_number\n" if $main::verbose || $main::terse;
	write_to_logfile($msg_name . "Running FSTest4 for user number $user_number\n");
		
	# Normal mode
	if ($main::datadir eq "") {	
		mkdir($test_dir) || die "Could not create directory: $!";
	
		# Write 100 hundred files
		for (my $i = 1; $i <= 10; $i++) {
			foreach my $test_file_size (@file_sizes) {
				if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
				exit if ! write_test_file("FSTest4ascii" . "-" . $i . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
				unlink($test_dir . "/FSTest4ascii" . "-" . $i . "-" . $test_file_size) or die "Could not remove file: $!\n" unless $main::noclean  || $main::dryrun;
			}
		}
	
		print "FSTest4 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest4 for user number $user_number completed\n\n");
		return(1);
	}
	
	# Persistent operation, create data dir, create test dir, create files
	if ($main::datadir ne "" && ! -d $main::datadir) {
		mkdir($main::datadir) || die "Could not create directory: $!";
		$test_dir = $main::datadir . "/FSTest4" . $unique_file_name;
		mkdir($test_dir) || die "Could not create directory: $!";
		
		# Write 100 hundred files
		for (my $i = 1; $i <= 10; $i++) {
			foreach my $test_file_size (@file_sizes) {
				if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
				exit if ! write_test_file("FSTest4ascii" . "-" . $i . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
			}
		}
	
		print "FSTest4 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest4 for user number $user_number completed\n\n");
		return(1);		
	}
	
	# Persistent operation, data dir exists
	if ($main::datadir ne "" && -d $main::datadir) { $test_dir = $main::datadir . "/FSTest4" . $unique_file_name; }
	if (! -d $test_dir) {
		# Test dir does not exist, create dir and files
		mkdir($test_dir) || die "Could not create directory: $!";
		
		# Write 100 hundred files
		for (my $i = 1; $i <= 10; $i++) {
			foreach my $test_file_size (@file_sizes) {
				if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
				exit if ! write_test_file("FSTest4ascii" . "-" . $i . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
			}
		}
	
		print "FSTest4 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest4 for user number $user_number completed\n\n");
		return(1);
	}
	else {
		# Test dir exists. As this is a write-only test, there is nothing to do here
		print "FSTest4 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest4 for user number $user_number completed\n\n");	
		return(1);	
	}
}

sub FSTest5 {
	# Test 5 - Multiple Small File Read
	# Simulate multiple reads of simulation, netlist and various other text files
	# Persistent mode requires 1.9M of disk space
	my $test_dir = "";
	my $unique_file_name = "";
	my $start_time = timelocal(localtime);	
	my $user_number = $_[0];
	my $msg_name = "FSTest5-user" . $user_number . ": ";
	if ($main::fixname ne "") {
		$unique_file_name = "-user". $user_number . "-" . $main::fixname;
		$test_dir = $main::outdir . "/FSTest5" . $unique_file_name;
	}
	else {
		my $datestamp = get_datestamp();
		$unique_file_name = "-user" . $user_number . "-" . $datestamp;
		$test_dir = $main::outdir . "/FSTest5" . $unique_file_name;
	}
	my @file_sizes = ("1K", "10K", "23K", "150K", "435K", "2K", "20K", "46K", "300K", "870K");

	print "Running FSTest5 for user number $user_number\n" if $main::verbose || $main::terse;
	write_to_logfile($msg_name . "Running FSTest5 for user number $user_number\n");
		
	# Normal mode
	if ($main::datadir eq "") {		
		mkdir($test_dir) || die "Could not create directory: $!";

		# Write the files	
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			exit if ! write_test_file("FSTest5ascii" . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
		}
	
		# Read 100 files
		for (1..10) {
			foreach my $test_file_size (@file_sizes) {
				read_test_file("FSTest5ascii" . "-" . $test_file_size, $test_dir);
			}
		}

		# Cleanup	
		opendir(DIR, $test_dir);
		while (defined(my $file = readdir(DIR))) {
			next if ($file eq "." || $file eq "..");
			unlink($test_dir . "/" . $file) or die "Could not remove file: $!\n" unless $main::noclean  || $main::dryrun;
		}
		closedir(DIR);
	
		print "FSTest5 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest5 for user number $user_number completed\n\n");
		return(1);
	}
	
	# Persistent operation, create data dir, create test dir, create files
	if ($main::datadir ne "" && ! -d $main::datadir) {
		mkdir($main::datadir) || die "Could not create directory: $!";
		$test_dir = $main::datadir . "/FSTest5" . $unique_file_name;
		mkdir($test_dir) || die "Could not create directory: $!";

		# Write the files		
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			exit if ! write_test_file("FSTest5ascii" . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
		}
	
		# Read 100 files
		# Reset the time to track the read times
		$start_time = timelocal(localtime);
		for (1..10) {
			foreach my $test_file_size (@file_sizes) {
				read_test_file("FSTest5ascii" . "-" . $test_file_size, $test_dir);
			}
		}
		print "FSTest5 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest5 for user number $user_number completed\n\n");
		return(1);
	}
	
	# Persistent operation, data dir exists
	if ($main::datadir ne "" && -d $main::datadir) { $test_dir = $main::datadir . "/FSTest5" . $unique_file_name; }
	if (! -d $test_dir) {
		# Test dir does not exist, create dir and files, read files
		mkdir($test_dir) || die "Could not create directory: $!";
		# Write the files		
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			exit if ! write_test_file("FSTest5ascii" . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
		}
	
		# Read 100 files
		# Reset the time to track the read times
		$start_time = timelocal(localtime);
		for (1..10) {
			foreach my $test_file_size (@file_sizes) {
				read_test_file("FSTest5ascii" . "-" . $test_file_size, $test_dir);
			}
		}
		print "FSTest5 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest5 for user number $user_number completed\n\n");
		return(1);
	}
	else {
		# Test dir exists, read files
		# Read 100 files
		# Reset the time to track the read times
		$start_time = timelocal(localtime);
		for (1..10) {
			foreach my $test_file_size (@file_sizes) {
				read_test_file("FSTest5ascii" . "-" . $test_file_size, $test_dir);
			}
		}
		print "FSTest5 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest5 for user number $user_number completed\n\n");
		return(1);
	}
	
}

sub FSTest6 {
	# Test 6 - Multiple Small File Write/Read
	# A combination of Tests 4 and 5 using "off-boundary" file sizes
	# Persistent mode uses 1.9M of disk space
	my $test_dir = "";
	my $unique_file_name = "";
	my $start_time = timelocal(localtime);
	my $user_number = $_[0];
	my $msg_name = "FSTest6-user" . $user_number . ": ";
	if ($main::fixname ne "") {
		$unique_file_name = "-user". $user_number . "-" . $main::fixname;
		$test_dir = $main::outdir . "/FSTest6" . $unique_file_name;
	}
	else {
		my $datestamp = get_datestamp();
		$unique_file_name = "-user" . $user_number . "-" . $datestamp;
		$test_dir = $main::outdir . "/FSTest6" . $unique_file_name;
	}
	my @file_sizes = ("1.1K", "10.2K", "23.3K", "150.4K", "435.5K", "2.6K", "20.7K", "46.8K", "300.9K", "877K");
	
	print "Running FSTest6 for user number $user_number\n" if $main::verbose || $main::terse;
	write_to_logfile($msg_name . "Running FSTest6 for user number $user_number\n");
	
	# Normal mode
	if ($main::datadir eq "") {	
		mkdir($test_dir) || die "Could not create directory: $!";
	
		# Read and write 100 files each
		for (1..10) {
			foreach my $test_file_size (@file_sizes) {
				if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
				exit if ! write_test_file("FSTest6ascii" . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
				read_test_file("FSTest6ascii" . "-" . $test_file_size, $test_dir);
				unlink($test_dir . "/FSTest6ascii" . "-" . $test_file_size) or die "Could not remove file: $!\n" unless $main::noclean  || $main::dryrun;
			}
		}
	
		print "FSTest6 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest6 for user number $user_number completed\n\n");
		return(1);
	}
	
	# Persistent operation, create data dir, create test dir, create files
	if ($main::datadir ne "" && ! -d $main::datadir) {
		mkdir($main::datadir) || die "Could not create directory: $!";
		$test_dir = $main::datadir . "/FSTest6" . $unique_file_name;
		mkdir($test_dir) || die "Could not create directory: $!";
		
		# Write the files
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			exit if ! write_test_file("FSTest6ascii" . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
		}
		
		# Read 100 files
		# Reset the time to track the read times
		$start_time = timelocal(localtime);
		for (1..10) {
			foreach my $test_file_size (@file_sizes) {
				read_test_file("FSTest6ascii" . "-" . $test_file_size, $test_dir);
			}
		}
		
		print "FSTest6 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest6 for user number $user_number completed\n\n");
		return(1);
	}
	
	# Persistent operation, data dir exists
	if ($main::datadir ne "" && -d $main::datadir) { $test_dir = $main::datadir . "/FSTest6" . $unique_file_name; }
	if (! -d $test_dir) {
		# Test dir does not exist, create dir and files, read files
		mkdir($test_dir) || die "Could not create directory: $!";
		
		# Write the files
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			exit if ! write_test_file("FSTest6ascii" . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
		}
		
		# Read 100 files
		# Reset the time to track the read times
		$start_time = timelocal(localtime);
		for (1..10) {
			foreach my $test_file_size (@file_sizes) {
				read_test_file("FSTest6ascii" . "-" . $test_file_size, $test_dir);
			}
		}
		
		print "FSTest6 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest6 for user number $user_number completed\n\n");
		return(1);
	}
	else {
		# Test dir exists, read files
		# Read 100 files
		# Reset the time to track the read times
		$start_time = timelocal(localtime);
		for (1..10) {
			foreach my $test_file_size (@file_sizes) {
				read_test_file("FSTest6ascii" . "-" . $test_file_size, $test_dir);
			}
		}
		
		print "FSTest6 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest6 for user number $user_number completed\n\n");
		return(1);
	}
}

sub FSTest7 {
	# Test 7 - Multiple Large File Write
	# Persistent mode requires 3.4G of disk space
	my $test_dir = "";
	my $unique_file_name = "";
	my $start_time = timelocal(localtime);
	my $user_number = $_[0];
	my $msg_name = "FSTest7-user" . $user_number . ": ";
	if ($main::fixname ne "") {
		$unique_file_name = "-user". $user_number . "-" . $main::fixname;
		$test_dir = $main::outdir . "/FSTest7" . $unique_file_name;
	}
	else {
		my $datestamp = get_datestamp();
		$unique_file_name = "-user" . $user_number . "-" . $datestamp;
		$test_dir = $main::outdir . "/FSTest7" . $unique_file_name;
	}
	my @file_sizes = ("800M", "900M", "350M", "275M", "1.25G");
	
	print "Running FSTest7 for user number $user_number\n" if $main::verbose || $main::terse;
	write_to_logfile($msg_name . "Running FSTest7 for user number $user_number\n");

	# Normal mode
	if ($main::datadir eq "") {	
		mkdir($test_dir) || die "Could not create directory: $!";	

		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			exit if ! write_test_file("FSTest7ascii" . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
			unlink($test_dir . "/" . "FSTest7ascii" . "-" . $test_file_size);
		}
	
		print "FSTest7 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest7 for user number $user_number completed\n\n");
		return(1);
	}
	
	# Persistent operation, create data dir, create test dir, create files
	if ($main::datadir ne "" && ! -d $main::datadir) {
		mkdir($main::datadir) || die "Could not create directory: $!";
		$test_dir = $main::datadir . "/FSTest7" . $unique_file_name;
		mkdir($test_dir) || die "Could not create directory: $!";
		
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			exit if ! write_test_file("FSTest7ascii" . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
		}
	
		print "FSTest7 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest7 for user number $user_number completed\n\n");
		return(1);
	}

	# Persistent operation, data dir exists
	if ($main::datadir ne "" && -d $main::datadir) { $test_dir = $main::datadir . "/FSTest7" . $unique_file_name; }
	if (! -d $test_dir) {
		# Test dir does not exist, create dir and files
		mkdir($test_dir) || die "Could not create directory: $!";
		
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			exit if ! write_test_file("FSTest7ascii" . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
		}
	
		print "FSTest7 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest7 for user number $user_number completed\n\n");
		return(1);
	}
	else {
		# Test dir exists. As this is a write-only test, there is nothing to do here
		print "FSTest7 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest7 for user number $user_number completed\n\n");
		return(1);
	}
}

sub FSTest8 {
	# Test 8 - Multiple Large File Read
	# Persistent mode requires 2.7G of disk space
	my $test_dir = "";
	my $unique_file_name = "";
	my $start_time = timelocal(localtime);
	my $user_number = $_[0];
	my $msg_name = "FSTest8-user" . $user_number . ": ";
	if ($main::fixname ne "") {
		$unique_file_name = "-user". $user_number . "-" . $main::fixname;
		$test_dir = $main::outdir . "/FSTest8" . $unique_file_name;
	}
	else {
		my $datestamp = get_datestamp();
		$unique_file_name = "-user" . $user_number . "-" . $datestamp;
		$test_dir = $main::outdir . "/FSTest8" . $unique_file_name;
	}
	my @file_sizes = ("800M", "350M", "275M", "1.25G", "150M");
	
	print "Running FSTest8 for user number $user_number\n" if $main::verbose || $main::terse;
	write_to_logfile($msg_name . "Running FSTest8 for user number $user_number\n");

	# Normal mode
	if ($main::datadir eq "") {		
		mkdir($test_dir) || die "Could not create directory: $!";
	
		# Do 50 reads
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			exit if ! write_test_file("FSTest8ascii" . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
			for (1..10) {
				read_test_file("FSTest8ascii" . "-" . $test_file_size, $test_dir);
			}
			unlink($test_dir . "/FSTest8ascii" . "-" . $test_file_size) or die "Could not remove file: $!\n" unless $main::noclean  || $main::dryrun;
		}
	
		print "FSTest8 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest8 for user number $user_number completed\n\n");
		return(1);
	}
	
	# Persistent operation, create data dir, create test dir, create files
	if ($main::datadir ne "" && ! -d $main::datadir) {
		mkdir($main::datadir) || die "Could not create directory: $!";
		$test_dir = $main::datadir . "/FSTest8" . $unique_file_name;
		mkdir($test_dir) || die "Could not create directory: $!";
		
		# Write the files
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			exit if ! write_test_file("FSTest8ascii" . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
		}
		
		# Do 50 reads
		# Reset the time to track the read times
		$start_time = timelocal(localtime);
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			for (1..10) {
				read_test_file("FSTest8ascii" . "-" . $test_file_size, $test_dir);
			}
		}
		
		print "FSTest8 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest8 for user number $user_number completed\n\n");
		return(1);
	}
	
	# Persistent operation, data dir exists
	if ($main::datadir ne "" && -d $main::datadir) { $test_dir = $main::datadir . "/FSTest8" . $unique_file_name; }
	if (! -d $test_dir) {
		# Test dir does not exist, create dir and files, read files
		mkdir($test_dir) || die "Could not create directory: $!";

		# Write the files
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			exit if ! write_test_file("FSTest8ascii" . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
		}
				
		# Do 50 reads
		# Reset the time to track the read times
		$start_time = timelocal(localtime);
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			for (1..10) {
				read_test_file("FSTest8ascii" . "-" . $test_file_size, $test_dir);
			}
		}
		
		print "FSTest8 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest8 for user number $user_number completed\n\n");
		return(1);
	}
	else {
		# Do 50 reads
		# Reset the time to track the read times
		$start_time = timelocal(localtime);
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			for (1..10) {
				read_test_file("FSTest8ascii" . "-" . $test_file_size, $test_dir);
			}
		}
		
		print "FSTest8 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest8 for user number $user_number completed\n\n");
		return(1);
	}
}

sub FSTest9 {
	# Test 9 - Multiple Large File Write/Read
	# Combine Tests 7 and 8
	# Persistent mode requires 2.7G of disk space
	my $test_dir = "";
	my $unique_file_name = "";
	my $start_time = timelocal(localtime);
	my $user_number = $_[0];
	my $msg_name = "FSTest9-user" . $user_number . ": ";
	if ($main::fixname ne "") {
		$unique_file_name = "-user". $user_number . "-" . $main::fixname;
		$test_dir = $main::outdir . "/FSTest9" . $unique_file_name;
	}
	else {
		my $datestamp = get_datestamp();
		$unique_file_name = "-user" . $user_number . "-" . $datestamp;
		$test_dir = $main::outdir . "/FSTest9" . $unique_file_name;
	}
	my @file_sizes = ("800M", "350M", "275M", "1.25G", "150M");
	
	print "Running FSTest9 for user number $user_number\n" if $main::verbose || $main::terse;
	write_to_logfile($msg_name . "Running FSTest9 for user number $user_number\n");

	# Normal mode
	if ($main::datadir eq "") {		
		mkdir($test_dir) || die "Could not create directory: $!";

		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			exit if ! write_test_file("FSTest9ascii" . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
			read_test_file("FSTest9ascii" . "-" . $test_file_size, $test_dir);
			unlink($test_dir . "/FSTest9ascii" . "-" . $test_file_size) or die "Could not remove file: $!\n" unless $main::noclean  || $main::dryrun;
		}

		print "FSTest9 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest9 for user number $user_number completed\n\n");
		return(1);
	}
	
	# Persistent operation, create data dir, create test dir, create files
	if ($main::datadir ne "" && ! -d $main::datadir) {
		mkdir($main::datadir) || die "Could not create directory: $!";
		$test_dir = $main::datadir . "/FSTest9" . $unique_file_name;
		mkdir($test_dir) || die "Could not create directory: $!";

		# Write the files		
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			exit if ! write_test_file("FSTest9ascii" . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
		}

		# Read the files
		# Reset the time to track the read times
		$start_time = timelocal(localtime);	
		foreach my $test_file_size (@file_sizes) {		
			read_test_file("FSTest9ascii" . "-" . $test_file_size, $test_dir);
		}

		print "FSTest9 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest9 for user number $user_number completed\n\n");
		return(1);
	}
	
	# Persistent operation, data dir exists
	if ($main::datadir ne "" && -d $main::datadir) { $test_dir = $main::datadir . "/FSTest9" . $unique_file_name; }
	if (! -d $test_dir) {
		# Test dir does not exist, create dir and files, read files
		mkdir($test_dir) || die "Could not create directory: $!";
		
		# Write the files		
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			exit if ! write_test_file("FSTest9ascii" . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
		}

		# Read the files
		# Reset the time to track the read times
		$start_time = timelocal(localtime);	
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };	
			read_test_file("FSTest9ascii" . "-" . $test_file_size, $test_dir);
		}

		print "FSTest9 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest9 for user number $user_number completed\n\n");
		return(1);
	}
	else {
		# Read the files
		# Reset the time to track the read times
		$start_time = timelocal(localtime);	
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };	
			read_test_file("FSTest9ascii" . "-" . $test_file_size, $test_dir);
		}

		print "FSTest9 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest9 for user number $user_number completed\n\n");
		return(1);
	}
}

sub FSTest10 {
	# Test 10 - Mixed File Size Write/Read
	# Simulate a verification cycle: a couple of large files and a few small files
	# Persistent mode requires 1.2G of disk space
	my $test_dir = "";
	my $unique_file_name = "";
	my $start_time = timelocal(localtime);
	my $user_number = $_[0];
	my $msg_name = "FSTest10-user" . $user_number . ": ";
	if ($main::fixname ne "") {
		$unique_file_name = "-user". $user_number . "-" . $main::fixname;
		$test_dir = $main::outdir . "/FSTest10" . $unique_file_name;
	}
	else {
		my $datestamp = get_datestamp();
		$unique_file_name = "-user" . $user_number . "-" . $datestamp;
		$test_dir = $main::outdir . "/FSTest10" . $unique_file_name;
	}
	my @file_sizes = ("900M", "1K", "10K", "23K", "350M", "150K", "435K");
	
	print "Running FSTest10 for user number $user_number\n" if $main::verbose || $main::terse;
	write_to_logfile($msg_name . "Running FSTest10 for user number $user_number\n");
	
	# Normal mode
	if ($main::datadir eq "") {	
		mkdir($test_dir) || die "Could not create directory: $!";
	
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			exit if ! write_test_file("FSTest10ascii" . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
			read_test_file("FSTest10ascii" . "-" . $test_file_size, $test_dir);
			unlink($test_dir . "/FSTest10ascii" . "-" . $test_file_size) or die "Could not remove file: $!\n" unless $main::noclean  || $main::dryrun;
		}
	
		print "FSTest10 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest10 for user number $user_number completed\n\n");
		return(1);
	}
	
	# Persistent operation, create data dir, create test dir, create files
	if ($main::datadir ne "" && ! -d $main::datadir) {
		mkdir($main::datadir) || die "Could not create directory: $!";
		$test_dir = $main::datadir . "/FSTest10" . $unique_file_name;
		mkdir($test_dir) || die "Could not create directory: $!";
		
		# Write the files
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			exit if ! write_test_file("FSTest10ascii" . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
		}
		
		# Read the files
		# Reset the time to track the read times
		$start_time = timelocal(localtime);
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			read_test_file("FSTest10ascii" . "-" . $test_file_size, $test_dir);
		}
	
		print "FSTest10 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest10 for user number $user_number completed\n\n");
		return(1);
	}
	
	# Persistent operation, data dir exists
	if ($main::datadir ne "" && -d $main::datadir) { $test_dir = $main::datadir . "/FSTest10" . $unique_file_name; }
	if (! -d $test_dir) {
		# Test dir does not exist, create dir and files, read files
		mkdir($test_dir) || die "Could not create directory: $!";
		
		# Write the files
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			exit if ! write_test_file("FSTest10ascii" . "-" . $test_file_size, $test_dir, "ascii", $test_file_size);
		}
		
		# Read the files
		# Reset the time to track the read times
		$start_time = timelocal(localtime);
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			read_test_file("FSTest10ascii" . "-" . $test_file_size, $test_dir);
		}
	
		print "FSTest10 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest10 for user number $user_number completed\n\n");
		return(1);
	}
	else {
		# Read the files
		# Reset the time to track the read times
		$start_time = timelocal(localtime);
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			read_test_file("FSTest10ascii" . "-" . $test_file_size, $test_dir);
		}
	
		print "FSTest10 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest10 for user number $user_number completed\n\n");
		return(1);
	}
}

sub FSTest11 {
	# Test 11 - Multiple Large File Writes
	# Simulate full chip GDS2 file creation - a dozen or so large files, written sequentially.
	# Persistent mode requires 3.5G of disk space
	my $test_dir = "";
	my $unique_file_name = "";
	my $start_time = timelocal(localtime);
	my $user_number = $_[0];
	my $msg_name = "FSTest11-user" . $user_number . ": ";
	if ($main::fixname ne "") {
		$unique_file_name = "-user". $user_number . "-" . $main::fixname;
		$test_dir = $main::outdir . "/FSTest11" . $unique_file_name;
	}
	else {
		my $datestamp = get_datestamp();
		$unique_file_name = "-user" . $user_number . "-" . $datestamp;
		$test_dir = $main::outdir . "/FSTest11" . $unique_file_name;
	}
	my @file_sizes = ("800M", "900M", "350M", "275M", "1.25G", "150M", "800M", "900M", "350M", "275M", "1.25G", "150M");
	
	print "Running FSTest11 for user number $user_number\n" if $main::verbose || $main::terse;
	write_to_logfile($msg_name . "Running FSTest11 for user number $user_number\n");
	
	# Normal mode
	if ($main::datadir eq "") {
		mkdir($test_dir) || die "Could not create directory: $!";
	
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			exit if ! write_test_file("FSTest11" . "-" . $test_file_size, $test_dir, "binary", $test_file_size);
			unlink($test_dir . "/FSTest11" . "-". $test_file_size) or die "Could not remove file: $!\n" unless $main::noclean || $main::dryrun;	
		}
	
		print "FSTest11 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest11 for user number $user_number completed\n\n");
		return(1);
	}
	# Persistent operation, create data dir, create test dir, create files, read files
	if ($main::datadir ne "" && ! -d $main::datadir) {
		mkdir($main::datadir) || die "Could not create directory: $!";
		$test_dir = $main::datadir . "/FSTest11" . $unique_file_name;
		mkdir($test_dir) || die "Could not create directory: $!";
		
		# Write the files
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			exit if ! write_test_file("FSTest11" . "-" . $test_file_size, $test_dir, "binary", $test_file_size);
		}
			
		print "FSTest11 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest11 for user number $user_number completed\n\n");
		return(1);
	}

	# Persistent operation, data dir exists
	if ($main::datadir ne "" && -d $main::datadir) { $test_dir = $main::datadir . "/FSTest11" . $unique_file_name; }
	if (! -d $test_dir) {
		# Test dir does not exist, create dir and files
		mkdir($test_dir) || die "Could not create directory: $!";
		# Write the files
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			exit if ! write_test_file("FSTest11" . "-" . $test_file_size, $test_dir, "binary", $test_file_size);
		}
			
		print "FSTest11 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest11 for user number $user_number completed\n\n");
		return(1);
	}
	else {
		# Test dir exists. As this is a write-only test, there is nothing to do here
		print "FSTest11 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
		my $finish_time = timelocal(localtime);
		my $total_run_time = elapsed_time($start_time, $finish_time);
		write_to_logfile($msg_name . $total_run_time);
		write_to_logfile($msg_name . "FSTest11 for user number $user_number completed\n\n");
		return(1);		
	}
}

sub FSTest12 {
	# Test 12 - Persistent file test
	if ($main::datadir eq "") { return }
	my $test_dir = "";
	my $unique_file_name = "";
	my $start_time = timelocal(localtime);
	my $user_number = $_[0];
	my $msg_name = "FSTest12-user" . $user_number . ": ";
	my @file_sizes = ("900M", "1K", "10K", "23K", "350M", "150K", "435K", "100K", "1M", "10M", "100M", "2G",  "2K", "20K", "46K", "300K", "870K");
	
	print "Running FSTest12 for user number $user_number\n" if $main::verbose || $main::terse;
	write_to_logfile($msg_name . "Running FSTest12 for user number $user_number\n");
	
	# Create the persistent directory if specified and it doesn't already exist
	# Then create and read the files
	if (! -d $main::datadir) {
		mkdir($main::datadir) || die "Could not create directory: $!";
		foreach my $test_file_size (@file_sizes) {
			if ($main::maxsize ne "" && (convert_size($main::maxsize) < convert_size($test_file_size))) { $test_file_size = $main::maxsize; };
			next if ! write_test_file("FSTest12" . "-" . $test_file_size, $main::datadir, "ascii", $test_file_size);	
		}
		# For this test, we only want to record the read times, so start the clock here...
		$start_time = timelocal(localtime);
		foreach my $test_file_size (@file_sizes) {
			read_test_file("FSTest12" . "-" . $test_file_size, $main::datadir);
		}
	}
	# The directory (and files) already exist. Read the files
	else {
		# For this test, we only want to record the read times, so start the clock here...
		$start_time = timelocal(localtime);
		foreach my $test_file_size (@file_sizes) {
			read_test_file("FSTest12" . "-" . $test_file_size, $main::datadir);
		}
	}
	
	print "FSTest12 for user number $user_number completed\n\n" if $main::verbose || $main::terse;
	my $finish_time = timelocal(localtime);
	my $total_run_time = elapsed_time($start_time, $finish_time);
	write_to_logfile($msg_name . $total_run_time);
	write_to_logfile($msg_name . "FSTest12 for user number $user_number completed\n\n");
}
###