package WriteTestFile;
use FSTCommon;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

use Exporter;
$VERSION = 0.11;
@ISA = qw(Exporter);

@EXPORT		= qw(&write_test_file);
#@EXPORT_OK	= qw(...);
	
###
# Params:
#  name - file name
#  dir 	- directory in which to create file. This code is not responsible for
#         creating the directory
#  type - binary or ascii file
#  size - file size. Syntax is n[K][M][G], where K = Kilo, M = Mega, G = Giga
#         Note: a file size of 0 is valid - an empty file will be created.
#
# Change Log:
#
# 0.11 - Changed warning message when there is not enough disk space
#

sub write_test_file {
	# Returns (1) if all is well, returns (0) if a problem is encountered
	print "Start of write_test_file\n" if $main::verbose;
	
	my $target_file = $_[0];
	print "File name is $target_file\n" if $main::verbose;
	
	my $target_dir = $_[1];
	chomp $target_dir;
	print "Target directory is $target_dir\n" if $main::verbose;
	
	my $file_type = $_[2];
	print "File type is $file_type\n" if $main::verbose;
	
	my $size = convert_size($_[3]);
	print "File size will be " . commify($size) . " bytes\n" if $main::verbose;
	
	my $path_and_file = $target_dir . "/" . $target_file;
	
	if ($main::dryrun) {
		print "DRY RUN: Would have written file $path_and_file " . commify($size) . " bytes in length\n";
		print "End of write_test_file\n";
		return(1);
	}

	# Is it safe?
	my $t_space = check_disk_space($target_dir);
	my $disk_space = convert_size($t_space);
	if (int($disk_space) < int($size) ) {
		write_to_logfile("FATAL: Not enough disk space in $target_dir\n for $target_file...\n");
		print "FATAL: Not enough disk space in $target_dir\n for $target_file...\n" if $main::verbose;
		return(0);
	}
	check_sys_resources();
			
	open(TARGET, "> $path_and_file") or die "Could not open file for write: $!";
	binmode TARGET if $file_type eq "binary";
	
	my $i = 0;
	while ($i <= $size) {
		# Write a block of bytes that represents the letter "A"
		if ($file_type eq "binary") {
			printf TARGET "%8192u", 65 or die "Error writing to file: $!\n";
			$i = $i + 8192;
		}
		# Write a block of "A" characters, followed by a newline.
		if ($file_type eq "ascii") {
			printf TARGET "%8192s", "A" or die "Error writing to file: $!\n";
			print TARGET "\n" or die "Error writing to file: $!\n";
			$i = $i + 8192;
		}
	}
	
	close(TARGET) or die "Error closing file: $!\n";
	
	print "End of write_test_file\n" if $main::verbose;
	return(1);
}

1;