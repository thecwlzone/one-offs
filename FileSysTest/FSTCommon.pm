package FSTCommon;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

use Exporter;
$VERSION = 0.21;
@ISA = qw(Exporter);

@EXPORT	= qw(&directory_purge &get_datestamp &write_to_logfile &check_disk_space
			 &check_sys_resources &check_sys_status &commify &elapsed_time &convert_size);
#@EXPORT_OK	= qw(...);
	
###
# This module will contain functions that are used in a lot of places
###

#
# Change Log:
#
# 0.21 - Added support in check_disk_space for GSA when it uses NFS
#
####
sub write_to_logfile {
	# Write a message to the log file.
	# The caller is responsible for formatting the text, we just write it.
	use Fcntl qw(:DEFAULT :flock);
	my $text = $_[0];
	flock($main::fh, 2);		# Ask for write lock
	print($main::fh $text);
	flock($main::fh, 8);		# Release write lock
}
####

####
sub get_datestamp {
	# Get a date stamp to use as part of the file/directory naming structure
	my $datestamp = localtime();
	$datestamp =~ s/ /-/g;
	return $datestamp;
}
####

####
sub elapsed_time {
	# arg1 is the start time, arg2 is the stop time, both are epoch seconds
	# Reformat so that humans can read the results
	my $then = $_[0];
	my $now = $_[1];
	my $diff = $now - $then;
	my $total_seconds = $now - $then;
	if ($diff < 60) {
		return "Elapsed time is $diff seconds\n";
	}
	else {
		my $seconds = $diff % 60;
		$diff = ($diff - $seconds) / 60;
		my $minutes = $diff % 60;
		$diff = ($diff - $minutes) / 60;
		my $hours = $diff % 24;
		if ($hours == 0) {
			return "Elapsed time is $minutes min $seconds sec - ($total_seconds seconds)\n";
		}
		else {
			return "Elapsed time is $hours hrs $minutes min $seconds sec - ($total_seconds seconds)\n";
		}
	}
}
####

# Convert size to integer
sub convert_size {
	my $s_size = $_[0];
	my $num_val = $s_size;
	chop $num_val;
	my $suffix = substr($s_size, length($s_size)-1, 1);
	my $size = 0;

	SWITCH: {
		if ($suffix =~ /K/) { $size = $num_val * 1000; last SWITCH; };
		if ($suffix =~ /M/) { $size = $num_val * 1000000; last SWITCH; };
		if ($suffix =~ /G/) { $size = $num_val * 1000000000; last SWITCH; };
		if ($suffix =~ /T/) { $size = $num_val * 1000000000000; last SWITCH; };
	}
	return $size;
}
###

####
sub directory_purge {
	# Recursively delete a directory tree, starting at $main::outdir
	use File::Path;
	my $dir = $main::outdir;
	print "  Removing $dir\n" if $main::verbose;
	rmtree($dir);
}
####

####
sub check_disk_space {
	# Determine the file system and run the appropriate command to check
	# disk space. If available space is < 10% of total, put a warning
	# message in LOGFILE. Return a string containing the available space
	# value.
	my $target_dir = $_[0];
	my $utilization = "";
	my $fs_type = "";
	my $kernel_name = `/bin/uname -s`;
	chomp $kernel_name;
	my $available_space = "";
	
	# Use the df command to figure out the file system type
	if ($kernel_name eq "Linux") {
		# Filesystem    Type   1K-blocks      Used Available Use% Mounted on
		# /dev/mapper/VolGroup00-LogVol02
		#               ext3     4951688   2506352   2189748  54% /home
		my @result = split(" ", `/bin/df -T $target_dir`);
		$fs_type = $result[9];
	}
	elsif (uc($kernel_name) eq "AIX") {
		# Filesystem    Mounted on         512-blocks      Free %Used    Iused %Iused
		# /dev/hd3      /tmp                134217728 126518896    6%      564     1% 
		my @result = split(" ", `/bin/df -M $target_dir`);
		my $mount_point = $result[9];
		# /tmp    : jfs
		@result = split(" ", `/usr/sysv/bin/df -n $mount_point`);
		$fs_type = $result[2];
	}
	else {
		die "Unknown operating system: $kernel_name. (WTF?) Cannot continue.\n";
	}

	# Get the per cent available and the actual available disk space	
	if (uc($fs_type) eq "AFS") {
		# Volume Name                   Quota      Used %Used   Partition
		# rel.c.p.hss65.1.sr.lhm      1000000    155314   16%         76%
		my @result = split(" ", `fs lq $target_dir`);
		$utilization = $result[9];
		my $quota_space = $result[7];
		my $used_space = $result[8];
		$available_space = int($quota_space) - int($used_space);
		$available_space = $available_space . "K";
	}
	elsif ($fs_type =~ /ext/) {
		# Filesystem            Size  Used Avail Use% Mounted on
		# /dev/mapper/VolGroup00-LogVol02
		#                      4.8G  2.4G  2.1G  54% /home
		my @result = split(" ", `df -h $target_dir`);
		$utilization = $result[11];
		$available_space = $result[10];
	}
	elsif ($fs_type eq "jfs") {
		my @result = split(" ", `/bin/df -Pg $target_dir`);
		$utilization = $result[12];
		$available_space = $result[11];		
		$available_space =~ s/\.\d+//;
		$available_space = $available_space . "G";
	}
	elsif ($fs_type eq "reiserfs") {
		# Filesystem            Size  Used Avail Use% Mounted on
		# /dev/sda2              33G  2.7G   31G   9% /
		my @result = split(" ", `df -h $target_dir`);
		$utilization = $result[11];
		$available_space = $result[8];
	}
	elsif ($fs_type eq "gpfs") {
		# Filesystem            Size  Used Avail Use% Mounted on
		# /dev/gpfs0            1.1T  591M  1.1T   1% /gpfs0
		my @result = split(" ", `df -h $target_dir`);
		$utilization = $result[11];
		$available_space = $result[10];		
	}
	elsif ($fs_type =~ /nfs/) {
		# We'll assume we're not on a Solaris box, so it's gotta be a GSA mount point
		# This is so ugly for a command line request...
		#
		# List Quota (GB) for '/gsa/rchgsa/home/l/e/lehman'
		# --------------------
		# Quota: 25
		# Used:  0.001
		#
		# Quota 'list' command finished successfully.
		#
		#
		my @result = split("\n", `export GSASCRIPT=true ; /usr/bin/gsa quota list --path $target_dir`);
		my @gsa_quota = split(" ", $result[3]);
		my $quota = $gsa_quota[1];
		my @used = split(" ", $result[4]);
		$utilization = $used[1];
		$available_space = $quota - (sprintf("%.1f", $quota * $utilization/100));
		$available_space = $available_space . "G";
	}
	else {
		die "Could not determine file system type: $fs_type. (WTF?) Cannot continue.\n";
	}
	
	$utilization =~ s/[^0-9.]//g;
	if (int($utilization) >= 98) {
		write_to_logfile("Warning: Disk capacity for $target_dir is at $utilization per cent\n");
	}
	
	return $available_space;
}
####

####
sub check_sys_resources {
	# Check user limits for open files and running processes. Send a
	# message to LOGFILE whenever any resource exceeds 90% of default
	# limits, regardless of actual user settings.
	my $kernel_name = `/bin/uname -s`;
}
####

####
sub check_sys_status {
	# Check for CPU/memory loading
	my $kernel_name = `/bin/uname -s`;
}
####

####
sub commify {
	# Add commas to make big numbers readable
	# Thanks to O'Reilly's "Perl Cookbook" by Tom Christiansen & Nathan Torkington
	my $text = reverse $_[0];
	$text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
	return scalar reverse $text;
}
####
