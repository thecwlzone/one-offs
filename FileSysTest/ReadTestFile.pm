package ReadTestFile;
use FSTCommon;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

use Exporter;
$VERSION = 0.10;
@ISA = qw(Exporter);

@EXPORT		= qw(&read_test_file);
#@EXPORT_OK	= qw(...);
	
###
# Params:
#  name - file name
#  dir 	- directory in which to read file.
#

sub read_test_file {
	print "Start of read_test_file\n" if $main::verbose;
	
	my $file_name = $_[0];
	print "File name is $file_name\n" if $main::verbose;

	my $target_dir = $_[1];
	chomp $target_dir;
	print "Target directory is $target_dir\n" if $main::verbose;
	
	my $target_file = $target_dir . "/" . $file_name;
	
	if ($main::dryrun) {
		print "DRY RUN: Would have read file $target_file\n";
		print "End of read_test_file\n";
		return;
	}

	# Is it safe?
	check_sys_resources();	
	open(TARGET, "< $target_file") or die "Could not open file for reading: $!\n";
	while (read(TARGET, my $buf, 8192)) { next; };
	close(TARGET);
	
	print "End of read_test_file\n" if $main::verbose;
}

###

1;