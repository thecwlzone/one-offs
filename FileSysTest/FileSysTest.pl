#!/usr/bin/perl -w
use WriteTestFile;
use FSTCommon;
use TheTests;
use Getopt::Long;
use Time::Local;
use lib ".";

#
# Change Log
#
# 0.20 - Added --maxsize option to limit file sizes to a user-defined maximum.
#        Syntax is --maxsize nG | nM | nK
#        Example:  --maxsize 1G
#        Also affects the code in TheTests.pm
#
# 0.21 - Removed 0755 directive from the mkdir commands to make GSA happy
#
# 0.22 - Added --fixname option. This will create a file/directory hierarchy
#        with a repeatable naming convention.
#
# 0.23 - Added --datadir option. The directory is persistent, so it can be used
#        to test file system caching. To be used in conjnction with the new
#        Test12 code.
#
# 0.24 - Added general support for the --datadir option
#        When using --datadir, you really need to use --fixname or the benefit
#        of persistent data is lost, so the process_options subroutine checks
#        for that dependency.
#
# This is the main program.
#
# Syntax: ./FileSysTest.pl [options]
#
# Options:
#
# -h, -help, --help			Print usage and exit.
# --verbose					Show processing details. Default behavior is silent.
# --terse					Not silent, and not verbose.
# --seq						Run tests sequentially. Default behavior.
# --sim						Run tests simultaneously. Overrides --seq option.
# --all						Run all tests. Default behavior.
# --maxsize nG | nM | nK	Use files no larger than n bytes
# --dryrun					Run the code, but don't really do anything.
#							Best used with the --verbose option.
# --noclean					Keep all created files and directories.
#							Default behavior is to delete files "on the fly".
# --tests 1,2,n | 1-n		Run designated tests. Overrides --all option.
# --users n					Simulate n number users. Default is 1 user.
#							n > 1 is only useful with the --sim option enabled.
# --outdir					Output directory. Default location is
#							/tmp/filesystest-`date`
# --logfile					Output file. Default name is filesystest-`date`.log
# --fixname name			Use "Name" when creating files and directories
# --datadir DirName			Use "DirName" as a persistent directory
# -v, --version				Version number
#
###################
# main
#
our $total_tests = 12;
our $fh;	# Log file handle
my $datestamp = get_datestamp();
my $MAIN_MSG_LABEL = "MAIN: ";
my $VERSION = "0.24";

# Initialize options
our $help = 0;
our $verbose = 0;
our $terse = 0;
our $seq = 1;
our $sim = 0;
our $all = 1;
our $maxsize = "";
our $dryrun = 0;
our $noclean = 0;
our $tests = "";
our $users = 1;
our $outdir = "/tmp";
our $logfile = "filesystest-" . $datestamp . ".log";
our $fixname = "";
our $datadir = "";
my $version = 0;

process_options();

# Initialize log file
open($fh, "> $main::logfile") or die "Could not open the log file $main::logfile: $!";

my $start_time = timelocal(localtime);
print("\nStart FileSysTest Suite\n\n") if $verbose || $terse;
write_to_logfile($MAIN_MSG_LABEL . "Start FileSysTest Suite\n\n");

# Write options to logfile
write_to_logfile($MAIN_MSG_LABEL . "Write files to " . $outdir . "\n");
write_to_logfile($MAIN_MSG_LABEL . "Log file name is " . $logfile . "\n");
if ($all) {
	write_to_logfile($MAIN_MSG_LABEL . "Running all tests\n");
}
else {
	write_to_logfile($MAIN_MSG_LABEL . "Running tests " . $tests . "\n");
}
if ($maxsize ne "") { write_to_logfile($MAIN_MSG_LABEL . "Maximum file size set to " . $maxsize . "\n"); }
if ($sim) {
	write_to_logfile($MAIN_MSG_LABEL . "Running " . $users . " users simultaneously\n\n");
}
else {
	write_to_logfile($MAIN_MSG_LABEL . "Running " . $users . " users sequentially\n\n");
}

print("DRY RUN MODE - no files will actually be created.\n\n") if $dryrun && $verbose;
write_to_logfile($MAIN_MSG_LABEL . "DRY RUN MODE - no files will actually be created.\n\n") if $dryrun;

run_dispatcher();

print "Tests complete. Performing teardown procedures...\n" if $verbose || $terse;

# Tear down
print "\nFinished FileSysTest Suite\n" if $verbose || $terse;
write_to_logfile("\n" . $MAIN_MSG_LABEL . "Finished FileSysTest Suite\n");
my $finish_time = timelocal(localtime);
my $total_run_time = elapsed_time($start_time, $finish_time);
write_to_logfile($MAIN_MSG_LABEL . $total_run_time);
close($fh);
directory_purge() unless $noclean;

exit;

# end main
#######################

####
# This is the heart of the program control
#
sub run_dispatcher {
	@tests = generate_test_list();

	# For n number of users	
	for ($i = 1; $i <= $main::users; $i++) {
		# Run each specified test
		my $user_number = $i;
		foreach $item (@tests) {
			my $run_test = "FSTest". $item;
			
			# Sequential testing
			&$run_test($user_number) if ! $main::sim;
			
			# Simultaneous testing
    		if ($main::sim) {
    			my $pid = fork();
      			if ($pid) {
					# parent
					push(@childs, $pid);
				}
				elsif ($pid == 0) {
					# child
					&$run_test($user_number);
					exit(0);
				}
				else {
					die "couldn't fork: $!\n";
				}
			} # if $sim
		} # foreach item
	} # for $i
	
	# Avoid zombie processes
	foreach (@childs) {
  		waitpid($_, 0);
	}
}
####

####
# Process options
sub process_options {
	use File::Basename;
	my $opt_result = GetOptions ('h'		=> \$main::help,
								'help'		=> \$main::help,
								'verbose'	=> \$main::verbose,
								'terse'		=> \$main::terse,
								'seq' 		=> \$main::seq,
								'sim'		=> \$main::sim,
								'all'		=> \$main::all,
								'maxsize=s'	=> \$main::maxsize,
								'dryrun'	=> \$main::dryrun,
								'noclean'	=> \$main::noclean,
								'tests=s'	=> \$main::tests,
								'users=i'	=> \$main::users,
								'outdir=s'	=> \$main::outdir,
								'logfile=s'	=> \$main::logfile,
								'fixname=s'	=> \$main::fixname,
								'datadir=s' => \$main::datadir,
								'v'			=> \$version,
								'version'	=> \$version
								);

	if (! $opt_result || $main::help) { goto USAGE; };
	if ($version) { print($VERSION . "\n"); exit; };
	if ($maxsize && $maxsize !~ /(\d+\.)*\d+[Gg]|[Mm]|[Kk]/) {
		warn "Incorrect --maxsize value: $maxsize Cannot continue\n";
		goto USAGE;
	}
	if ($datadir ne "" && $fixname eq "") {
		warn "When using the --datadir option, use the --fixname option to create reusable directory names";
		goto USAGE;
	}
	
	# Adjust options as required based upon user input
#	if ($main::fixname ne "") { $main::logfile = "filesystest-" . $fixname . ".log"; }
	if ($main::sim) { $seq = 0; };
	if ($main::tests ne "") { $main::all = 0; };
	# Create outdir if necessary
	# Note: We rely on the user to have umask values set to create files and
	# directories under the appropriate file system(s)
	if (! -d $main::outdir) {
		mkdir($main::outdir) || die "Could not create directory: $!";
	}	
	# Now add a unique test directory name to outdir
	# Allows a cleanup of the test directory without losing the log file.
	if ($main::fixname ne "") {
		$main::outdir = $main::outdir . "/filesystest-" . $fixname;
	}
	else {
		$main::outdir = $main::outdir . "/filesystest-" . $datestamp;
	}
	mkdir($main::outdir) || die "Could not create directory: $!";
	# Tack on the logfile name to outdir
	$main::logfile = dirname($main::outdir) . "/" . $main::logfile;

	if ($verbose) {
		print "Command line options settings:\n";
		print "  --verbose	= $main::verbose\n";
		print "  --terse	= $main::terse\n";
		print "  --seq		= $main::seq\n";
		print "  --sim		= $main::sim\n";
		print "  --all		= $main::all\n";
		print "  --maxsize	= $main::maxsize\n";
		print "  --dryrun	= $main::dryrun\n";
		print "  --noclean	= $main::noclean\n";
		print "  --tests	= $main::tests\n";
		print "  --users	= $main::users\n";
		print "  --outdir	= $main::outdir\n";
		print "  --logfile	= $main::logfile\n";
		print "  --fixname	= $main::fixname\n";
		print "  --datadir	= $main::datadir\n";
		print "  --version	= $VERSION\n";
	}							
}
####

####
sub generate_test_list {
	# Create an array of tests to be run
	my @tests = ();
	if ($main::all) {
		for ($i = 1; $i <= $main::total_tests; $i++) {
			$tests[$i] = $i;
		}
		shift @tests;	# Don't use tests[0]
	}
	# --tests 3 | --tests 11
	elsif ($main::tests =~ /^\d+(\d+)?$/) {
		$tests[0] = $main::tests;
	}
	# --tests 1,2,3
	elsif ($main::tests =~ /^\d+,\d+/) {
		my @test_list = split /,/, $main::tests;
		for ($i = 0; $i <= $#test_list; $i++) {
			$tests[$i] = $test_list[$i];
		}			 
	}
	# --tests 1-11
	elsif ($main::tests =~ /^\d+-\d+/) {
		my @test_list = split /-/, $main::tests;
		my $j = 0;
		for ($i = $test_list[0]; $i <= $test_list[$#test_list]; $i++) {
			$tests[$j] = $i;
			$j++;
		}
	}
	else {
		warn "Unknown format associated with --tests option. Cannot continue...\n";
		goto USAGE;
	}
	
	# Check for valid test numbers
	foreach $item (@tests) {
		if ($item < 1 || $item > $main::total_tests) {
			warn "Error in --tests option. The maximum number of tests is $main::total_tests\n";
			warn " You entered $item. Cannot continue.\n";
			exit;
		}
	}
	
	return @tests;
}
####
# Print usage syntax
use Text::Wrap qw($columns &wrap);
$columns = 30;
USAGE: {
		print "Legal options for FileSysTest.pl are:\n";
		print "FileSysTest.pl [-h | -help | --help] [--verbose] [--seq | --sim]\n";
		print "               [--all | --tests 1,2,n | --tests 1-n] [--maxsize nG | nM | nK] [--dryrun] [--noclean]\n";
		print "               [--users n] [--outdir DirName] [--logfile FileName] [--datadir DirName --fixname name] [-v | --version]\n\n";
		print "--verbose               Show processing details. Default behavior is silent.\n";
		print "--terse                 Show progress, but not verbosely\n";
		print "--seq                   Run tests sequentially. Default behavior.\n";
		print "--sim                   Run tests simultaneously. Overrides --seq option.\n";
		print "--all                   Run all tests. Default behavior.\n";
		print "--maxsize nG | nM | nK  Use files no larger than n bytes\n";
		print "--dryrun                Run the code, but don't really do anything.\n";
		print "                        Best used with the --verbose option.\n";
		print "--noclean               Keep all created files and directories.\n";
		print "                        Default behavior is to delete files \"on the fly\".\n";
		print "--tests 1,2,n | 1-n     Run designated tests. Overrides --all option.\n";
		print "--users n               Simulate n number users. Default is 1 user.\n";
		print "                        n > 1 is only useful with the --sim option enabled\n";
		print "--outdir                Output directory. Default location is\n";
		print "                        /tmp/filesystest-`date`\n";
		print "--logfile               Output file. Default name is filesystest-`date`.log\n";
		print "--fixname Name          Use \"Name\" to create repeatable file/directory names\n";
		print "--datadir DirName       Use \"DirName\" as a persistent directory\n";
		print "-v, --version           Version number\n\n";
		exit;
}	
####
