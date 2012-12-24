#! /usr/bin/perl -w

# Make a backup of a database and upload it to S3.

use strict;
use FileHandle;
use Try::Tiny;

scalar(@ARGV) == 1 || die "Usage: $0 <database name>\n";
my $dbname = shift @ARGV;

my $home = $ENV{'HOME'};
my $dbpasswd_fh = new FileHandle("<$home/.ccdbpasswd")
	|| die "Couldn't open $home/.ccdbpasswd: $!\n";
my $dbpasswd = <$dbpasswd_fh>;
die "Couldn't read db password from $home/.ccdbpasswd\n" if (!defined $dbpasswd);
chomp $dbpasswd;
$dbpasswd_fh->close();

my $date = `date +'%d-%m-%Y'`;
chomp $date;

my $backup_filename = "$dbname-$date.sql.bz2";

# Dump the database
my $backup_dir = "/home/ubuntu/backup";
system("mkdir -p $backup_dir")/256 == 0 || die "Couldn't create backup directory\n";
my $backup_file_path = "$backup_dir/$backup_filename";

try {
	my $cmd = "mysqldump -u cloudcoder -p'$dbpasswd' '$dbname' | (bzip2 --best > $backup_file_path)";
	#print "cmd: $cmd\n";
	system($cmd)/256 == 0 || die "mysqldump failed\n";
	
	# Upload to S3
	my $s3cmd = "/home/ubuntu/bin/s3backup.pl '$backup_file_path' org.cloudcoder.backup";
	print "s3cmd: $s3cmd\n";
	exit 0;
	system($s3cmd)/256 == 0
		|| die "s3backup.pl failed\n";
} catch {
	die "Error: $_\n";
} finally {
	#system("rm -f $backup_file_path");
};

# vim:set ts=2:
